import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shelf/shelf.dart';

import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/exchange_rate_storage.dart';
import 'package:my_day/features/finance/services/finance_storage.dart';
import 'package:my_day/features/weight/models/weight_record.dart';
import 'package:my_day/features/weight/services/weight_storage.dart';
import 'package:my_day/shared/services/local_api_server.dart';

/// Purpose: Exercise the MyDay local HTTP API contract.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: Path provider is faked so storage stays inside the test sandbox.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Handler handler;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('my_day_local_api_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    handler = LocalApiServer.buildHandlerForTesting();
  });

  tearDown(() async {
    await LocalApiServer.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('requires Basic Auth whenever credentials are configured', () async {
    handler = LocalApiServer.buildHandlerForTesting(
      username: 'api',
      password: 'secret',
    );

    final denied = await handler(_request('GET', '/ping'));
    expect(denied.statusCode, 401);

    final allowed = await handler(
      _request(
        'GET',
        '/ping',
        headers: {'authorization': _basicAuth('api', 'secret')},
      ),
    );
    expect(allowed.statusCode, 200);
    expect(await _decodeObject(allowed), {'status': 'ok'});
  });

  test('adds, scores, lists, and completes enriched todo records', () async {
    final addResponse = await handler(
      _jsonRequest('POST', '/todo/add', {
        'title': 'Plan API refresh',
        'type': 'daily',
        'note': 'Cover new fields',
        'scheduledDate': '2026-06-10',
        'reminderTime': '2026-06-12T09:00:00',
        'subtasks': [
          {'title': 'Write tests'},
        ],
      }),
    );
    final added = await _decodeObject(addResponse);
    final taskId = added['id'] as String;
    final subtaskId =
        ((added['task'] as Map<String, dynamic>)['subtasks'] as List)
                .single['id']
            as String;

    await handler(
      _jsonRequest('POST', '/todo/score', {'date': '2026-06-12', 'score': 9}),
    );
    await handler(
      _jsonRequest('POST', '/todo/complete', {
        'id': taskId,
        'subtaskId': subtaskId,
        'date': '2026-06-12',
        'completed': true,
      }),
    );

    final day = await _decodeObject(
      await handler(_request('GET', '/todo/day?date=2026-06-12')),
    );
    final tasks = day['tasks'] as List;
    final task = tasks.single as Map<String, dynamic>;
    final subtask = (task['subtasks'] as List).single as Map<String, dynamic>;

    expect(day['score'], 5);
    expect(day['total'], 1);
    expect(task['note'], 'Cover new fields');
    expect(task['reminderTime'], '2026-06-12T09:00:00.000');
    expect(subtask['isCompleted'], isTrue);
    expect(subtask['modifiedAt'], isNotEmpty);
  });

  test('summarizes converted finance data and stores rate snapshots', () async {
    final account = Account(
      id: 'usd-card',
      type: AccountType.credit,
      bankOrApp: 'Bank',
      name: 'USD Card',
      currency: 'USD',
      securityCode: '123',
    );
    final category = Category(
      id: 'food',
      name: 'Food',
      icon: const IconRef(codePoint: 0xe57c),
      type: TransactionType.expense,
    );
    await FinanceStorage.save(
      FinanceData(
        accounts: [account],
        categories: [category],
        transactions: [],
        defaultCurrency: 'CNY',
      ),
    );
    await ExchangeRateStorage.save(
      ExchangeRateData(
        currentSnapshotId: 'snapshot-1',
        snapshots: {
          'snapshot-1': RateSnapshot(
            id: 'snapshot-1',
            rates: {'USD_CNY': 7},
            createdAt: DateTime(2026, 6, 1),
          ),
        },
      ),
    );

    final add = await _decodeObject(
      await handler(
        _jsonRequest('POST', '/finance/add_transaction', {
          'type': 'expense',
          'amount': 2,
          'currency': 'USD',
          'accountId': account.id,
          'categoryId': category.id,
          'note': 'Coffee',
          'date': '2026-06-12T08:00:00',
        }),
      ),
    );
    final tx = add['transaction'] as Map<String, dynamic>;
    expect(tx['rateSnapshotId'], 'snapshot-1');

    final summary = await _decodeObject(
      await handler(_request('GET', '/finance/summary?month=2026-06')),
    );
    final accounts = summary['accounts'] as List;
    final categories = summary['top_expense_categories'] as List;

    expect(summary['defaultCurrency'], 'CNY');
    expect(summary['expense'], 14.0);
    expect(summary['total_assets'], -14.0);
    expect(accounts.single, isNot(containsPair('securityCode', '123')));
    expect(categories.single['name'], 'Food');
    expect(categories.single['amount'], 14.0);
  });

  test(
    'adds and returns weight composition and effective measurements',
    () async {
      await WeightStorage.save(
        WeightData(
          height: 170,
          records: [
            WeightRecord(
              id: 'baseline',
              weight: 66,
              bustCm: 88,
              waistCm: 70,
              hipCm: 92,
              datetime: DateTime(2026, 6, 1, 8),
            ),
          ],
        ),
      );

      final add = await _decodeObject(
        await handler(
          _jsonRequest('POST', '/weight/add', {
            'weight': 65,
            'bodyFat': 21.5,
            'waistCm': 69,
            'notes': 'Morning',
            'date': '2026-06-02T08:00:00',
          }),
        ),
      );
      expect(add['success'], isTrue);

      final list = await _decodeList(
        await handler(_request('GET', '/weight/list?limit=1')),
      );
      final record = list.single as Map<String, dynamic>;
      final effective = record['effectiveMeasurements'] as Map<String, dynamic>;

      expect(record['bodyFat'], 21.5);
      expect(record['notes'], 'Morning');
      expect(effective['bustCm'], 88.0);
      expect(effective['waistCm'], 69.0);
      expect(effective['hipCm'], 92.0);

      final stats = await _decodeObject(
        await handler(_request('GET', '/weight/stats')),
      );
      expect(stats['latest'], 65.0);
      expect(stats['bmi'], closeTo(22.49, 0.01));
      expect(stats['waistHipRatio'], closeTo(0.75, 0.001));
      expect(stats['bodyFat'], 21.5);
    },
  );
}

/// Purpose: Build a plain Shelf request.
/// Inputs: HTTP `method`, local `path`, and optional `headers`.
/// Returns: `Request`.
/// Side effects: None.
/// Notes: Paths are resolved against a dummy localhost URI.
Request _request(String method, String path, {Map<String, String>? headers}) {
  return Request(method, Uri.parse('http://localhost$path'), headers: headers);
}

/// Purpose: Build a JSON Shelf request.
/// Inputs: HTTP `method`, local `path`, and JSON-compatible `body`.
/// Returns: `Request`.
/// Side effects: None.
/// Notes: The request body is encoded as UTF-8 JSON.
Request _jsonRequest(String method, String path, Object body) {
  return _request(
    method,
    path,
    headers: {'content-type': 'application/json'},
  ).change(body: jsonEncode(body));
}

/// Purpose: Decode a response body as a JSON object.
/// Inputs: `response`.
/// Returns: `Future<Map<String, dynamic>>`.
/// Side effects: Reads the response body stream.
/// Notes: Test helper for object responses.
Future<Map<String, dynamic>> _decodeObject(Response response) async {
  expect(response.statusCode, 200);
  return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
}

/// Purpose: Decode a response body as a JSON list.
/// Inputs: `response`.
/// Returns: `Future<List<dynamic>>`.
/// Side effects: Reads the response body stream.
/// Notes: Test helper for list responses.
Future<List<dynamic>> _decodeList(Response response) async {
  expect(response.statusCode, 200);
  return jsonDecode(await response.readAsString()) as List<dynamic>;
}

/// Purpose: Build an HTTP Basic Auth header.
/// Inputs: `username`, `password`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Matches LocalApiServer's Basic Auth validation.
String _basicAuth(String username, String password) {
  return 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
}

class _FakePathProvider extends PathProviderPlatform {
  final String documentsPath;

  /// Purpose: Create a fake path provider for tests.
  /// Inputs: `documentsPath`.
  /// Returns: A new `_FakePathProvider` instance.
  /// Side effects: None.
  /// Notes: Only application documents path is needed by these tests.
  _FakePathProvider(this.documentsPath);

  /// Purpose: Return the fake application documents directory.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: None.
  /// Notes: None.
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
