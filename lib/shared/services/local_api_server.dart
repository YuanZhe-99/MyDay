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

  /// Purpose: Return port.
  /// Inputs: None.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: When port 0 is configured for tests, this becomes the bound port after start.
  static int get port => _port;

  /// Purpose: Return listen address.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  static String get listenAddress => _listenAddress;

  /// Purpose: Return enabled.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  static bool get enabled => _enabled;

  /// Purpose: Return whether running is true.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  static bool get isRunning => _server != null;

  /// Purpose: Return last error.
  /// Inputs: None.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: None.
  static String? get lastError => _lastError;

  /// Purpose: Load API config from storage.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Reads `storage_config.json` and updates cached API settings.
  /// Notes: Invalid or absent values fall back to the localhost default.
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

  /// Purpose: Start the local HTTP API server when enabled.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a desktop HTTP listener and updates `_lastError`.
  /// Notes: Non-loopback binding is refused unless credentials are configured.
  static Future<void> start() async {
    await loadConfig();
    await stop();
    _lastError = null;
    if (!_enabled) return;

    final isNonLoopback =
        _listenAddress == '0.0.0.0' ||
        (_listenAddress != 'localhost' && _listenAddress != '127.0.0.1');
    if (isNonLoopback && !_hasCredentials) {
      _lastError = 'credentials_required';
      return;
    }

    try {
      _server = await shelf_io.serve(_buildHandler(), _bindAddress(), _port);
      _port = _server!.port;
      // ignore: avoid_print
      print('[LocalApiServer] listening on port $_port');
    } catch (e) {
      _lastError = e.toString();
      // ignore: avoid_print
      print('[LocalApiServer] failed to start: $e');
    }
  }

  /// Purpose: Stop the local HTTP API server.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Closes the active listener if one exists.
  /// Notes: None.
  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// Purpose: Restart the local HTTP API server after reloading config.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Reloads config, closes any old listener, and may open a new one.
  /// Notes: None.
  static Future<void> restart() async {
    await loadConfig();
    await start();
  }

  /// Purpose: Build the request handler for local API tests.
  /// Inputs: Optional `username` and `password`.
  /// Returns: `Handler`.
  /// Side effects: Updates in-memory credentials used by the handler.
  /// Notes: Production startup uses `start()` instead of this test hook.
  static Handler buildHandlerForTesting({String? username, String? password}) {
    _username = username;
    _password = password;
    return _buildHandler();
  }

  /// Purpose: Build the Shelf request pipeline and route table.
  /// Inputs: None.
  /// Returns: `Handler`.
  /// Side effects: None.
  /// Notes: Used by production startup and tests so route behavior stays identical.
  static Handler _buildHandler() {
    final router = Router();
    router.get('/ping', _handlePing);

    router.get('/todo/list', _handleTodoList);
    router.get('/todo/day', _handleTodoDay);
    router.post('/todo/add', _handleTodoAdd);
    router.post('/todo/complete', _handleTodoComplete);
    router.post('/todo/score', _handleTodoScore);
    router.get('/todo/stats', _handleTodoStats);

    router.get('/finance/summary', _handleFinanceSummary);
    router.get('/finance/accounts', _handleFinanceAccounts);
    router.get('/finance/categories', _handleFinanceCategories);
    router.get('/finance/transactions', _handleFinanceTransactions);
    router.post('/finance/add_transaction', _handleFinanceAddTransaction);
    router.get('/finance/subscriptions', _handleFinanceSubscriptions);

    router.get('/weight/list', _handleWeightList);
    router.post('/weight/add', _handleWeightAdd);
    router.get('/weight/stats', _handleWeightStats);

    return const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addMiddleware(_errorMiddleware())
        .addHandler(router.call);
  }

  /// Purpose: Resolve the configured listen address to an InternetAddress.
  /// Inputs: None.
  /// Returns: `InternetAddress`.
  /// Side effects: None.
  /// Notes: `localhost` must use `loopbackIPv4`; it is not a numeric address.
  static InternetAddress _bindAddress() {
    if (_listenAddress == '0.0.0.0') return InternetAddress.anyIPv4;
    if (_listenAddress == 'localhost' || _listenAddress == '127.0.0.1') {
      return InternetAddress.loopbackIPv4;
    }
    return InternetAddress(_listenAddress, type: InternetAddressType.any);
  }

  // Route handlers

  /// Purpose: Report that the local API server is alive.
  /// Inputs: `request`.
  /// Returns: `Future<Response>`.
  /// Side effects: None.
  /// Notes: None.
  static Future<Response> _handlePing(Request request) async {
    return _json({'status': 'ok'});
  }

  // Todo

  /// Purpose: List tasks visible on a requested day.
  /// Inputs: `request` query `date` and optional `type`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads todo storage.
  /// Notes: Response remains a top-level array for backward compatibility.
  static Future<Response> _handleTodoList(Request request) async {
    final date = _queryDate(request, 'date') ?? DateTime.now();
    final typeStr = request.url.queryParameters['type'];
    final data = await TodoStorage.load();
    if (data == null) return _json([]);
    return _json(_visibleTodoTasks(data, date, typeStr: typeStr));
  }

  /// Purpose: Return a day-level todo summary with score and tasks.
  /// Inputs: `request` query `date`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads todo storage.
  /// Notes: Missing todo data returns an empty day with score zero.
  static Future<Response> _handleTodoDay(Request request) async {
    final date = _queryDate(request, 'date') ?? DateTime.now();
    final dateKey = DailyCompletionLog.dateKey(date);
    final data =
        await TodoStorage.load() ??
        TodoData(
          dailyTemplates: [],
          oneTimeTasks: [],
          dailyLog: DailyCompletionLog(),
          dailyScores: DailyScoreLog(),
        );
    final tasks = _visibleTodoTasks(data, date);
    final completed = tasks.where((t) => t['isCompleted'] == true).length;
    return _json({
      'date': dateKey,
      'score': data.dailyScores.scoreFor(date),
      'total': tasks.length,
      'completed': completed,
      'tasks': tasks,
    });
  }

  /// Purpose: Add a todo task through the local API.
  /// Inputs: JSON body with title, type, optional dates, note, reminder, subtasks, and recurrence.
  /// Returns: `Future<Response>`.
  /// Side effects: Writes todo storage.
  /// Notes: Daily tasks use `scheduledDate` as `startDate`; one-time tasks use it as the scheduled date.
  static Future<Response> _handleTodoAdd(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');

    final title = (body['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return _error(400, 'title is required');

    final typeStr = body['type'] as String? ?? 'workOnce';
    final type = _taskTypeByName(typeStr);
    if (type == null) return _error(400, 'invalid task type');

    final dueDate = _optionalBodyDate(body, 'dueDate');
    if (body['dueDate'] != null && dueDate == null) {
      return _error(400, 'invalid dueDate');
    }
    final scheduledDate = _optionalBodyDate(body, 'scheduledDate');
    if (body['scheduledDate'] != null && scheduledDate == null) {
      return _error(400, 'invalid scheduledDate');
    }
    final reminderTime = _optionalBodyDate(body, 'reminderTime');
    if (body['reminderTime'] != null && reminderTime == null) {
      return _error(400, 'invalid reminderTime');
    }
    final recurrence = _parseRecurrence(body['recurrence']);
    if (body['recurrence'] != null && recurrence == null) {
      return _error(400, 'invalid recurrence');
    }

    final task = Task(
      title: title,
      note: _optionalTrimmedString(body['note']),
      type: type,
      emoji: _optionalTrimmedString(body['emoji']),
      reminderTime: reminderTime,
      subtasks: _parseSubtasks(body['subtasks']),
      dueDate: dueDate,
      scheduledDate: type == TaskType.daily
          ? null
          : (scheduledDate ?? DateTime.now()),
      startDate: type == TaskType.daily
          ? (scheduledDate ?? DateTime.now())
          : null,
      recurrence: type == TaskType.daily ? null : recurrence,
    );

    final data =
        await TodoStorage.load() ??
        TodoData(
          dailyTemplates: [],
          oneTimeTasks: [],
          dailyLog: DailyCompletionLog(),
          dailyScores: DailyScoreLog(),
        );
    final next = type == TaskType.daily
        ? _todoDataWith(data, dailyTemplates: [...data.dailyTemplates, task])
        : _todoDataWith(data, oneTimeTasks: [...data.oneTimeTasks, task]);
    await TodoStorage.save(next);
    return _json({'success': true, 'id': task.id, 'task': _todoTaskJson(task)});
  }

  /// Purpose: Complete or reopen a task or subtask.
  /// Inputs: JSON body with task `id`, optional `subtaskId`, `date`, `completed`, and recurrence flag.
  /// Returns: `Future<Response>`.
  /// Side effects: Writes todo storage.
  /// Notes: Daily completion is date-scoped; one-time task completion is stored on the task.
  static Future<Response> _handleTodoComplete(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');
    final id = body['id'] as String?;
    if (id == null || id.isEmpty) return _error(400, 'id is required');
    final completed = body['completed'] as bool? ?? true;
    final subtaskId = body['subtaskId'] as String?;
    final createNextRecurrence = body['createNextRecurrence'] == true;
    final date = _optionalBodyDate(body, 'date') ?? DateTime.now();
    if (body['date'] != null && _optionalBodyDate(body, 'date') == null) {
      return _error(400, 'invalid date');
    }

    final data = await TodoStorage.load();
    if (data == null) return _error(404, 'no todo data');

    final dailyIdx = data.dailyTemplates.indexWhere((t) => t.id == id);
    if (dailyIdx >= 0) {
      final task = data.dailyTemplates[dailyIdx];
      if (subtaskId != null && subtaskId.isNotEmpty) {
        if (!task.subtasks.any((s) => s.id == subtaskId)) {
          return _error(404, 'subtask not found');
        }
        final currentlyCompleted = data.dailyLog.isSubtaskCompleted(
          date,
          subtaskId,
        );
        if (currentlyCompleted != completed) {
          data.dailyLog.toggleSubtask(date, subtaskId);
        }
      } else {
        final currentlyCompleted = data.dailyLog.isCompleted(date, id);
        if (currentlyCompleted != completed) data.dailyLog.toggle(date, id);
      }
      await TodoStorage.save(data);
      return _json({'success': true});
    }

    final idx = data.oneTimeTasks.indexWhere((t) => t.id == id);
    if (idx < 0) return _error(404, 'task not found');
    final existing = data.oneTimeTasks[idx];
    var updated = existing;

    if (subtaskId != null && subtaskId.isNotEmpty) {
      final subIdx = existing.subtasks.indexWhere((s) => s.id == subtaskId);
      if (subIdx < 0) return _error(404, 'subtask not found');
      final subtasks = List<SubTask>.from(existing.subtasks);
      subtasks[subIdx] = subtasks[subIdx].copyWith(isCompleted: completed);
      updated = _copyOneTimeTask(existing, subtasks: subtasks);
    } else {
      updated = _copyOneTimeTask(
        existing,
        isCompleted: completed,
        completedDate: completed ? DateTime.now() : null,
      );
      if (!existing.isCompleted &&
          completed &&
          createNextRecurrence &&
          existing.recurrence != null) {
        final nextDate = existing.recurrence!.nextDate(
          existing.scheduledDate ?? date,
        );
        final nextTask = Task(
          title: existing.title,
          note: existing.note,
          emoji: existing.emoji,
          type: existing.type,
          reminderTime: existing.reminderTime,
          subtasks: existing.subtasks
              .map((s) => SubTask(title: s.title))
              .toList(),
          scheduledDate: nextDate,
          dueDate: existing.dueDate != null
              ? existing.recurrence!.nextDate(existing.dueDate!)
              : null,
          recurrence: existing.recurrence,
        );
        final oneTimeTasks = List<Task>.from(data.oneTimeTasks)
          ..[idx] = updated
          ..add(nextTask);
        await TodoStorage.save(_todoDataWith(data, oneTimeTasks: oneTimeTasks));
        return _json({
          'success': true,
          'nextTaskId': nextTask.id,
          'nextScheduledDate': nextDate.toIso8601String(),
        });
      }
    }

    final oneTimeTasks = List<Task>.from(data.oneTimeTasks)..[idx] = updated;
    await TodoStorage.save(_todoDataWith(data, oneTimeTasks: oneTimeTasks));
    return _json({'success': true});
  }

  /// Purpose: Store the day score for a todo date.
  /// Inputs: JSON body with `score` and optional `date`.
  /// Returns: `Future<Response>`.
  /// Side effects: Writes todo storage.
  /// Notes: Scores are clamped to the model range -5 through 5.
  static Future<Response> _handleTodoScore(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');
    final scoreValue = body['score'];
    if (scoreValue is! num) return _error(400, 'score is required');
    final date = _optionalBodyDate(body, 'date') ?? DateTime.now();
    if (body['date'] != null && _optionalBodyDate(body, 'date') == null) {
      return _error(400, 'invalid date');
    }
    final data =
        await TodoStorage.load() ??
        TodoData(
          dailyTemplates: [],
          oneTimeTasks: [],
          dailyLog: DailyCompletionLog(),
          dailyScores: DailyScoreLog(),
        );
    data.dailyScores.setScore(date, scoreValue.round());
    await TodoStorage.save(data);
    return _json({
      'success': true,
      'date': DailyCompletionLog.dateKey(date),
      'score': data.dailyScores.scoreFor(date),
    });
  }

  /// Purpose: Return today's todo completion statistics.
  /// Inputs: `request`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads todo storage.
  /// Notes: Keeps the historical snake_case keys for plugin compatibility.
  static Future<Response> _handleTodoStats(Request request) async {
    final now = DateTime.now();
    final todayKey = DailyCompletionLog.dateKey(now);
    final data = await TodoStorage.load();
    if (data == null) {
      return _json({'today_total': 0, 'today_completed': 0, 'overdue': 0});
    }

    final tasks = _visibleTodoTasks(data, now);
    final completed = tasks.where((t) => t['isCompleted'] == true).length;
    var overdue = 0;
    for (final t in data.oneTimeTasks) {
      if (!t.isCompleted && t.dueDate != null) {
        final dueKey = DailyCompletionLog.dateKey(t.dueDate!);
        if (todayKey.compareTo(dueKey) > 0) overdue++;
      }
    }

    return _json({
      'today_total': tasks.length,
      'today_completed': completed,
      'overdue': overdue,
    });
  }

  // Finance

  /// Purpose: Return a converted monthly finance summary.
  /// Inputs: `request` query `month`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads finance and exchange-rate storage.
  /// Notes: Income, expense, balance, and category totals are in the default currency.
  static Future<Response> _handleFinanceSummary(Request request) async {
    final monthStart =
        _queryMonth(request) ??
        DateTime(DateTime.now().year, DateTime.now().month);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);
    final finData = await FinanceStorage.load();
    if (finData == null) {
      return _json({
        'month': DateFormat('yyyy-MM').format(monthStart),
        'defaultCurrency': 'CNY',
        'income': 0.0,
        'expense': 0.0,
        'balance': 0.0,
        'total_assets': 0.0,
        'accounts': [],
        'category_totals': [],
        'top_expense_categories': [],
      });
    }
    final rateData = await ExchangeRateStorage.load();
    final defaultCurrency = finData.defaultCurrency;

    var income = 0.0;
    var expense = 0.0;
    final categoryTotals = <String, _CategoryTotal>{};
    for (final tx in finData.transactions) {
      if (tx.date.isBefore(monthStart) || !tx.date.isBefore(monthEnd)) continue;
      final converted = convertCurrency(
        rateData.ratesAt(tx.rateSnapshotId),
        tx.amount,
        tx.currency,
        defaultCurrency,
      );
      switch (tx.type) {
        case TransactionType.income:
          income += converted;
          _addCategoryTotal(categoryTotals, tx, converted);
        case TransactionType.expense:
          expense += converted;
          _addCategoryTotal(categoryTotals, tx, converted);
        case TransactionType.transfer:
          break;
      }
    }

    final categoriesById = {for (final c in finData.categories) c.id: c};
    final accounts = finData.accounts.map((account) {
      final balance = accountBalance(account, finData.transactions, rateData);
      final convertedBalance = convertCurrency(
        rateData.currentRates,
        balance,
        account.currency,
        defaultCurrency,
      );
      return _accountJson(
        account,
        balance: balance,
        convertedBalance: convertedBalance,
        defaultCurrency: defaultCurrency,
      );
    }).toList();
    final totalAssets = accounts.fold<double>(
      0,
      (sum, account) =>
          sum + ((account['convertedBalance'] as num?)?.toDouble() ?? 0),
    );

    final totals =
        categoryTotals.values.map((total) {
          final category = categoriesById[total.categoryId];
          return {
            'categoryId': total.categoryId.isEmpty ? null : total.categoryId,
            'name': category?.name ?? 'Uncategorized',
            'type': total.type.name,
            'amount': _round(total.amount),
            'count': total.count,
            'currency': defaultCurrency,
          };
        }).toList()..sort(
          (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
        );
    final topExpenseCategories = totals
        .where((total) => total['type'] == TransactionType.expense.name)
        .take(5)
        .toList();

    return _json({
      'month': DateFormat('yyyy-MM').format(monthStart),
      'defaultCurrency': defaultCurrency,
      'income': _round(income),
      'expense': _round(expense),
      'balance': _round(income - expense),
      'total_assets': _round(totalAssets),
      'accounts': accounts,
      'category_totals': totals,
      'top_expense_categories': topExpenseCategories,
    });
  }

  /// Purpose: Return safe finance account details.
  /// Inputs: `request` query optional `type`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads finance and exchange-rate storage.
  /// Notes: Security-sensitive card fields are intentionally omitted.
  static Future<Response> _handleFinanceAccounts(Request request) async {
    final typeStr = request.url.queryParameters['type'];
    final type = typeStr == null ? null : _accountTypeByName(typeStr);
    if (typeStr != null && type == null) {
      return _error(400, 'invalid account type');
    }
    final finData = await FinanceStorage.load();
    if (finData == null) return _json([]);
    final rateData = await ExchangeRateStorage.load();
    final accounts = finData.accounts.where(
      (a) => type == null || a.type == type,
    );
    return _json(
      accounts.map((account) {
        final balance = accountBalance(account, finData.transactions, rateData);
        return _accountJson(
          account,
          balance: balance,
          convertedBalance: convertCurrency(
            rateData.currentRates,
            balance,
            account.currency,
            finData.defaultCurrency,
          ),
          defaultCurrency: finData.defaultCurrency,
        );
      }).toList(),
    );
  }

  /// Purpose: Return finance categories, optionally filtered by transaction type.
  /// Inputs: `request` query optional `type`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads finance storage.
  /// Notes: Transfer categories are supported by the underlying model.
  static Future<Response> _handleFinanceCategories(Request request) async {
    final typeStr = request.url.queryParameters['type'];
    final type = typeStr == null ? null : _transactionTypeByName(typeStr);
    if (typeStr != null && type == null) {
      return _error(400, 'invalid transaction type');
    }
    final finData = await FinanceStorage.load();
    if (finData == null) return _json([]);
    return _json(
      finData.categories
          .where((category) => type == null || category.type == type)
          .map(_categoryJson)
          .toList(),
    );
  }

  /// Purpose: Return finance transactions with names and transfer fields.
  /// Inputs: `request` query filters for pagination, type, month, dates, account, and category.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads finance storage.
  /// Notes: Results are newest first and remain a top-level array for compatibility.
  static Future<Response> _handleFinanceTransactions(Request request) async {
    final limit = _queryInt(request, 'limit', defaultValue: 20).clamp(0, 200);
    final offset = _queryInt(
      request,
      'offset',
      defaultValue: 0,
    ).clamp(0, 1000000);
    final typeStr = request.url.queryParameters['type'];
    final type = typeStr == null ? null : _transactionTypeByName(typeStr);
    if (typeStr != null && type == null) {
      return _error(400, 'invalid transaction type');
    }
    final monthStart = _queryMonth(request);
    final rangeStart =
        monthStart ??
        _queryDate(request, 'startDate') ??
        _queryDate(request, 'start');
    final rangeEnd = monthStart != null
        ? DateTime(monthStart.year, monthStart.month + 1)
        : (_queryDate(request, 'endDate') ?? _queryDate(request, 'end'));
    final accountId = request.url.queryParameters['accountId'];
    final categoryId = request.url.queryParameters['categoryId'];

    final finData = await FinanceStorage.load();
    if (finData == null) return _json([]);

    var txs = finData.transactions.where((tx) {
      if (type != null && tx.type != type) return false;
      if (accountId != null &&
          tx.accountId != accountId &&
          tx.toAccountId != accountId) {
        return false;
      }
      if (categoryId != null && tx.categoryId != categoryId) return false;
      if (rangeStart != null && tx.date.isBefore(rangeStart)) return false;
      if (rangeEnd != null) {
        if (monthStart != null) {
          if (!tx.date.isBefore(rangeEnd)) return false;
        } else if (tx.date.isAfter(rangeEnd)) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final accountsById = {for (final a in finData.accounts) a.id: a};
    final categoriesById = {for (final c in finData.categories) c.id: c};
    return _json(
      txs
          .skip(offset)
          .take(limit)
          .map(
            (tx) => _transactionJson(
              tx,
              accountsById: accountsById,
              categoriesById: categoriesById,
            ),
          )
          .toList(),
    );
  }

  /// Purpose: Add a validated finance transaction.
  /// Inputs: JSON body with transaction fields and optional transfer target fields.
  /// Returns: `Future<Response>`.
  /// Side effects: Writes finance storage.
  /// Notes: The current exchange-rate snapshot id is stored for converted summaries.
  static Future<Response> _handleFinanceAddTransaction(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');

    final type = _transactionTypeByName(body['type'] as String?);
    if (type == null) return _error(400, 'type is required');
    final amount = _positiveDouble(body['amount']);
    if (amount == null) return _error(400, 'valid amount is required');

    final finData =
        await FinanceStorage.load() ??
        FinanceData(accounts: [], categories: [], transactions: []);
    final accountId = body['accountId'] as String?;
    if (accountId == null || accountId.isEmpty) {
      return _error(400, 'accountId is required');
    }
    final account = finData.accounts
        .where((a) => a.id == accountId)
        .firstOrNull;
    if (account == null) return _error(404, 'account not found');

    final categoryId = body['categoryId'] as String?;
    final category = categoryId == null || categoryId.isEmpty
        ? null
        : finData.categories.where((c) => c.id == categoryId).firstOrNull;
    if (categoryId != null && categoryId.isNotEmpty && category == null) {
      return _error(404, 'category not found');
    }
    if (category != null && category.type != type) {
      return _error(400, 'category type does not match transaction type');
    }

    Account? targetAccount;
    final toAccountId = body['toAccountId'] as String?;
    if (type == TransactionType.transfer) {
      if (toAccountId == null || toAccountId.isEmpty) {
        return _error(400, 'toAccountId is required for transfer');
      }
      targetAccount = finData.accounts
          .where((a) => a.id == toAccountId)
          .firstOrNull;
      if (targetAccount == null) return _error(404, 'target account not found');
      if (targetAccount.id == account.id) {
        return _error(400, 'target account must differ from source account');
      }
    }

    final toAmount = _optionalPositiveDouble(body['toAmount']);
    if (body['toAmount'] != null && toAmount == null) {
      return _error(400, 'valid toAmount is required');
    }
    final date = _optionalBodyDate(body, 'date');
    if (body['date'] != null && date == null) {
      return _error(400, 'invalid date');
    }
    final rateData = await ExchangeRateStorage.load();
    final currentSnapshotId = rateData.currentSnapshotId.isEmpty
        ? null
        : rateData.currentSnapshotId;

    final tx = Transaction(
      type: type,
      amount: amount,
      currency: (body['currency'] as String?)?.trim().isNotEmpty == true
          ? (body['currency'] as String).trim().toUpperCase()
          : account.currency,
      rateSnapshotId: currentSnapshotId,
      accountId: account.id,
      toAccountId: type == TransactionType.transfer ? targetAccount?.id : null,
      toAmount: type == TransactionType.transfer ? toAmount : null,
      toCurrency: type == TransactionType.transfer
          ? ((body['toCurrency'] as String?)?.trim().isNotEmpty == true
                ? (body['toCurrency'] as String).trim().toUpperCase()
                : targetAccount?.currency)
          : null,
      categoryId: category?.id,
      note: body['note'] as String? ?? '',
      date: date,
    );

    final next = FinanceData(
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
      accountSortModes: finData.accountSortModes,
      accountCustomOrders: finData.accountCustomOrders,
      accountPickerSettings: finData.accountPickerSettings,
    );
    await FinanceStorage.save(next);
    return _json({
      'success': true,
      'id': tx.id,
      'transaction': _transactionJson(tx),
    });
  }

  /// Purpose: Return subscriptions with account and category names.
  /// Inputs: `request` query optional `includeInactive`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads finance storage.
  /// Notes: Inactive subscriptions remain hidden unless explicitly requested.
  static Future<Response> _handleFinanceSubscriptions(Request request) async {
    final includeInactive = _queryBool(request, 'includeInactive');
    final finData = await FinanceStorage.load();
    if (finData == null) return _json([]);
    final accountsById = {for (final a in finData.accounts) a.id: a};
    final categoriesById = {for (final c in finData.categories) c.id: c};
    return _json(
      finData.subscriptions
          .where((s) => includeInactive || s.isActive)
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'emoji': s.emoji,
              'imagePath': s.imagePath,
              'startDate': s.startDate.toIso8601String(),
              'trialDays': s.trialDays,
              'billingCycleType': s.billingCycleType.name,
              'billingInterval': s.billingInterval,
              'amount': s.amount,
              'currency': s.currency,
              'accountId': s.accountId,
              'accountName': accountsById[s.accountId]?.name,
              'categoryId': s.categoryId,
              'categoryName': s.categoryId != null
                  ? categoriesById[s.categoryId]?.name
                  : null,
              'note': s.note,
              'isActive': s.isActive,
              'cancelledAt': s.cancelledAt?.toIso8601String(),
              'cancelType': s.cancelType?.name,
              'nextBillingDate': s.nextBillingDate?.toIso8601String(),
              'modifiedAt': s.modifiedAt.toIso8601String(),
            },
          )
          .toList(),
    );
  }

  // Weight

  /// Purpose: Return recent weight records with effective measurements.
  /// Inputs: `request` query `limit`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads weight storage.
  /// Notes: Missing circumference fields inherit previous positive values in `effectiveMeasurements`.
  static Future<Response> _handleWeightList(Request request) async {
    final limit = _queryInt(request, 'limit', defaultValue: 30).clamp(0, 200);
    final data = await WeightStorage.load();
    if (data == null) return _json([]);
    final sorted = data.records.toList()
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    return _json(
      sorted.take(limit).map((r) => _weightRecordJson(r, data)).toList(),
    );
  }

  /// Purpose: Add a weight record with optional body composition and measurements.
  /// Inputs: JSON body with `weight`, optional `date`, `bodyFat`, measurements, and `notes`.
  /// Returns: `Future<Response>`.
  /// Side effects: Writes weight storage.
  /// Notes: Non-positive optional numeric fields are rejected when present.
  static Future<Response> _handleWeightAdd(Request request) async {
    final body = await _parseBody(request);
    if (body == null) return _error(400, 'invalid JSON body');
    final weight = _positiveDouble(body['weight']);
    if (weight == null) return _error(400, 'valid weight is required');
    final bodyFat = _optionalPositiveDouble(body['bodyFat']);
    final bustCm = _optionalPositiveDouble(body['bustCm']);
    final waistCm = _optionalPositiveDouble(body['waistCm']);
    final hipCm = _optionalPositiveDouble(body['hipCm']);
    if (body['bodyFat'] != null && bodyFat == null) {
      return _error(400, 'valid bodyFat is required');
    }
    if (body['bustCm'] != null && bustCm == null) {
      return _error(400, 'valid bustCm is required');
    }
    if (body['waistCm'] != null && waistCm == null) {
      return _error(400, 'valid waistCm is required');
    }
    if (body['hipCm'] != null && hipCm == null) {
      return _error(400, 'valid hipCm is required');
    }
    final date = _optionalBodyDate(body, 'date');
    if (body['date'] != null && date == null) {
      return _error(400, 'invalid date');
    }

    final record = WeightRecord(
      weight: weight,
      bodyFat: bodyFat,
      bustCm: bustCm,
      waistCm: waistCm,
      hipCm: hipCm,
      datetime: date,
      notes: _optionalTrimmedString(body['notes']),
    );
    final data = await WeightStorage.load() ?? WeightData(records: []);
    final next = WeightData(
      height: data.height,
      records: [...data.records, record],
      reminderMode: data.reminderMode,
      morningHour: data.morningHour,
      morningMinute: data.morningMinute,
      eveningHour: data.eveningHour,
      eveningMinute: data.eveningMinute,
      reminderGraceMinutes: data.reminderGraceMinutes,
      settingsModifiedAt: data.settingsModifiedAt,
    );
    await WeightStorage.save(next);
    return _json({
      'success': true,
      'id': record.id,
      'record': _weightRecordJson(record, next),
    });
  }

  /// Purpose: Return weight statistics and latest measurement details.
  /// Inputs: `request`.
  /// Returns: `Future<Response>`.
  /// Side effects: Reads weight storage.
  /// Notes: Historical keys `latest`, `avg_7d`, `avg_30d`, and `trend` are preserved.
  static Future<Response> _handleWeightStats(Request request) async {
    final data = await WeightStorage.load();
    if (data == null || data.records.isEmpty) {
      return _json({
        'latest': null,
        'avg_7d': null,
        'avg_30d': null,
        'trend': 'unknown',
        'height': data?.height,
        'bmi': null,
        'waistHipRatio': null,
        'bodyFat': null,
        'latestRecord': null,
        'effectiveMeasurements': null,
      });
    }
    final sorted = data.records.toList()
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    final latestRecord = sorted.first;
    final latest = latestRecord.weight;
    final now = DateTime.now();
    final r7 = sorted
        .where((r) => now.difference(r.datetime).inDays <= 7)
        .map((r) => r.weight)
        .toList();
    final r30 = sorted
        .where((r) => now.difference(r.datetime).inDays <= 30)
        .map((r) => r.weight)
        .toList();
    final avg7 = r7.isNotEmpty ? r7.reduce((a, b) => a + b) / r7.length : null;
    final avg30 = r30.isNotEmpty
        ? r30.reduce((a, b) => a + b) / r30.length
        : null;

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

    final effective = WeightData.effectiveMeasurementsUpTo(
      data.records,
      latestRecord.datetime,
    );
    return _json({
      'latest': _round(latest, digits: 1),
      'avg_7d': avg7 != null ? _round(avg7, digits: 1) : null,
      'avg_30d': avg30 != null ? _round(avg30, digits: 1) : null,
      'trend': trend,
      'height': data.height,
      'bmi': _nullableRound(WeightData.calculateBMI(data.height, latest)),
      'waistHipRatio': _nullableRound(
        WeightData.calculateWaistHipRatio(effective.waistCm, effective.hipCm),
        digits: 3,
      ),
      'bodyFat': latestRecord.bodyFat,
      'latestRecord': _weightRecordJson(latestRecord, data),
      'effectiveMeasurements': _measurementsJson(effective),
    });
  }

  // Shared serialization helpers

  /// Purpose: Return todo tasks visible on a date.
  /// Inputs: `data`, `date`, optional `typeStr`.
  /// Returns: A list of task JSON maps.
  /// Side effects: None.
  /// Notes: Matches the existing carry-forward behavior for incomplete one-time tasks.
  static List<Map<String, dynamic>> _visibleTodoTasks(
    TodoData data,
    DateTime date, {
    String? typeStr,
  }) {
    final dateKey = DailyCompletionLog.dateKey(date);
    final todayKey = DailyCompletionLog.dateKey(DateTime.now());
    final results = <Map<String, dynamic>>[];

    for (final task in data.dailyTemplates) {
      if (typeStr != null && task.type.name != typeStr) continue;
      if (task.type != TaskType.daily) continue;
      final start = task.startDate ?? task.createdDate;
      if (dateKey.compareTo(DailyCompletionLog.dateKey(start)) < 0) continue;
      if (task.deletedDate != null &&
          dateKey.compareTo(DailyCompletionLog.dateKey(task.deletedDate!)) >=
              0) {
        continue;
      }
      results.add(
        _todoTaskJson(
          task,
          date: date,
          isCompleted: data.dailyLog.isCompleted(date, task.id),
          dailyLog: data.dailyLog,
        ),
      );
    }

    for (final task in data.oneTimeTasks) {
      if (typeStr != null && task.type.name != typeStr) continue;
      if (task.type == TaskType.daily) continue;
      final scheduled = task.scheduledDate;
      if (scheduled != null) {
        final scheduledKey = DailyCompletionLog.dateKey(scheduled);
        if (dateKey.compareTo(scheduledKey) < 0) continue;
        if (task.isCompleted && dateKey != scheduledKey) continue;
        if (!task.isCompleted && dateKey.compareTo(todayKey) > 0) continue;
      }
      results.add(_todoTaskJson(task, isCompleted: task.isCompleted));
    }

    return results;
  }

  /// Purpose: Serialize a todo task for API output.
  /// Inputs: `task`, optional date-scoped completion data.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Daily subtask completion is read from `dailyLog` for the requested date.
  static Map<String, dynamic> _todoTaskJson(
    Task task, {
    DateTime? date,
    bool? isCompleted,
    DailyCompletionLog? dailyLog,
  }) {
    return {
      'id': task.id,
      'title': task.title,
      'note': task.note,
      'emoji': task.emoji,
      'type': task.type.name,
      'isCompleted': isCompleted ?? task.isCompleted,
      'reminderTime': task.reminderTime?.toIso8601String(),
      'subtasks': task.subtasks
          .map(
            (subtask) => {
              'id': subtask.id,
              'title': subtask.title,
              'isCompleted': date != null && dailyLog != null
                  ? dailyLog.isSubtaskCompleted(date, subtask.id)
                  : subtask.isCompleted,
              'modifiedAt': subtask.modifiedAt.toIso8601String(),
            },
          )
          .toList(),
      'createdDate': task.createdDate.toIso8601String(),
      'completedDate': task.completedDate?.toIso8601String(),
      'scheduledDate': task.scheduledDate?.toIso8601String(),
      'deletedDate': task.deletedDate?.toIso8601String(),
      'startDate': task.startDate?.toIso8601String(),
      'dueDate': task.dueDate?.toIso8601String(),
      'recurrence': task.recurrence?.toJson(),
      'modifiedAt': task.modifiedAt.toIso8601String(),
    };
  }

  /// Purpose: Serialize an account without secret card fields.
  /// Inputs: `account`, optional balance values.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: `securityCode`, card number, and expiry date are not exposed.
  static Map<String, dynamic> _accountJson(
    Account account, {
    double? balance,
    double? convertedBalance,
    required String defaultCurrency,
  }) {
    return {
      'id': account.id,
      'type': account.type.name,
      'bankOrApp': account.bankOrApp,
      'name': account.name,
      'currency': account.currency,
      'emoji': account.emoji,
      'imagePath': account.imagePath,
      'feeWaiverMinimumBalance': account.feeWaiverMinimumBalance,
      'feeWaiverMonthlyDeposit': account.feeWaiverMonthlyDeposit,
      if (balance != null) 'balance': _round(balance),
      if (convertedBalance != null)
        'convertedBalance': _round(convertedBalance),
      'defaultCurrency': defaultCurrency,
      'modifiedAt': account.modifiedAt.toIso8601String(),
    };
  }

  /// Purpose: Serialize a finance category.
  /// Inputs: `category`.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Icon metadata is included so callers can render known categories.
  static Map<String, dynamic> _categoryJson(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'emoji': category.emoji,
      'type': category.type.name,
      'icon': category.icon.toJson(),
      'modifiedAt': category.modifiedAt.toIso8601String(),
    };
  }

  /// Purpose: Serialize a transaction with related display names.
  /// Inputs: `tx`, optional account/category lookup maps.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Names are null when a referenced record is missing.
  static Map<String, dynamic> _transactionJson(
    Transaction tx, {
    Map<String, Account> accountsById = const {},
    Map<String, Category> categoriesById = const {},
  }) {
    return {
      'id': tx.id,
      'type': tx.type.name,
      'amount': tx.amount,
      'currency': tx.currency,
      'rateSnapshotId': tx.rateSnapshotId,
      'accountId': tx.accountId,
      'accountName': accountsById[tx.accountId]?.name,
      'toAccountId': tx.toAccountId,
      'toAccountName': tx.toAccountId != null
          ? accountsById[tx.toAccountId]?.name
          : null,
      'toAmount': tx.toAmount,
      'toCurrency': tx.toCurrency,
      'categoryId': tx.categoryId,
      'categoryName': tx.categoryId != null
          ? categoriesById[tx.categoryId]?.name
          : null,
      'subscriptionId': tx.subscriptionId,
      'note': tx.note,
      'date': tx.date.toIso8601String(),
      'modifiedAt': tx.modifiedAt.toIso8601String(),
    };
  }

  /// Purpose: Serialize a weight record with display-effective measurements.
  /// Inputs: `record`, `data`.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Effective measurements are computed without writing inherited values back.
  static Map<String, dynamic> _weightRecordJson(
    WeightRecord record,
    WeightData data,
  ) {
    final effective = WeightData.effectiveMeasurementsUpTo(
      data.records,
      record.datetime,
    );
    return {
      'id': record.id,
      'weight': record.weight,
      'bodyFat': record.bodyFat,
      'bustCm': record.bustCm,
      'waistCm': record.waistCm,
      'hipCm': record.hipCm,
      'effectiveMeasurements': _measurementsJson(effective),
      'date': DateFormat('yyyy-MM-dd').format(record.datetime),
      'datetime': record.datetime.toIso8601String(),
      'notes': record.notes,
      'modifiedAt': record.modifiedAt.toIso8601String(),
    };
  }

  /// Purpose: Serialize effective body measurements.
  /// Inputs: `measurements`.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Null fields mean no positive value exists up to that date.
  static Map<String, dynamic> _measurementsJson(
    EffectiveWeightMeasurements measurements,
  ) {
    return {
      'bustCm': measurements.bustCm,
      'waistCm': measurements.waistCm,
      'hipCm': measurements.hipCm,
    };
  }

  // Parsing and data helpers

  /// Purpose: Clone todo data while replacing selected lists.
  /// Inputs: Existing `data` and optional replacement collections.
  /// Returns: `TodoData`.
  /// Side effects: None.
  /// Notes: Preserves all reminder and sort settings.
  static TodoData _todoDataWith(
    TodoData data, {
    List<Task>? dailyTemplates,
    List<Task>? oneTimeTasks,
  }) {
    return TodoData(
      dailyTemplates: dailyTemplates ?? data.dailyTemplates,
      oneTimeTasks: oneTimeTasks ?? data.oneTimeTasks,
      dailyLog: data.dailyLog,
      dailyScores: data.dailyScores,
      morningReminderHour: data.morningReminderHour,
      morningReminderMinute: data.morningReminderMinute,
      completionReminderHour: data.completionReminderHour,
      completionReminderMinute: data.completionReminderMinute,
      taskSortModes: data.taskSortModes,
      taskCustomOrders: data.taskCustomOrders,
      settingsModifiedAt: data.settingsModifiedAt,
    );
  }

  /// Purpose: Copy a one-time task while allowing completedDate to clear.
  /// Inputs: `task`, optional completion and subtask fields.
  /// Returns: `Task`.
  /// Side effects: None.
  /// Notes: Used because `Task.copyWith` intentionally lacks a completed-date clear flag.
  static Task _copyOneTimeTask(
    Task task, {
    bool? isCompleted,
    DateTime? completedDate,
    List<SubTask>? subtasks,
  }) {
    return Task(
      id: task.id,
      title: task.title,
      note: task.note,
      emoji: task.emoji,
      type: task.type,
      isCompleted: isCompleted ?? task.isCompleted,
      reminderTime: task.reminderTime,
      subtasks: subtasks ?? task.subtasks,
      createdDate: task.createdDate,
      completedDate: completedDate,
      scheduledDate: task.scheduledDate,
      deletedDate: task.deletedDate,
      startDate: task.startDate,
      dueDate: task.dueDate,
      recurrence: task.recurrence,
      modifiedAt: DateTime.now(),
    );
  }

  /// Purpose: Add a converted category amount into a total map.
  /// Inputs: `totals`, `tx`, `converted`.
  /// Returns: None.
  /// Side effects: Mutates `totals`.
  /// Notes: Empty category ids represent uncategorized flows.
  static void _addCategoryTotal(
    Map<String, _CategoryTotal> totals,
    Transaction tx,
    double converted,
  ) {
    final key = '${tx.type.name}:${tx.categoryId ?? ''}';
    final existing = totals[key];
    if (existing == null) {
      totals[key] = _CategoryTotal(
        categoryId: tx.categoryId ?? '',
        type: tx.type,
        amount: converted,
        count: 1,
      );
    } else {
      totals[key] = existing.add(converted);
    }
  }

  /// Purpose: Parse a yyyy-MM query month.
  /// Inputs: `request`.
  /// Returns: `DateTime?`.
  /// Side effects: None.
  /// Notes: Invalid or absent values return null so callers can choose defaults.
  static DateTime? _queryMonth(Request request) {
    final monthStr = request.url.queryParameters['month'];
    if (monthStr == null || monthStr.isEmpty) return null;
    final parts = monthStr.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month);
  }

  /// Purpose: Parse an integer query parameter.
  /// Inputs: `request`, `name`, `defaultValue`.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: Invalid values return the default.
  static int _queryInt(
    Request request,
    String name, {
    required int defaultValue,
  }) {
    return int.tryParse(request.url.queryParameters[name] ?? '') ??
        defaultValue;
  }

  /// Purpose: Parse a boolean query parameter.
  /// Inputs: `request`, `name`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Accepts `true`, `1`, and `yes`.
  static bool _queryBool(Request request, String name) {
    final value = request.url.queryParameters[name]?.toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Purpose: Parse a date query parameter.
  /// Inputs: `request`, `name`.
  /// Returns: `DateTime?`.
  /// Side effects: None.
  /// Notes: Uses Dart's ISO-compatible `DateTime.tryParse`.
  static DateTime? _queryDate(Request request, String name) {
    final value = request.url.queryParameters[name];
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Purpose: Parse a date field from a JSON body.
  /// Inputs: `body`, `name`.
  /// Returns: `DateTime?`.
  /// Side effects: None.
  /// Notes: Non-string values are treated as invalid and return null.
  static DateTime? _optionalBodyDate(Map<String, dynamic> body, String name) {
    final value = body[name];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  /// Purpose: Parse a required positive numeric field.
  /// Inputs: `value`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Non-positive and non-numeric values return null.
  static double? _positiveDouble(Object? value) {
    final parsed = switch (value) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text.trim()),
      _ => null,
    };
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// Purpose: Parse an optional positive numeric API field.
  /// Inputs: `value`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Non-positive and non-numeric values are treated as absent.
  static double? _optionalPositiveDouble(Object? value) {
    if (value == null) return null;
    return _positiveDouble(value);
  }

  /// Purpose: Parse an optional string and trim whitespace.
  /// Inputs: `value`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Empty strings become null.
  static String? _optionalTrimmedString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Purpose: Parse subtasks from JSON input.
  /// Inputs: `value`.
  /// Returns: `List<SubTask>`.
  /// Side effects: None.
  /// Notes: Accepts strings or maps with `title` and optional `isCompleted`.
  static List<SubTask> _parseSubtasks(Object? value) {
    if (value is! List) return const [];
    final subtasks = <SubTask>[];
    for (final item in value) {
      String? title;
      bool isCompleted = false;
      if (item is String) {
        title = item.trim();
      } else if (item is Map) {
        title = (item['title'] as String?)?.trim();
        isCompleted = item['isCompleted'] as bool? ?? false;
      }
      if (title != null && title.isNotEmpty) {
        subtasks.add(SubTask(title: title, isCompleted: isCompleted));
      }
    }
    return subtasks;
  }

  /// Purpose: Parse a task recurrence from JSON input.
  /// Inputs: `value`.
  /// Returns: `TaskRecurrence?`.
  /// Side effects: None.
  /// Notes: Invalid recurrence objects return null.
  static TaskRecurrence? _parseRecurrence(Object? value) {
    if (value == null) return null;
    if (value is! Map) return null;
    final json = value.map(
      (key, childValue) => MapEntry(key.toString(), childValue),
    );
    final type = json['type'] as String?;
    if (type == null) return null;
    switch (type) {
      case 'everyNDays':
        final days = json['intervalDays'];
        if (days is! num || days <= 0) return null;
        return TaskRecurrence.everyNDays(days.round());
      case 'monthlyOnDay':
        final day = json['dayOfMonth'];
        if (day is! num || day <= 0) return null;
        return TaskRecurrence.monthlyOnDay(day.round());
      case 'yearlyOnMonthDay':
        final month = json['monthOfYear'];
        final day = json['dayOfMonth'];
        if (month is! num || month <= 0 || day is! num || day <= 0) return null;
        return TaskRecurrence.yearlyOnMonthDay(month.round(), day.round());
    }
    return null;
  }

  /// Purpose: Return a task type by API name.
  /// Inputs: `name`.
  /// Returns: `TaskType?`.
  /// Side effects: None.
  /// Notes: Unknown names return null.
  static TaskType? _taskTypeByName(String? name) {
    if (name == null) return null;
    for (final value in TaskType.values) {
      if (value.name == name) return value;
    }
    return null;
  }

  /// Purpose: Return a transaction type by API name.
  /// Inputs: `name`.
  /// Returns: `TransactionType?`.
  /// Side effects: None.
  /// Notes: Unknown names return null.
  static TransactionType? _transactionTypeByName(String? name) {
    if (name == null) return null;
    for (final value in TransactionType.values) {
      if (value.name == name) return value;
    }
    return null;
  }

  /// Purpose: Return an account type by API name.
  /// Inputs: `name`.
  /// Returns: `AccountType?`.
  /// Side effects: None.
  /// Notes: Unknown names return null.
  static AccountType? _accountTypeByName(String name) {
    for (final value in AccountType.values) {
      if (value.name == name) return value;
    }
    return null;
  }

  /// Purpose: Round a double for stable JSON output.
  /// Inputs: `value`, `digits`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Uses decimal string formatting to avoid noisy binary fractions.
  static double _round(double value, {int digits = 2}) {
    return double.parse(value.toStringAsFixed(digits));
  }

  /// Purpose: Round a nullable double for JSON output.
  /// Inputs: `value`, `digits`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Null input remains null.
  static double? _nullableRound(double? value, {int digits = 2}) {
    return value == null ? null : _round(value, digits: digits);
  }

  /// Purpose: Encode successful JSON responses.
  /// Inputs: `data`.
  /// Returns: `Response`.
  /// Side effects: None.
  /// Notes: All API responses use `application/json`.
  static Response _json(Object? data) => Response.ok(
    jsonEncode(data),
    headers: {'Content-Type': 'application/json'},
  );

  /// Purpose: Encode JSON error responses.
  /// Inputs: `status`, `message`.
  /// Returns: `Response`.
  /// Side effects: None.
  /// Notes: Error bodies always use an `error` string key.
  static Response _error(int status, String message) => Response(
    status,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'},
  );

  /// Purpose: Parse a JSON request body.
  /// Inputs: `request`.
  /// Returns: `Future<Map<String, dynamic>?>`.
  /// Side effects: Reads the request body stream.
  /// Notes: Empty or malformed bodies return null.
  static Future<Map<String, dynamic>?> _parseBody(Request request) async {
    try {
      final raw = await request.readAsString();
      if (raw.trim().isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Middleware

  /// Purpose: Add permissive CORS headers for local tooling.
  /// Inputs: None.
  /// Returns: `Middleware`.
  /// Side effects: None.
  /// Notes: OPTIONS requests are answered before auth checks.
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

  /// Purpose: Enforce local API authentication policy.
  /// Inputs: None.
  /// Returns: `Middleware`.
  /// Side effects: None.
  /// Notes: Configured credentials are required for every non-OPTIONS request, including localhost.
  static Middleware _authMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final remoteAddr =
            (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
                ?.remoteAddress;
        final isLoopback = remoteAddr == null || remoteAddr.isLoopback;
        if (_hasCredentials) {
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
        } else if (!isLoopback) {
          return _error(
            403,
            'authentication required for non-localhost access',
          );
        }
        return innerHandler(request);
      };
    };
  }

  /// Purpose: Return whether both API credential fields are configured.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Empty strings are treated as absent credentials.
  static bool get _hasCredentials =>
      _username != null &&
      _username!.isNotEmpty &&
      _password != null &&
      _password!.isNotEmpty;

  /// Purpose: Validate an HTTP Basic Auth header.
  /// Inputs: `header`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Passwords may contain colons.
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

  /// Purpose: Convert uncaught route exceptions into JSON errors.
  /// Inputs: None.
  /// Returns: `Middleware`.
  /// Side effects: None.
  /// Notes: Keeps the local API from returning plain-text stack traces.
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

class _CategoryTotal {
  final String categoryId;
  final TransactionType type;
  final double amount;
  final int count;

  /// Purpose: Store an accumulated finance category total.
  /// Inputs: `categoryId`, `type`, `amount`, and `count`.
  /// Returns: A new `_CategoryTotal` instance.
  /// Side effects: None.
  /// Notes: Internal helper for local API summaries.
  const _CategoryTotal({
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.count,
  });

  /// Purpose: Add an amount to this total.
  /// Inputs: `value`.
  /// Returns: `_CategoryTotal`.
  /// Side effects: None.
  /// Notes: Preserves category id and transaction type.
  _CategoryTotal add(double value) {
    return _CategoryTotal(
      categoryId: categoryId,
      type: type,
      amount: amount + value,
      count: count + 1,
    );
  }
}
