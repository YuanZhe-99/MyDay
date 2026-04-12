import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../features/finance/models/finance.dart';
import '../../features/finance/services/balance_util.dart';
import '../../features/finance/services/exchange_rate_storage.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/todo/models/task.dart';
import '../../features/todo/services/todo_storage.dart';
import '../../features/weight/models/weight_record.dart';
import '../../features/weight/services/weight_storage.dart';

class LocalApiServer {
  static HttpServer? _server;
  static int _port = 7790;
  static String _listenAddress = 'localhost';
  static bool _enabled = false;
  static String? _username;
  static String? _password;
  static String? _lastError;

  static int get port => _port;
  static String get listenAddress => _listenAddress;
  static bool get enabled => _enabled;
  static bool get isRunning => _server != null;
  static String? get lastError => _lastError;

  static Future<void> loadConfig() async {
    try {
      final json = await TodoStorage.readConfig();
      _port = json['apiPort'] as int? ?? 7790;
      _listenAddress = json['apiListenAddress'] as String? ?? 'localhost';
      _enabled = json['apiEnabled'] as bool? ?? false;
      _username = json['apiUsername'] as String?;
      _password = json['apiPassword'] as String?;
    } catch (_) {}
  }

  static Future<void> start() async {
    await loadConfig();
    await stop();
    _lastError = null;
    if (!_enabled) return;

    final isNonLoopback = _listenAddress == '0.0.0.0' ||
        (_listenAddress != 'localhost' && _listenAddress != '127.0.0.1');
    final hasCredentials = _username != null &&
        _username!.isNotEmpty &&
        _password != null &&
        _password!.isNotEmpty;
    if (isNonLoopback && !hasCredentials) {
      _lastError = 'credentials_required';
      return;
    }

    final router = Router();
    router.get('/ping', _handlePing);
    // Todo
    router.get('/todo/list', _handleTodoList);
    router.post('/todo/add', _handleTodoAdd);
    router.post('/todo/complete', _handleTodoComplete);
    router.get('/todo/stats', _handleTodoStats);
    // Finance
    router.get('/finance/summary', _handleFinanceSummary);
    router.get('/finance/transactions', _handleFinanceTransactions);
    router.post('/finance/add_transaction', _handleFinanceAddTransaction);
    router.get('/finance/subscriptions', _handleFinanceSubscriptions);
    // Weight
    router.get('/weight/list', _handleWeightList);
    router.post('/weight/add', _handleWeightAdd);
    router.get('/weight/stats', _handleWeightStats);

    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addMiddleware(_errorMiddleware())
        .addHandler(router.call);

    try {
      final InternetAddress bindAddress;
      if (_listenAddress == '0.0.0.0') {
        bindAddress = InternetAddress.anyIPv4;
      } else if (_listenAddress == 'localhost' ||
          _listenAddress == '127.0.0.1') {
        bindAddress = InternetAddress.loopbackIPv4;
      } else {
        bindAddress =
            InternetAddress(_listenAddress, type: InternetAddressType.any);
      }
      _server = await shelf_io.serve(handler, bindAddress, _port);
      // ignore: avoid_print
      print('[LocalApiServer] listening on port $_port');
    } catch (e) {
      _lastError = e.toString();
      // ignore: avoid_print
      print('[LocalApiServer] failed to start: $e');
    }
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static Future<void> restart() async {
    await loadConfig();
    await start();
  }

  // ── Route handlers ──

  static Future<Response> _handlePing(Request request) async {
    return _json({'status': 'ok'});
  }

  // ── Todo ──

  static Future<Response> _handleTodoList(Request request) async {
    final dateStr = request.url.queryParameters['date'];
    final typeStr = request.url.queryParameters['type'];
    final date = dateStr != null
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();
    final dateKey = DailyCompletionLog.dateKey(date);
    final today = DateTime.now();
    final todayKey = DailyCompletionLog.dateKey(today);

    final data = await TodoStorage.load();
    if (data == null) return _json([]);

    final results = <Map<String, dynamic>>[];

    // Daily templates active on this date
    for (final t in data.dailyTemplates) {
      if (typeStr != null && t.type.name != typeStr) continue;
      if (t.type != TaskType.daily) continue;
      final start = t.startDate ?? t.createdDate;
      final startKey = DailyCompletionLog.dateKey(start);
      if (dateKey.compareTo(startKey) < 0) continue;
      if (t.deletedDate != null) {
        final delKey = DailyCompletionLog.dateKey(t.deletedDate!);
        if (dateKey.compareTo(delKey) >= 0) continue;
      }
      final isCompleted = data.dailyLog.isCompleted(date, t.id);
      results.add({
        'id': t.id,
        'title': t.title,
        'emoji': t.emoji,
        'type': t.type.name,
        'isCompleted': isCompleted,
        'subtasks': t.subtasks
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'isCompleted':
                      data.dailyLog.isSubtaskCompleted(date, s.id),
                })
            .toList(),
        'dueDate': t.dueDate?.toIso8601String(),
        'scheduledDate': t.scheduledDate?.toIso8601String(),
      });
    }

    // One-time tasks (routineOnce / workOnce)
    for (final t in data.oneTimeTasks) {
      if (typeStr != null && t.type.name != typeStr) continue;
      if (t.type == TaskType.daily) continue;
      final sched = t.scheduledDate;
      if (sched != null) {
        final schedKey = DailyCompletionLog.dateKey(sched);
        // Show on scheduled date; if incomplete, carry forward through today
        if (dateKey.compareTo(schedKey) < 0) continue;
        if (t.isCompleted && dateKey != schedKey) continue;
        if (!t.isCompleted && dateKey.compareTo(todayKey) > 0) continue;
      }
      results.add({
        'id': t.id,
        'title': t.title,
        'emoji': t.emoji,
        'type': t.type.name,
        'isCompleted': t.isCompleted,
        'subtasks': t.subtasks
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'isCompleted': s.isCompleted,
                })
            .toList(),
        'dueDate': t.dueDate?.toIso8601String(),
        'scheduledDate': t.scheduledDate?.toIso8601String(),
      });
    }

    return _json(results);
  }

  static Future<Response> _handleTodoAdd(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');
    final title = body['title'] as String?;
    if (title == null || title.trim().isEmpty) {
      return _error(400, 'title is required');
    }
    final typeStr = body['type'] as String? ?? 'workOnce';
    final type = TaskType.values.where((t) => t.name == typeStr).firstOrNull ??
        TaskType.workOnce;
    final emoji = body['emoji'] as String?;
    DateTime? dueDate;
    if (body['dueDate'] != null) {
      dueDate = DateTime.tryParse(body['dueDate'] as String);
    }
    DateTime? scheduledDate;
    if (body['scheduledDate'] != null) {
      scheduledDate = DateTime.tryParse(body['scheduledDate'] as String);
    }

    final task = Task(
      title: title.trim(),
      type: type,
      emoji: emoji,
      dueDate: dueDate,
      scheduledDate: scheduledDate ?? DateTime.now(),
      startDate: type == TaskType.daily ? DateTime.now() : null,
    );

    final data = await TodoStorage.load() ??
        TodoData(
          dailyTemplates: [],
          oneTimeTasks: [],
          dailyLog: DailyCompletionLog(),
        );

    if (type == TaskType.daily) {
      await TodoStorage.save(TodoData(
        dailyTemplates: [...data.dailyTemplates, task],
        oneTimeTasks: data.oneTimeTasks,
        dailyLog: data.dailyLog,
        morningReminderHour: data.morningReminderHour,
        morningReminderMinute: data.morningReminderMinute,
        completionReminderHour: data.completionReminderHour,
        completionReminderMinute: data.completionReminderMinute,
        settingsModifiedAt: data.settingsModifiedAt,
      ));
    } else {
      await TodoStorage.save(TodoData(
        dailyTemplates: data.dailyTemplates,
        oneTimeTasks: [...data.oneTimeTasks, task],
        dailyLog: data.dailyLog,
        morningReminderHour: data.morningReminderHour,
        morningReminderMinute: data.morningReminderMinute,
        completionReminderHour: data.completionReminderHour,
        completionReminderMinute: data.completionReminderMinute,
        settingsModifiedAt: data.settingsModifiedAt,
      ));
    }
    return _json({'success': true, 'id': task.id});
  }

  static Future<Response> _handleTodoComplete(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');
    final id = body['id'] as String?;
    if (id == null) return _error(400, 'id is required');
    final completed = body['completed'] as bool? ?? true;
    final dateStr = body['date'] as String?;
    final date = dateStr != null
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();

    final data = await TodoStorage.load();
    if (data == null) return _error(404, 'no todo data');

    // Check if it's a daily template
    final dailyIdx = data.dailyTemplates.indexWhere((t) => t.id == id);
    if (dailyIdx >= 0) {
      final isCurrentlyCompleted = data.dailyLog.isCompleted(date, id);
      if (isCurrentlyCompleted != completed) {
        data.dailyLog.toggle(date, id);
      }
      await TodoStorage.save(data);
      return _json({'success': true});
    }

    // Check one-time tasks
    final idx = data.oneTimeTasks.indexWhere((t) => t.id == id);
    if (idx < 0) return _error(404, 'task not found');
    final updated = data.oneTimeTasks[idx].copyWith(
      isCompleted: completed,
      completedDate: completed ? DateTime.now() : null,
    );
    final newList = List<Task>.from(data.oneTimeTasks);
    newList[idx] = updated;
    await TodoStorage.save(TodoData(
      dailyTemplates: data.dailyTemplates,
      oneTimeTasks: newList,
      dailyLog: data.dailyLog,
      morningReminderHour: data.morningReminderHour,
      morningReminderMinute: data.morningReminderMinute,
      completionReminderHour: data.completionReminderHour,
      completionReminderMinute: data.completionReminderMinute,
      settingsModifiedAt: data.settingsModifiedAt,
    ));
    return _json({'success': true});
  }

  static Future<Response> _handleTodoStats(Request request) async {
    final now = DateTime.now();
    final todayKey = DailyCompletionLog.dateKey(now);
    final data = await TodoStorage.load();
    if (data == null) {
      return _json({'today_total': 0, 'today_completed': 0, 'overdue': 0});
    }

    var total = 0;
    var completed = 0;
    var overdue = 0;

    // Daily templates active today
    for (final t in data.dailyTemplates) {
      if (t.type != TaskType.daily) continue;
      final start = t.startDate ?? t.createdDate;
      final startKey = DailyCompletionLog.dateKey(start);
      if (todayKey.compareTo(startKey) < 0) continue;
      if (t.deletedDate != null) {
        final delKey = DailyCompletionLog.dateKey(t.deletedDate!);
        if (todayKey.compareTo(delKey) >= 0) continue;
      }
      total++;
      if (data.dailyLog.isCompleted(now, t.id)) completed++;
    }

    // One-time tasks visible today
    for (final t in data.oneTimeTasks) {
      final sched = t.scheduledDate;
      if (sched != null) {
        final schedKey = DailyCompletionLog.dateKey(sched);
        if (todayKey.compareTo(schedKey) < 0) continue;
        if (t.isCompleted && todayKey != schedKey) continue;
      }
      total++;
      if (t.isCompleted) completed++;
      // Overdue: has dueDate before today and not completed
      if (!t.isCompleted && t.dueDate != null) {
        final dueKey = DailyCompletionLog.dateKey(t.dueDate!);
        if (todayKey.compareTo(dueKey) > 0) overdue++;
      }
    }

    return _json({
      'today_total': total,
      'today_completed': completed,
      'overdue': overdue,
    });
  }

  // ── Finance ──

  static Future<Response> _handleFinanceSummary(Request request) async {
    final monthStr = request.url.queryParameters['month'];
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    if (monthStr != null) {
      final parts = monthStr.split('-');
      if (parts.length == 2) {
        year = int.tryParse(parts[0]) ?? year;
        month = int.tryParse(parts[1]) ?? month;
      }
    }
    final monthStart = DateTime(year, month);
    final monthEnd = DateTime(year, month + 1);

    final finData = await FinanceStorage.load();
    if (finData == null) {
      return _json({
        'income': 0.0,
        'expense': 0.0,
        'balance': 0.0,
        'accounts': [],
        'top_expense_categories': [],
      });
    }
    final rateData = await ExchangeRateStorage.load();

    // Monthly income/expense
    var income = 0.0;
    var expense = 0.0;
    final catExpense = <String, double>{};
    final catCount = <String, int>{};
    for (final tx in finData.transactions) {
      if (tx.date.isBefore(monthStart) || !tx.date.isBefore(monthEnd)) {
        continue;
      }
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
        case TransactionType.expense:
          expense += tx.amount;
          final catId = tx.categoryId ?? '';
          catExpense[catId] = (catExpense[catId] ?? 0) + tx.amount;
          catCount[catId] = (catCount[catId] ?? 0) + 1;
        case TransactionType.transfer:
          break;
      }
    }

    // Account balances
    final accounts = finData.accounts.map((a) {
      final bal = accountBalance(a, finData.transactions, rateData);
      return {
        'id': a.id,
        'name': a.name,
        'type': a.type.name,
        'currency': a.currency,
        'balance': double.parse(bal.toStringAsFixed(2)),
      };
    }).toList();

    // Top expense categories
    final catMap = {for (final c in finData.categories) c.id: c.name};
    final topCats = catExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExpenseCategories = topCats.take(5).map((e) {
      return {
        'name': catMap[e.key] ?? 'Uncategorized',
        'amount': double.parse(e.value.toStringAsFixed(2)),
        'count': catCount[e.key] ?? 0,
      };
    }).toList();

    return _json({
      'income': double.parse(income.toStringAsFixed(2)),
      'expense': double.parse(expense.toStringAsFixed(2)),
      'balance': double.parse((income - expense).toStringAsFixed(2)),
      'accounts': accounts,
      'top_expense_categories': topExpenseCategories,
    });
  }

  static Future<Response> _handleFinanceTransactions(Request request) async {
    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 20;
    final offset =
        int.tryParse(request.url.queryParameters['offset'] ?? '') ?? 0;
    final typeStr = request.url.queryParameters['type'];

    final finData = await FinanceStorage.load();
    if (finData == null) return _json([]);

    var txs = finData.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (typeStr != null) {
      final type =
          TransactionType.values.where((t) => t.name == typeStr).firstOrNull;
      if (type != null) {
        txs = txs.where((t) => t.type == type).toList();
      }
    }

    final paged = txs.skip(offset).take(limit);
    final catMap = {for (final c in finData.categories) c.id: c.name};
    final acctMap = {for (final a in finData.accounts) a.id: a.name};

    return _json(paged
        .map((t) => {
              'id': t.id,
              'type': t.type.name,
              'amount': t.amount,
              'currency': t.currency,
              'accountId': t.accountId,
              'accountName': acctMap[t.accountId],
              'toAccountId': t.toAccountId,
              'toAccountName':
                  t.toAccountId != null ? acctMap[t.toAccountId] : null,
              'categoryId': t.categoryId,
              'categoryName':
                  t.categoryId != null ? catMap[t.categoryId] : null,
              'note': t.note,
              'date': t.date.toIso8601String(),
            })
        .toList());
  }

  static Future<Response> _handleFinanceAddTransaction(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');

    final typeStr = body['type'] as String?;
    if (typeStr == null) return _error(400, 'type is required');
    final type = TransactionType.values
            .where((t) => t.name == typeStr)
            .firstOrNull ??
        TransactionType.expense;

    final amount = (body['amount'] as num?)?.toDouble();
    if (amount == null || amount <= 0) return _error(400, 'valid amount is required');

    final accountId = body['accountId'] as String?;
    if (accountId == null) return _error(400, 'accountId is required');

    final currency = body['currency'] as String? ?? 'CNY';
    final toAccountId = body['toAccountId'] as String?;
    final categoryId = body['categoryId'] as String?;
    final note = body['note'] as String? ?? '';
    DateTime? date;
    if (body['date'] != null) {
      date = DateTime.tryParse(body['date'] as String);
    }

    final tx = Transaction(
      type: type,
      amount: amount,
      currency: currency,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      note: note,
      date: date,
    );

    final finData = await FinanceStorage.load() ??
        FinanceData(accounts: [], categories: [], transactions: []);

    await FinanceStorage.save(FinanceData(
      accounts: finData.accounts,
      categories: finData.categories,
      transactions: [...finData.transactions, tx],
      subscriptions: finData.subscriptions,
      defaultCurrency: finData.defaultCurrency,
      settingsModifiedAt: finData.settingsModifiedAt,
      subscriptionReminderHour: finData.subscriptionReminderHour,
      subscriptionReminderMinute: finData.subscriptionReminderMinute,
      subscriptionSortMode: finData.subscriptionSortMode,
      subscriptionCustomOrder: finData.subscriptionCustomOrder,
    ));
    return _json({'success': true, 'id': tx.id});
  }

  static Future<Response> _handleFinanceSubscriptions(Request request) async {
    final finData = await FinanceStorage.load();
    if (finData == null) return _json([]);
    final active = finData.subscriptions.where((s) => s.isActive);
    return _json(active
        .map((s) => {
              'id': s.id,
              'name': s.name,
              'emoji': s.emoji,
              'amount': s.amount,
              'currency': s.currency,
              'nextBillingDate': s.nextBillingDate?.toIso8601String(),
              'billingCycleType': s.billingCycleType.name,
            })
        .toList());
  }

  // ── Weight ──

  static Future<Response> _handleWeightList(Request request) async {
    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 30;
    final data = await WeightStorage.load();
    if (data == null) return _json([]);
    final sorted = data.records.toList()
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    return _json(sorted
        .take(limit)
        .map((r) => {
              'id': r.id,
              'weight': r.weight,
              'date': DateFormat('yyyy-MM-dd').format(r.datetime),
            })
        .toList());
  }

  static Future<Response> _handleWeightAdd(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');
    final weight = (body['weight'] as num?)?.toDouble();
    if (weight == null || weight <= 0) {
      return _error(400, 'valid weight is required');
    }
    DateTime? date;
    if (body['date'] != null) {
      date = DateTime.tryParse(body['date'] as String);
    }

    final record = WeightRecord(weight: weight, datetime: date);
    final data = await WeightStorage.load() ?? WeightData(records: []);
    await WeightStorage.save(WeightData(
      height: data.height,
      records: [...data.records, record],
      reminderMode: data.reminderMode,
      morningHour: data.morningHour,
      morningMinute: data.morningMinute,
      eveningHour: data.eveningHour,
      eveningMinute: data.eveningMinute,
      settingsModifiedAt: data.settingsModifiedAt,
    ));
    return _json({'success': true, 'id': record.id});
  }

  static Future<Response> _handleWeightStats(Request request) async {
    final data = await WeightStorage.load();
    if (data == null || data.records.isEmpty) {
      return _json({
        'latest': null,
        'avg_7d': null,
        'avg_30d': null,
        'trend': 'unknown',
      });
    }
    final sorted = data.records.toList()
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    final latest = sorted.first.weight;
    final now = DateTime.now();
    final r7 = sorted
        .where((r) => now.difference(r.datetime).inDays <= 7)
        .map((r) => r.weight)
        .toList();
    final r30 = sorted
        .where((r) => now.difference(r.datetime).inDays <= 30)
        .map((r) => r.weight)
        .toList();
    final avg7 =
        r7.isNotEmpty ? r7.reduce((a, b) => a + b) / r7.length : null;
    final avg30 =
        r30.isNotEmpty ? r30.reduce((a, b) => a + b) / r30.length : null;

    // Trend: compare avg of first half vs second half of last 30 days
    String trend = 'unknown';
    if (r30.length >= 4) {
      final mid = r30.length ~/ 2;
      final recent = r30.sublist(0, mid);
      final older = r30.sublist(mid);
      final avgRecent = recent.reduce((a, b) => a + b) / recent.length;
      final avgOlder = older.reduce((a, b) => a + b) / older.length;
      final diff = avgRecent - avgOlder;
      if (diff > 0.3) {
        trend = 'up';
      } else if (diff < -0.3) {
        trend = 'down';
      } else {
        trend = 'stable';
      }
    }

    return _json({
      'latest': double.parse(latest.toStringAsFixed(1)),
      'avg_7d': avg7 != null ? double.parse(avg7.toStringAsFixed(1)) : null,
      'avg_30d':
          avg30 != null ? double.parse(avg30.toStringAsFixed(1)) : null,
      'trend': trend,
    });
  }

  // ── Helpers ──

  static Response _json(Object data) => Response.ok(
        jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

  static Response _error(int status, String message) => Response(
        status,
        body: jsonEncode({'error': message}),
        headers: {'Content-Type': 'application/json'},
      );

  static Future<Map<String, dynamic>?> _parseBody(Request request) async {
    try {
      final raw = await request.readAsString();
      if (raw.trim().isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Middleware ──

  static Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  static Middleware _authMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final remoteAddr = (request.context['shelf.io.connection_info']
                as HttpConnectionInfo?)
            ?.remoteAddress;
        final isLoopback = remoteAddr == null || remoteAddr.isLoopback;
        final hasCredentials = _username != null &&
            _username!.isNotEmpty &&
            _password != null &&
            _password!.isNotEmpty;
        if (!isLoopback && !hasCredentials) {
          return _error(
              403, 'authentication required for non-localhost access');
        }
        if (hasCredentials && !isLoopback) {
          final authHeader = request.headers['authorization'];
          if (authHeader == null || !_validateBasicAuth(authHeader)) {
            return Response(
              401,
              body: jsonEncode({'error': 'unauthorized'}),
              headers: {
                'Content-Type': 'application/json',
                'WWW-Authenticate': 'Basic realm="MyDay API"',
              },
            );
          }
        }
        return innerHandler(request);
      };
    };
  }

  static bool _validateBasicAuth(String header) {
    if (!header.startsWith('Basic ')) return false;
    try {
      final decoded = utf8.decode(base64Decode(header.substring(6)));
      final parts = decoded.split(':');
      if (parts.length < 2) return false;
      return parts[0] == _username && parts.sublist(1).join(':') == _password;
    } catch (_) {
      return false;
    }
  }

  static Middleware _errorMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          return await innerHandler(request);
        } catch (e) {
          return _error(500, 'internal error: $e');
        }
      };
    };
  }
}
