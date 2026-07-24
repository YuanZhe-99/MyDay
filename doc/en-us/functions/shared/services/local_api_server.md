# lib/shared/services/local_api_server.dart

Desktop-only static service (`LocalApiServer`) that runs the MyDay local HTTP API: a Shelf-based
server exposing `/ping`, `/todo/*`, `/finance/*`, and `/weight/*` endpoints over plain JSON so local
tooling (shortcuts, widgets, scripts) can read and write the same on-disk data the app itself uses.
Started from `main()` (see
[../../../architecture.md#startup-sequence](../../../architecture.md#startup-sequence)) and
controlled from the Settings page's desktop section
([../../features/settings.md](../../../features/settings.md)). Config (`apiPort`,
`apiListenAddress`, `apiEnabled`, `apiUsername`, `apiPassword`), the non-loopback
credential requirement, the permissive-CORS/Basic-Auth middleware stack, and the
`data_unreadable` 500 contract are all documented at
[../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api) — this page
covers the implementation behind that contract. The endpoint list itself is also summarized in
`AGENTS.md`'s "Local HTTP API" section and [../../../sync.md](../../../sync.md).

This file collaborates with `TodoStorage`, `FinanceStorage`, `ExchangeRateStorage`, and
`WeightStorage` for persistence (each can throw a typed `*StorageException` on unparsable data,
caught by `_errorMiddleware`), and with `balance_util.dart`'s `accountBalance`/`convertCurrency`
for finance currency conversion.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `port` | static getter (`LocalApiServer`) | B | Return the configured/bound API port. |
| `listenAddress` | static getter (`LocalApiServer`) | B | Return the configured listen address. |
| `enabled` | static getter (`LocalApiServer`) | B | Return whether the local API is enabled in config. |
| `isRunning` | static getter (`LocalApiServer`) | B | Return whether the HTTP listener is currently open. |
| `lastError` | static getter (`LocalApiServer`) | B | Return the last start failure reason, if any. |
| [`loadConfig`](#loadconfig) | static method (`LocalApiServer`) | A | Load API settings from `storage_config.json`. |
| [`start`](#start) | static method (`LocalApiServer`) | A | Start the HTTP listener when enabled and allowed. |
| [`stop`](#stop) | static method (`LocalApiServer`) | A | Close the active HTTP listener. |
| [`restart`](#restart) | static method (`LocalApiServer`) | A | Reload config and restart the listener. |
| [`buildHandlerForTesting`](#buildhandlerfortesting) | static method (`LocalApiServer`) | A | Build the route handler with injected test credentials. |
| [`_buildHandler`](#_buildhandler) | static method (`LocalApiServer`) | A | Wire the route table and middleware pipeline. |
| [`_bindAddress`](#_bindaddress) | static method (`LocalApiServer`) | A | Resolve the configured listen address to an `InternetAddress`. |
| [`_handlePing`](#_handleping) | static method (`LocalApiServer`) | A | Handle `GET /ping`. |
| [`_handleTodoList`](#_handletodolist) | static method (`LocalApiServer`) | A | Handle `GET /todo/list`. |
| [`_handleTodoDay`](#_handletododay) | static method (`LocalApiServer`) | A | Handle `GET /todo/day`. |
| [`_handleTodoAdd`](#_handletodoadd) | static method (`LocalApiServer`) | A | Handle `POST /todo/add`. |
| [`_handleTodoComplete`](#_handletodocomplete) | static method (`LocalApiServer`) | A | Handle `POST /todo/complete`. |
| [`_handleTodoScore`](#_handletodoscore) | static method (`LocalApiServer`) | A | Handle `POST /todo/score`. |
| [`_handleTodoStats`](#_handletodostats) | static method (`LocalApiServer`) | A | Handle `GET /todo/stats`. |
| [`_handleFinanceSummary`](#_handlefinancesummary) | static method (`LocalApiServer`) | A | Handle `GET /finance/summary`. |
| [`_handleFinanceAccounts`](#_handlefinanceaccounts) | static method (`LocalApiServer`) | A | Handle `GET /finance/accounts`. |
| [`_handleFinanceCategories`](#_handlefinancecategories) | static method (`LocalApiServer`) | A | Handle `GET /finance/categories`. |
| [`_handleFinanceTransactions`](#_handlefinancetransactions) | static method (`LocalApiServer`) | A | Handle `GET /finance/transactions`. |
| [`_handleFinanceAddTransaction`](#_handlefinanceaddtransaction) | static method (`LocalApiServer`) | A | Handle `POST /finance/add_transaction`. |
| [`_handleFinanceSubscriptions`](#_handlefinancesubscriptions) | static method (`LocalApiServer`) | A | Handle `GET /finance/subscriptions`. |
| [`_handleWeightList`](#_handleweightlist) | static method (`LocalApiServer`) | A | Handle `GET /weight/list`. |
| [`_handleWeightAdd`](#_handleweightadd) | static method (`LocalApiServer`) | A | Handle `POST /weight/add`. |
| [`_handleWeightStats`](#_handleweightstats) | static method (`LocalApiServer`) | A | Handle `GET /weight/stats`. |
| [`_visibleTodoTasks`](#_visibletodotasks) | static method (`LocalApiServer`) | A | Compute which todo tasks are visible on a given date. |
| [`_todoTaskJson`](#_todotaskjson) | static method (`LocalApiServer`) | A | Serialize a `Task` to API JSON. |
| [`_accountJson`](#_accountjson) | static method (`LocalApiServer`) | A | Serialize an `Account` to API JSON without secret fields. |
| [`_categoryJson`](#_categoryjson) | static method (`LocalApiServer`) | A | Serialize a `Category` to API JSON. |
| [`_transactionJson`](#_transactionjson) | static method (`LocalApiServer`) | A | Serialize a `Transaction` to API JSON. |
| [`_weightRecordJson`](#_weightrecordjson) | static method (`LocalApiServer`) | A | Serialize a `WeightRecord` to API JSON. |
| [`_measurementsJson`](#_measurementsjson) | static method (`LocalApiServer`) | A | Serialize effective body measurements to JSON. |
| [`_todoDataWith`](#_tododatawith) | static method (`LocalApiServer`) | A | Copy `TodoData` while replacing selected task lists. |
| [`_copyOneTimeTask`](#_copyonetimetask) | static method (`LocalApiServer`) | A | Copy a one-time `Task`, allowing `completedDate` to clear. |
| [`_addCategoryTotal`](#_addcategorytotal) | static method (`LocalApiServer`) | A | Accumulate a converted amount into a category-total map. |
| [`_queryMonth`](#_querymonth) | static method (`LocalApiServer`) | A | Parse a `yyyy-MM` query parameter. |
| [`_queryInt`](#_queryint) | static method (`LocalApiServer`) | A | Parse an integer query parameter with a default. |
| [`_queryBool`](#_querybool) | static method (`LocalApiServer`) | A | Parse a boolean query parameter. |
| [`_queryDate`](#_querydate) | static method (`LocalApiServer`) | A | Parse a date query parameter. |
| [`_optionalBodyDate`](#_optionalbodydate) | static method (`LocalApiServer`) | A | Parse an optional date field from a JSON body. |
| [`_positiveDouble`](#_positivedouble) | static method (`LocalApiServer`) | A | Parse a required positive numeric value. |
| [`_optionalPositiveDouble`](#_optionalpositivedouble) | static method (`LocalApiServer`) | A | Parse an optional positive numeric value. |
| [`_optionalTrimmedString`](#_optionaltrimmedstring) | static method (`LocalApiServer`) | A | Parse and trim an optional string. |
| [`_parseSubtasks`](#_parsesubtasks) | static method (`LocalApiServer`) | A | Parse subtasks from JSON input. |
| [`_parseRecurrence`](#_parserecurrence) | static method (`LocalApiServer`) | A | Parse a `TaskRecurrence` from JSON input. |
| [`_taskTypeByName`](#_tasktypebyname) | static method (`LocalApiServer`) | A | Resolve a `TaskType` by API name. |
| [`_transactionTypeByName`](#_transactiontypebyname) | static method (`LocalApiServer`) | A | Resolve a `TransactionType` by API name. |
| [`_accountTypeByName`](#_accounttypebyname) | static method (`LocalApiServer`) | A | Resolve an `AccountType` by API name. |
| [`_round`](#_round) | static method (`LocalApiServer`) | A | Round a double for stable JSON output. |
| [`_nullableRound`](#_nullableround) | static method (`LocalApiServer`) | A | Round a nullable double for JSON output. |
| [`_json`](#_json) | static method (`LocalApiServer`) | A | Encode a successful JSON response. |
| [`_error`](#_error) | static method (`LocalApiServer`) | A | Encode a JSON error response. |
| [`_parseBody`](#_parsebody) | static method (`LocalApiServer`) | A | Parse the request body as JSON. |
| [`_corsMiddleware`](#_corsmiddleware) | static method (`LocalApiServer`) | A | Add permissive CORS headers and answer `OPTIONS`. |
| [`_authMiddleware`](#_authmiddleware) | static method (`LocalApiServer`) | A | Enforce Basic Auth / loopback-only policy. |
| [`_hasCredentials`](#_hascredentials) | static getter (`LocalApiServer`) | A | Return whether both API credential fields are configured. |
| [`_validateBasicAuth`](#_validatebasicauth) | static method (`LocalApiServer`) | A | Validate a `Basic` Authorization header. |
| [`_errorMiddleware`](#_errormiddleware) | static method (`LocalApiServer`) | A | Convert uncaught storage exceptions into JSON 500s. |
| [`_CategoryTotal.new`](#_categorytotal-new) | constructor (`_CategoryTotal`) | A | Store an accumulated finance category total. |
| [`add`](#add) | method (`_CategoryTotal`) | A | Return a copy with `value` added to the total. |

`grep -c 'Purpose:' lib/shared/services/local_api_server.dart` reports 63, matching all 63 real
declarations found in this file (5 plain getters plus 58 methods/getters/constructors with real
branching, parsing, serialization, or IO logic). No misattached blocks and no undocumented real
declarations were found — every `/// Purpose:` block sits directly above the class member it
describes. The five one-line field-return getters (`port`, `listenAddress`, `enabled`, `isRunning`,
`lastError`) are the only Tier B rows; everything else in this service file has real logic
(validation, storage IO, JSON shaping, or middleware behavior) and is Tier A per the blanket
"services" rule. Two private static fields (`_corsHeaders`) and the seven plain private state
fields (`_server`, `_port`, `_listenAddress`, `_enabled`, `_username`, `_password`, `_lastError`)
are not separately indexed — they carry no doc comment and are not functions/getters/constructors.

## Documentation

### `static Future<void> loadConfig()` <a id="loadconfig"></a>
- **Kind:** static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 67)
- **Purpose:** Load the cached API settings (`_port`, `_listenAddress`, `_enabled`, `_username`,
  `_password`) from `storage_config.json` via `TodoStorage.readConfig()`.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Overwrites the class's static config fields.
- **Algorithm:**
  1. Read the config JSON via `TodoStorage.readConfig()`.
  2. Assign `apiPort` (default `7790`), `apiListenAddress` (default `'localhost'`), `apiEnabled`
     (default `false`), `apiUsername`, `apiPassword` from the JSON, falling back per key.
  3. Swallow any exception silently (`catch (_) {}`), leaving the previous cached values in place.
- **Usage:** Called from `start()` and `restart()` before (re)opening the listener; not normally
  called directly by application code.
- **Notes:** Failure is silent by design — a corrupt or missing config leaves the last-known-good
  values rather than crashing startup.

### `static Future<void> start()` <a id="start"></a>
- **Kind:** static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 83)
- **Purpose:** Start the local HTTP API server when it is enabled in config and allowed to bind.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Calls `loadConfig()` and `stop()`; on success opens a `shelf_io` listener and
  updates `_server`/`_port`; on failure or refusal sets `_lastError` (`'credentials_required'` or
  the caught exception's `toString()`).
- **Algorithm:**
  1. `loadConfig()`, then `stop()` (closes any previously-open listener) and clear `_lastError`.
  2. Return immediately if `_enabled` is false.
  3. Compute `isNonLoopback`: true if `_listenAddress == '0.0.0.0'`, or if it is anything other than
     `'localhost'`/`'127.0.0.1'`. If non-loopback and `_hasCredentials` is false, set
     `_lastError = 'credentials_required'` and return without binding.
  4. Otherwise call `shelf_io.serve(_buildHandler(), _bindAddress(), _port)`; on success store the
     server and the actual bound port (`_server!.port` — relevant when `_port` was `0`); on
     exception, store `_lastError` and print a diagnostic line.
- **Usage:**
  ```dart
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await LocalApiServer.start();
  }
  ```
  (`lib/main.dart`, startup sequence.)
- **Notes:** Any listen address other than `localhost`/`127.0.0.1` (including a specific LAN IP) is
  treated as non-loopback and refused unless both `apiUsername` and `apiPassword` are set — see
  [../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api). Safe to
  call repeatedly; it always stops any prior listener first.

### `static Future<void> stop()` <a id="stop"></a>
- **Kind:** static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 114)
- **Purpose:** Close the active HTTP listener, if one exists.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Force-closes `_server` and sets it to `null`.
- **Algorithm:** `await _server?.close(force: true); _server = null;`
- **Usage:**
  ```dart
  await LocalApiServer.stop();
  ```
  (`test/local_api_server_test.dart`, `tearDown`; also the Settings page when the user disables the
  API toggle.)
- **Notes:** Safe to call when no server is running (`_server` is already `null`).

### `static Future<void> restart()` <a id="restart"></a>
- **Kind:** static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 124)
- **Purpose:** Reload API config from storage and restart the listener with the new settings.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Same as `loadConfig()` + `start()` combined.
- **Algorithm:** `await loadConfig(); await start();` — note `start()` itself also calls
  `loadConfig()` first, so config is loaded twice; harmless since `loadConfig()` is idempotent.
- **Usage:**
  ```dart
  await LocalApiServer.restart();
  ```
  (`lib/features/settings/views/settings_page.dart`, after saving new port/address/credentials in
  the API settings dialog.)
- **Notes:** None.

### `static Handler buildHandlerForTesting({String? username, String? password})` <a id="buildhandlerfortesting"></a>
- **Kind:** static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 134)
- **Purpose:** Build the same request handler used in production, with directly-injected
  credentials, for use in widget/unit tests without going through `loadConfig()`.
- **Inputs:** Optional `username`/`password`.
- **Returns:** `Handler`.
- **Side effects:** Overwrites the static `_username`/`_password` fields as a side effect of
  configuring the handler.
- **Algorithm:** Assign `_username`/`_password` from the parameters, then return `_buildHandler()`.
- **Usage:**
  ```dart
  handler = LocalApiServer.buildHandlerForTesting(
    username: 'api',
    password: 'secret',
  );
  ```
  (`test/local_api_server_test.dart`, Basic Auth test case.)
- **Notes:** Does not open a real `HttpServer` — the returned `Handler` is invoked directly against
  synthetic `Request` objects in tests.

### `static Handler _buildHandler()` <a id="_buildhandler"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 145)
- **Purpose:** Build the Shelf router (all 16 routes) and wrap it in the CORS / auth / error
  middleware pipeline.
- **Inputs:** None.
- **Returns:** `Handler`.
- **Side effects:** None (pure construction).
- **Algorithm:**
  1. Create a `Router` and register `GET /ping`, the seven `/todo/*` routes, the six `/finance/*`
     routes, and the three `/weight/*` routes to their `_handleXxx` methods (see
     [../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api) for the
     full endpoint list).
  2. Wrap with `Pipeline().addMiddleware(_corsMiddleware()).addMiddleware(_authMiddleware())
     .addMiddleware(_errorMiddleware()).addHandler(router.call)` — CORS runs outermost, then auth,
     then error handling, then the router.
- **Usage:** Called from `start()` (real listener) and `buildHandlerForTesting()` (in-memory
  handler for tests) so both paths share identical routing/middleware behavior.
- **Notes:** Middleware order matters: CORS headers/`OPTIONS` short-circuit happens before auth is
  checked, so preflight requests never need credentials.

### `static InternetAddress _bindAddress()` <a id="_bindaddress"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 179)
- **Purpose:** Translate the configured `_listenAddress` string into an `InternetAddress` suitable
  for `shelf_io.serve`.
- **Inputs:** None (reads `_listenAddress`).
- **Returns:** `InternetAddress`.
- **Side effects:** None.
- **Algorithm:** `'0.0.0.0'` → `InternetAddress.anyIPv4`; `'localhost'` or `'127.0.0.1'` →
  `InternetAddress.loopbackIPv4`; anything else → `InternetAddress(_listenAddress, type: any)`
  (parsed as a literal numeric address).
- **Usage:** Called once from `start()` when opening the listener.
- **Notes:** `'localhost'` must be special-cased to `loopbackIPv4` because `InternetAddress('localhost')`
  is not a valid numeric address literal and would throw.

### `static Future<Response> _handlePing(Request request)` <a id="_handleping"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 194)
- **Purpose:** Answer `GET /ping` so callers can check the API is reachable and authenticated.
- **Inputs:** `request` (unused beyond routing).
- **Returns:** `Future<Response>`.
- **Side effects:** None.
- **Algorithm:** Return `_json({'status': 'ok'})`.
- **Usage:** Routed from `_buildHandler()`: `router.get('/ping', _handlePing);`
- **Notes:** None.

### `static Future<Response> _handleTodoList(Request request)` <a id="_handletodolist"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 205)
- **Purpose:** Implement `GET /todo/list?date=YYYY-MM-DD` — a flat array of tasks visible that day.
- **Inputs:** `request` query `date` (defaults to now) and optional `type`.
- **Returns:** `Future<Response>`.
- **Side effects:** Reads todo storage (`TodoStorage.load()`).
- **Algorithm:** Parse `date`; load todo data (empty array if none); delegate to
  `_visibleTodoTasks(data, date, typeStr: typeStr)` and wrap the result in `_json`.
- **Usage:** Routed from `_buildHandler()`: `router.get('/todo/list', _handleTodoList);`
- **Notes:** Returns a bare JSON array (not an object) for backward compatibility with existing API
  consumers.

### `static Future<Response> _handleTodoDay(Request request)` <a id="_handletododay"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 218)
- **Purpose:** Implement `GET /todo/day?date=YYYY-MM-DD` — day score, totals, and enriched tasks.
- **Inputs:** `request` query `date` (defaults to now).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads todo storage; substitutes an empty in-memory `TodoData` when none exists.
- **Algorithm:**
  1. Load data, or build an empty `TodoData` (empty lists, fresh logs) if none exists.
  2. Compute visible tasks via `_visibleTodoTasks(data, date)`; count `isCompleted == true`.
  3. Return `{date, score: data.dailyScores.scoreFor(date), total, completed, tasks}`.
- **Usage:** Routed from `_buildHandler()`: `router.get('/todo/day', _handleTodoDay);`
- **Notes:** Missing todo data yields score `0` and an empty task list rather than a 404, per
  [../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api).

### `static Future<Response> _handleTodoAdd(Request request)` <a id="_handletodoadd"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 245)
- **Purpose:** Implement `POST /todo/add` — create a daily template or one-time task.
- **Inputs:** JSON body: `title` (required), `type` (default `'workOnce'`), optional `dueDate`,
  `scheduledDate`, `reminderTime`, `note`, `emoji`, `subtasks`, `recurrence`.
- **Returns:** `Future<Response>`.
- **Side effects:** Writes todo storage (`TodoStorage.save`).
- **Algorithm:**
  1. Parse body; 400 if missing/invalid JSON, missing/empty `title`, unknown `type`, or any
     provided date/recurrence field that fails to parse.
  2. Build a `Task`; for `TaskType.daily` the parsed date becomes `startDate` (not
     `scheduledDate`), and `recurrence` is forced to `null`; for other types the parsed date
     becomes `scheduledDate` (defaulting to now) and `recurrence` is kept.
  3. Load existing data (or an empty `TodoData`); append the new task to `dailyTemplates` or
     `oneTimeTasks` via `_todoDataWith`; save.
  4. Return `{success: true, id, task: _todoTaskJson(task)}`.
- **Usage:**
  ```dart
  final res = await handler(_request('POST', '/todo/add', body: {'title': 'Test task'}));
  ```
  (`test/local_api_server_test.dart`.)
- **Notes:** Daily-template `type` intentionally cannot carry a `recurrence` — daily tasks already
  repeat every day by definition.

### `static Future<Response> _handleTodoComplete(Request request)` <a id="_handletodocomplete"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 310)
- **Purpose:** Implement `POST /todo/complete` — complete/reopen a task or one of its subtasks, and
  optionally spawn the next recurrence instance.
- **Inputs:** JSON body: `id` (required), optional `subtaskId`, `completed` (default `true`),
  `createNextRecurrence`, `date` (default now).
- **Returns:** `Future<Response>`.
- **Side effects:** Writes todo storage; toggles date-scoped daily-log entries or mutates a
  one-time task's completion fields.
- **Algorithm:**
  1. Parse body; 400 on missing/invalid JSON, missing `id`, or an invalid `date`.
  2. Load data; 404 if none.
  3. If `id` matches a **daily template**: for a `subtaskId`, 404 if unknown, else toggle
     `dailyLog.toggleSubtask(date, subtaskId)` only when the current state differs from
     `completed`; for the whole task, toggle `dailyLog.toggle(date, id)` under the same
     only-if-changed rule. Save and return `{success: true}`.
  4. Otherwise find a matching **one-time task**; 404 if not found.
  5. For a `subtaskId`: 404 if unknown, else `copyWith(isCompleted: completed)` on that subtask and
     rebuild the task via `_copyOneTimeTask(existing, subtasks: ...)`.
  6. Otherwise rebuild the task via `_copyOneTimeTask(existing, isCompleted: completed,
     completedDate: completed ? now : null)`. If this transitions incomplete → complete,
     `createNextRecurrence` is true, and the task has a `recurrence`: compute
     `nextDate = recurrence.nextDate(scheduledDate ?? date)`, build a fresh `Task` (same title/
     note/emoji/type/reminder, subtasks reset to incomplete, `dueDate` advanced by the same
     recurrence if present), append it, save both the updated and new task together, and return
     early with `{success: true, nextTaskId, nextScheduledDate}`.
  7. If no early return happened, save the updated one-time task list and return
     `{success: true}`.
- **Usage:**
  ```dart
  await handler(_request('POST', '/todo/complete', body: {'id': taskId, 'completed': true}));
  ```
  (`test/local_api_server_test.dart`, todo lifecycle test.)
- **Notes:** The recurrence branch is the most involved path in this file — it only fires on a
  true completion transition (not on re-completing an already-complete task) and only for one-time
  tasks, since daily templates repeat implicitly via the daily log instead.

### `static Future<Response> _handleTodoScore(Request request)` <a id="_handletodoscore"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 409)
- **Purpose:** Implement `POST /todo/score` — set the day score for a date.
- **Inputs:** JSON body: `score` (required numeric), optional `date` (default now).
- **Returns:** `Future<Response>`.
- **Side effects:** Writes todo storage.
- **Algorithm:** Validate `score` is numeric and `date` (if given) parses; load/create data;
  `data.dailyScores.setScore(date, scoreValue.round())`; save; return the resulting
  `{success, date, score}` (the getter re-reads via `scoreFor(date)`, which clamps to the model's
  -5..5 range).
- **Usage:**
  ```dart
  await handler(_request('POST', '/todo/score', body: {'score': 3}));
  ```
  (`test/local_api_server_test.dart`.)
- **Notes:** The response echoes `data.dailyScores.scoreFor(date)` rather than the raw input, so
  clamping is reflected in what the caller sees.

### `static Future<Response> _handleTodoStats(Request request)` <a id="_handletodostats"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 440)
- **Purpose:** Implement `GET /todo/stats` — today's total/completed/overdue counts.
- **Inputs:** `request` (unused beyond routing).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads todo storage.
- **Algorithm:**
  1. If no data, return zeros for all three counters.
  2. Compute today's visible tasks via `_visibleTodoTasks`; count completed ones.
  3. Count one-time tasks that are incomplete, have a `dueDate`, and whose due-date key sorts
     before today's key.
- **Usage:** Routed from `_buildHandler()`: `router.get('/todo/stats', _handleTodoStats);`
- **Notes:** Keeps the historical snake_case response keys (`today_total`, `today_completed`,
  `overdue`) for compatibility with existing plugins/scripts.

### `static Future<Response> _handleFinanceSummary(Request request)` <a id="_handlefinancesummary"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 472)
- **Purpose:** Implement `GET /finance/summary?month=yyyy-MM` — converted income/expense/balance,
  total assets, per-account balances, and per-category totals for a month.
- **Inputs:** `request` query `month` (defaults to the current month).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads finance and exchange-rate storage.
- **Algorithm:**
  1. If no finance data, return a zeroed summary shaped like the normal response.
  2. For every transaction inside `[monthStart, monthEnd)`, convert its amount using the exchange
     rate **snapshot in effect at transaction time** (`rateData.ratesAt(tx.rateSnapshotId)`);
     accumulate `income`/`expense` and per-category totals (via `_addCategoryTotal`) for income and
     expense transactions only — transfers are skipped.
  3. For every account, compute its balance (`accountBalance`) and convert it to the default
     currency using the **current** exchange rates (`rateData.currentRates`) — a different rate
     source than step 2, since balances are a point-in-time snapshot rather than a historical
     transaction. Sum converted balances into `total_assets`.
  4. Sort category totals descending by amount; take the top 5 expense-type entries as
     `top_expense_categories`.
- **Usage:**
  ```dart
  final res = await handler(_request('GET', '/finance/summary?month=2026-07'));
  ```
  (`test/local_api_server_test.dart`, finance summary test.)
- **Notes:** Historical transaction conversion uses the rate snapshot stored on the transaction;
  account-balance conversion always uses today's rates — mixing these up would silently misreport
  `total_assets` against `income`/`expense`.

### `static Future<Response> _handleFinanceAccounts(Request request)` <a id="_handlefinanceaccounts"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 576)
- **Purpose:** Implement `GET /finance/accounts?type=...` — account details with card secrets
  omitted.
- **Inputs:** `request` query optional `type` (an `AccountType` name).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads finance and exchange-rate storage.
- **Algorithm:** Validate `type` if given (400 on unknown); filter accounts by type; for each,
  compute balance/converted-balance and serialize via `_accountJson`.
- **Usage:** Routed from `_buildHandler()`: `router.get('/finance/accounts', _handleFinanceAccounts);`
- **Notes:** Relies on `_accountJson` to keep `securityCode`/card number/expiry out of the response.

### `static Future<Response> _handleFinanceCategories(Request request)` <a id="_handlefinancecategories"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 611)
- **Purpose:** Implement `GET /finance/categories?type=expense|income|transfer`.
- **Inputs:** `request` query optional `type` (a `TransactionType` name).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads finance storage.
- **Algorithm:** Validate `type` if given (400 on unknown); filter categories by type; map each
  through `_categoryJson`.
- **Usage:** Routed from `_buildHandler()`: `router.get('/finance/categories', _handleFinanceCategories);`
- **Notes:** Transfer-type categories are supported since the underlying model allows them.

### `static Future<Response> _handleFinanceTransactions(Request request)` <a id="_handlefinancetransactions"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 632)
- **Purpose:** Implement `GET /finance/transactions` with pagination and multiple filters.
- **Inputs:** `request` query `limit` (default 20, clamped 0..200), `offset` (default 0, clamped
  0..1,000,000), optional `type`, `month` (overrides `startDate`/`endDate`), `startDate`/`start`,
  `endDate`/`end`, `accountId`, `categoryId`.
- **Returns:** `Future<Response>`.
- **Side effects:** Reads finance storage.
- **Algorithm:**
  1. Validate `type` if given.
  2. Resolve the date range: an explicit `month` always wins and sets `[monthStart, monthStart+1
     month)`; otherwise `startDate`/`start` and `endDate`/`end` are used as an inclusive lower
     bound and (for non-month ranges) an inclusive upper bound.
  3. Filter transactions by type, `accountId` (matches either `accountId` or `toAccountId`),
     `categoryId`, and the resolved date range; sort newest-first.
  4. Build id-keyed lookup maps for accounts/categories; skip `offset`, take `limit`, and map each
     surviving transaction through `_transactionJson` with those lookup maps.
- **Usage:**
  ```dart
  final res = await handler(_request('GET', '/finance/transactions?limit=5'));
  ```
  (`test/local_api_server_test.dart`.)
- **Notes:** Returns a bare JSON array, matching `_handleTodoList`'s backward-compatibility choice.

### `static Future<Response> _handleFinanceAddTransaction(Request request)` <a id="_handlefinanceaddtransaction"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 699)
- **Purpose:** Implement `POST /finance/add_transaction` with full field validation, including
  transfers.
- **Inputs:** JSON body: `type` (required), `amount` (required positive), `accountId` (required,
  must exist), optional `categoryId` (must exist and match `type` if given), for transfers
  `toAccountId` (required, must exist, must differ from `accountId`), optional `toAmount`
  (positive if given), optional `currency`/`toCurrency`, optional `date`, optional `note`.
- **Returns:** `Future<Response>`.
- **Side effects:** Writes finance storage.
- **Algorithm:**
  1. Validate `type`, `amount`, `accountId`/account lookup, `categoryId`/category lookup + type
     match, and (for transfers) `toAccountId`/target lookup + distinctness — returning 400/404 on
     the first failure.
  2. Validate optional `toAmount` and `date`.
  3. Read the current exchange-rate snapshot id (`null` if empty).
  4. Build a `Transaction`: `currency` defaults to the source account's currency unless an explicit
     non-empty `currency` is given (trimmed + uppercased); for transfers, `toAccountId`/`toAmount`/
     `toCurrency` are populated (with `toCurrency` defaulting to the target account's currency),
     and left `null` for non-transfers.
  5. Append the transaction to a copy of `FinanceData` (preserving every other field verbatim) and
     save.
  6. Return `{success: true, id, transaction: _transactionJson(tx)}`.
- **Usage:**
  ```dart
  await handler(_request('POST', '/finance/add_transaction', body: {
    'type': 'expense',
    'amount': 12.5,
    'accountId': accountId,
  }));
  ```
  (`test/local_api_server_test.dart`, finance add-transaction test.)
- **Notes:** Storing the current rate-snapshot id (not a computed converted amount) is what lets
  `_handleFinanceSummary` later convert this transaction using the rate that was current when it
  was recorded.

### `static Future<Response> _handleFinanceSubscriptions(Request request)` <a id="_handlefinancesubscriptions"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 807)
- **Purpose:** Implement `GET /finance/subscriptions?includeInactive=true` with resolved account
  and category names.
- **Inputs:** `request` query optional `includeInactive` (`true`/`1`/`yes`).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads finance storage.
- **Algorithm:** Filter subscriptions to active ones unless `includeInactive`; build account/
  category id-keyed lookup maps; map each subscription to a JSON object inline (not via a shared
  `_xxxJson` helper) including resolved `accountName`/`categoryName`.
- **Usage:** Routed from `_buildHandler()`:
  `router.get('/finance/subscriptions', _handleFinanceSubscriptions);`
- **Notes:** Unlike the other serializers, this endpoint's JSON shape is built inline rather than
  through a dedicated `_subscriptionJson` helper — there is no reusable serializer to link to for
  subscriptions elsewhere in this file.

### `static Future<Response> _handleWeightList(Request request)` <a id="_handleweightlist"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 853)
- **Purpose:** Implement `GET /weight/list?limit=n` — recent weight records with effective
  (inherited) measurements.
- **Inputs:** `request` query `limit` (default 30, clamped 0..200).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads weight storage.
- **Algorithm:** Sort records newest-first by `datetime`; take `limit`; map each through
  `_weightRecordJson(r, data)`.
- **Usage:** Routed from `_buildHandler()`: `router.get('/weight/list', _handleWeightList);`
- **Notes:** Returns a bare JSON array.

### `static Future<Response> _handleWeightAdd(Request request)` <a id="_handleweightadd"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 869)
- **Purpose:** Implement `POST /weight/add` — record a new weight entry with optional body
  composition and circumference measurements.
- **Inputs:** JSON body: `weight` (required positive), optional `bodyFat`/`bustCm`/`waistCm`/
  `hipCm` (each rejected with 400 if present but not a positive number), optional `date`, optional
  `notes`.
- **Returns:** `Future<Response>`.
- **Side effects:** Writes weight storage.
- **Algorithm:**
  1. Validate `weight` and every provided optional numeric field independently — each is `null`
     when the key is entirely absent, but a 400 error when the key is present with a non-positive
     or non-numeric value.
  2. Validate `date` if given.
  3. Build a `WeightRecord`; append it to the (loaded-or-empty) `WeightData`, preserving every
     other settings field verbatim.
  4. Save; return `{success: true, id, record: _weightRecordJson(record, next)}`.
- **Usage:**
  ```dart
  await handler(_request('POST', '/weight/add', body: {'weight': 65.5}));
  ```
  (`test/local_api_server_test.dart`, weight add test.)
- **Notes:** The optional fields' "absent vs. invalid" distinction mirrors `_handleTodoAdd`'s date
  handling: `body['x'] != null && parsed == null` is the reused pattern for "present but invalid".

### `static Future<Response> _handleWeightStats(Request request)` <a id="_handleweightstats"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 929)
- **Purpose:** Implement `GET /weight/stats` — latest/average/trend plus BMI, waist-hip ratio, and
  effective measurements.
- **Inputs:** `request` (unused beyond routing).
- **Returns:** `Future<Response>`.
- **Side effects:** Reads weight storage.
- **Algorithm:**
  1. If no records, return an all-null/`'unknown'` shape (still including `height` if data exists).
  2. Sort records newest-first; `latest` = most recent weight; `avg_7d`/`avg_30d` = mean weight of
     records within 7/30 days of now (`null` if the window is empty).
  3. Trend (only computed with at least 4 records in the 30-day window): split that window in half
     (`recent` = first half of the desc-sorted list, i.e. the more recent half; `older` = second
     half); average each half; `diff = avgRecent - avgOlder`; `diff > 0.3` → `'up'`, `diff < -0.3`
     → `'down'`, else `'stable'`. Fewer than 4 records leaves `trend = 'unknown'`.
  4. Compute `effective` measurements via `WeightData.effectiveMeasurementsUpTo(records,
     latestRecord.datetime)`, then `bmi`/`waistHipRatio` via `WeightData.calculateBMI`/
     `calculateWaistHipRatio` on `height`/`latest`/`effective`.
- **Usage:** Routed from `_buildHandler()`: `router.get('/weight/stats', _handleWeightStats);`
- **Notes:** Preserves the historical response keys (`latest`, `avg_7d`, `avg_30d`, `trend`) while
  adding new fields (`bmi`, `waistHipRatio`, `height`, `bodyFat`, `latestRecord`,
  `effectiveMeasurements`) — see
  [../../features/weight.md](../../../features/weight.md) for how effective measurements and the
  grace-window logic behave in the storage layer.

### `static List<Map<String, dynamic>> _visibleTodoTasks(TodoData data, DateTime date, {String? typeStr})` <a id="_visibletodotasks"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1008)
- **Purpose:** Compute the list of tasks (daily templates + one-time tasks) that should be visible
  on `date`, serialized to JSON, shared by `_handleTodoList`, `_handleTodoDay`, and
  `_handleTodoStats`.
- **Inputs:** `data`, `date`, optional `typeStr` filter (matched against `task.type.name`).
- **Returns:** A `List<Map<String, dynamic>>` of `_todoTaskJson` results.
- **Side effects:** None.
- **Algorithm:**
  1. For each daily template: skip if `typeStr` doesn't match, skip if `task.type != daily`, skip
     if `date` is before the task's `startDate`/`createdDate`, skip if the task has been
     soft-deleted on or before `date` (`deletedDate`); otherwise emit `_todoTaskJson` with
     `isCompleted` read from `data.dailyLog.isCompleted(date, task.id)`.
  2. For each one-time task: skip if `typeStr` doesn't match, skip daily-type tasks (handled
     above); if `scheduledDate` is set, skip if `date` is before it, skip a completed task unless
     `date` equals its scheduled date, and skip an incomplete task whose scheduled date is in the
     future relative to `date`; otherwise emit `_todoTaskJson` with `isCompleted: task.isCompleted`.
- **Usage:**
  ```dart
  return _json(_visibleTodoTasks(data, date, typeStr: typeStr));
  ```
  (`_handleTodoList`, same file.)
- **Notes:** Incomplete one-time tasks with no `scheduledDate`, or whose scheduled date has passed
  and are still incomplete, "carry forward" and remain visible on later dates — matching the
  existing overdue-carry-forward behavior tested by `_handleTodoStats`'s `overdue` counter.

### `static Map<String, dynamic> _todoTaskJson(Task task, {DateTime? date, bool? isCompleted, DailyCompletionLog? dailyLog})` <a id="_todotaskjson"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1058)
- **Purpose:** Serialize a `Task` (plus its subtasks) into the API's JSON task shape.
- **Inputs:** `task`; optional `date`/`isCompleted`/`dailyLog` for date-scoped completion.
- **Returns:** A `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:** Emit `id`/`title`/`note`/`emoji`/`type.name`; `isCompleted` uses the passed value
  if given, else `task.isCompleted`; each subtask's `isCompleted` comes from
  `dailyLog.isSubtaskCompleted(date, subtask.id)` when both `date` and `dailyLog` are supplied,
  else from `subtask.isCompleted`; all `DateTime` fields are ISO-8601 strings or `null`;
  `recurrence` is `task.recurrence?.toJson()`.
- **Usage:**
  ```dart
  results.add(_todoTaskJson(task, date: date, isCompleted: ..., dailyLog: data.dailyLog));
  ```
  (`_visibleTodoTasks`, same file, for daily templates.)
- **Notes:** The `date`/`dailyLog` parameters exist specifically so daily templates' subtask
  completion can be read per-day rather than from a single stored flag on the subtask.

### `static Map<String, dynamic> _accountJson(Account account, {double? balance, double? convertedBalance, required String defaultCurrency})` <a id="_accountjson"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1100)
- **Purpose:** Serialize an `Account` for API output while omitting sensitive card fields.
- **Inputs:** `account`; optional `balance`/`convertedBalance`; required `defaultCurrency`.
- **Returns:** A `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:** Emit id/type/bankOrApp/name/currency/emoji/imagePath/fee-waiver fields and
  `modifiedAt`; conditionally include `balance`/`convertedBalance` (rounded via `_round`) only when
  provided.
- **Usage:**
  ```dart
  return _accountJson(account, balance: balance, convertedBalance: convertedBalance,
      defaultCurrency: finData.defaultCurrency);
  ```
  (`_handleFinanceAccounts`, same file.)
- **Notes:** `securityCode`, card number, and expiry date are intentionally never read from
  `account` here — see
  [../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api).

### `static Map<String, dynamic> _categoryJson(Category category)` <a id="_categoryjson"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1129)
- **Purpose:** Serialize a `Category` for API output.
- **Inputs:** `category`.
- **Returns:** A `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:** Emit id/name/emoji/`type.name`/`icon.toJson()`/`modifiedAt`.
- **Usage:**
  ```dart
  finData.categories.where(...).map(_categoryJson).toList()
  ```
  (`_handleFinanceCategories`, same file.)
- **Notes:** Icon metadata is included so API consumers can render the same category icons as the
  app.

### `static Map<String, dynamic> _transactionJson(Transaction tx, {Map<String, Account> accountsById = const {}, Map<String, Category> categoriesById = const {}})` <a id="_transactionjson"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1145)
- **Purpose:** Serialize a `Transaction`, resolving human-readable account/category names when
  lookup maps are supplied.
- **Inputs:** `tx`; optional `accountsById`/`categoriesById` (default empty).
- **Returns:** A `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:** Emit transaction fields plus `accountName`/`toAccountName`/`categoryName` resolved
  from the lookup maps (`null` when the referenced id is missing or the map wasn't supplied).
- **Usage:**
  ```dart
  'transaction': _transactionJson(tx),
  ```
  (`_handleFinanceAddTransaction`, same file — called without lookup maps, so names are `null`
  there; `_handleFinanceTransactions` passes both maps.)
- **Notes:** Designed to degrade gracefully when called without lookup maps (e.g. right after
  creating a transaction, before names are needed).

### `static Map<String, dynamic> _weightRecordJson(WeightRecord record, WeightData data)` <a id="_weightrecordjson"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1180)
- **Purpose:** Serialize a `WeightRecord` with its display-effective measurements.
- **Inputs:** `record`, `data` (the full record set, needed to compute inheritance).
- **Returns:** A `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:** Compute `WeightData.effectiveMeasurementsUpTo(data.records, record.datetime)`;
  emit weight/bodyFat/bustCm/waistCm/hipCm/`effectiveMeasurements`
  (via `_measurementsJson`)/`date` (`yyyy-MM-dd`)/`datetime`/notes/`modifiedAt`.
- **Usage:**
  ```dart
  sorted.take(limit).map((r) => _weightRecordJson(r, data)).toList()
  ```
  (`_handleWeightList`, same file.)
- **Notes:** Effective measurements are computed for display only — nothing is written back to
  `record` even when a value is inherited from an earlier record.

### `static Map<String, dynamic> _measurementsJson(EffectiveWeightMeasurements measurements)` <a id="_measurementsjson"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1208)
- **Purpose:** Serialize an `EffectiveWeightMeasurements` value to JSON.
- **Inputs:** `measurements`.
- **Returns:** A `Map<String, dynamic>` with `bustCm`/`waistCm`/`hipCm`.
- **Side effects:** None.
- **Algorithm:** Direct field passthrough, no computation.
- **Usage:**
  ```dart
  'effectiveMeasurements': _measurementsJson(effective),
  ```
  (`_handleWeightStats` and `_weightRecordJson`, same file.)
- **Notes:** A `null` field means no positive value exists for that measurement up to the
  reference date — it is not synonymous with zero.

### `static TodoData _todoDataWith(TodoData data, {List<Task>? dailyTemplates, List<Task>? oneTimeTasks})` <a id="_tododatawith"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1225)
- **Purpose:** Clone a `TodoData` while optionally replacing its `dailyTemplates`/`oneTimeTasks`
  lists.
- **Inputs:** `data`; optional replacement `dailyTemplates`/`oneTimeTasks`.
- **Returns:** `TodoData`.
- **Side effects:** None.
- **Algorithm:** Build a new `TodoData` using the replacement lists if given, else the originals,
  and copy every other field (`dailyLog`, `dailyScores`, both reminder-hour/minute pairs, sort
  modes/custom orders, `settingsModifiedAt`) verbatim.
- **Usage:**
  ```dart
  final next = type == TaskType.daily
      ? _todoDataWith(data, dailyTemplates: [...data.dailyTemplates, task])
      : _todoDataWith(data, oneTimeTasks: [...data.oneTimeTasks, task]);
  ```
  (`_handleTodoAdd`, same file.)
- **Notes:** Exists because the local API only ever needs to replace one of the two task lists at
  a time, unlike a general-purpose `copyWith`.

### `static Task _copyOneTimeTask(Task task, {bool? isCompleted, DateTime? completedDate, List<SubTask>? subtasks})` <a id="_copyonetimetask"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1250)
- **Purpose:** Copy a one-time `Task`, allowing `completedDate` to be explicitly cleared to `null`.
- **Inputs:** `task`; optional `isCompleted`/`completedDate`/`subtasks` overrides.
- **Returns:** `Task`.
- **Side effects:** None.
- **Algorithm:** Construct a new `Task` from every field of `task`, substituting the given
  overrides, and always stamping `modifiedAt: DateTime.now().toUtc()`.
- **Usage:**
  ```dart
  updated = _copyOneTimeTask(existing, isCompleted: completed,
      completedDate: completed ? DateTime.now() : null);
  ```
  (`_handleTodoComplete`, same file.)
- **Notes:** Exists specifically because `Task.copyWith` has no way to pass an explicit `null` for
  `completedDate` (reopening a task must clear it) — a plain `copyWith(completedDate: null)` would
  be indistinguishable from "don't change this field" under the usual copyWith convention.

### `static void _addCategoryTotal(Map<String, _CategoryTotal> totals, Transaction tx, double converted)` <a id="_addcategorytotal"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1281)
- **Purpose:** Accumulate a converted transaction amount into a `type:categoryId`-keyed totals map.
- **Inputs:** `totals` (mutated), `tx`, `converted` (already currency-converted amount).
- **Returns:** `void`.
- **Side effects:** Mutates `totals` in place.
- **Algorithm:** Key = `'${tx.type.name}:${tx.categoryId ?? ''}'`; if absent, insert a new
  `_CategoryTotal` with `count: 1`; else replace with `existing.add(converted)`.
- **Usage:**
  ```dart
  _addCategoryTotal(categoryTotals, tx, converted);
  ```
  (`_handleFinanceSummary`, same file, for income and expense transactions.)
- **Notes:** Empty `categoryId` (`''`) represents uncategorized income/expense and is kept as its
  own bucket rather than merged with a named category.

### `static DateTime? _queryMonth(Request request)` <a id="_querymonth"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1305)
- **Purpose:** Parse a `?month=yyyy-MM` query parameter into the first day of that month.
- **Inputs:** `request`.
- **Returns:** `DateTime?`.
- **Side effects:** None.
- **Algorithm:** Split on `-`; require exactly 2 parts, both integer-parseable, with `month` in
  1..12; return `DateTime(year, month)`, else `null`.
- **Usage:**
  ```dart
  final monthStart = _queryMonth(request) ?? DateTime(now.year, now.month);
  ```
  (`_handleFinanceSummary`, same file.)
- **Notes:** Absent or malformed `month` returns `null` so callers can supply their own default
  rather than erroring.

### `static int _queryInt(Request request, String name, {required int defaultValue})` <a id="_queryint"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1321)
- **Purpose:** Parse a named integer query parameter, falling back to a default.
- **Inputs:** `request`, `name`, `defaultValue`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** `int.tryParse(queryParameters[name] ?? '') ?? defaultValue`.
- **Usage:**
  ```dart
  final limit = _queryInt(request, 'limit', defaultValue: 20).clamp(0, 200);
  ```
  (`_handleFinanceTransactions`, same file.)
- **Notes:** Callers are responsible for clamping the result to a sane range; this helper itself
  applies no bounds.

### `static bool _queryBool(Request request, String name)` <a id="_querybool"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1335)
- **Purpose:** Parse a named boolean-ish query parameter.
- **Inputs:** `request`, `name`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Lowercase the value; true iff it equals `'true'`, `'1'`, or `'yes'`.
- **Usage:**
  ```dart
  final includeInactive = _queryBool(request, 'includeInactive');
  ```
  (`_handleFinanceSubscriptions`, same file.)
- **Notes:** Any other value (including absent) is `false` — there is no error path.

### `static DateTime? _queryDate(Request request, String name)` <a id="_querydate"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1345)
- **Purpose:** Parse a named ISO-ish date query parameter.
- **Inputs:** `request`, `name`.
- **Returns:** `DateTime?`.
- **Side effects:** None.
- **Algorithm:** `DateTime.tryParse(value)` if present and non-empty, else `null`.
- **Usage:**
  ```dart
  final date = _queryDate(request, 'date') ?? DateTime.now();
  ```
  (`_handleTodoList`, same file.)
- **Notes:** Uses Dart's built-in ISO-8601-compatible parser; no custom format handling.

### `static DateTime? _optionalBodyDate(Map<String, dynamic> body, String name)` <a id="_optionalbodydate"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1356)
- **Purpose:** Parse a named date field out of a decoded JSON request body.
- **Inputs:** `body`, `name`.
- **Returns:** `DateTime?`.
- **Side effects:** None.
- **Algorithm:** `null` if the key is missing; `null` if the value isn't a non-blank `String`;
  otherwise `DateTime.tryParse(value.trim())`.
- **Usage:**
  ```dart
  final dueDate = _optionalBodyDate(body, 'dueDate');
  if (body['dueDate'] != null && dueDate == null) return _error(400, 'invalid dueDate');
  ```
  (`_handleTodoAdd`, same file — the repeated "present but invalid" check pattern used by every
  POST handler in this file.)
- **Notes:** A non-`String` JSON value (e.g. a number) for a date field is treated the same as an
  invalid string, not coerced.

### `static double? _positiveDouble(Object? value)` <a id="_positivedouble"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1368)
- **Purpose:** Parse a required strictly-positive numeric value from untyped JSON input.
- **Inputs:** `value` (expected `num` or numeric `String`).
- **Returns:** `double?` (`null` on failure).
- **Side effects:** None.
- **Algorithm:** `switch` on the runtime type: `num` → `.toDouble()`; `String` → `double.tryParse`
  on the trimmed text; anything else → `null`. Then reject `null` or `<= 0`.
- **Usage:**
  ```dart
  final amount = _positiveDouble(body['amount']);
  if (amount == null) return _error(400, 'valid amount is required');
  ```
  (`_handleFinanceAddTransaction`, same file.)
- **Notes:** Zero is rejected along with negative numbers — amounts/weights/measurements must be
  strictly positive throughout this file.

### `static double? _optionalPositiveDouble(Object? value)` <a id="_optionalpositivedouble"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1383)
- **Purpose:** Parse an optional strictly-positive numeric field, treating an absent key as `null`.
- **Inputs:** `value`.
- **Returns:** `double?`.
- **Side effects:** None.
- **Algorithm:** `null` if `value == null`; otherwise delegate to `_positiveDouble(value)`.
- **Usage:**
  ```dart
  final bodyFat = _optionalPositiveDouble(body['bodyFat']);
  if (body['bodyFat'] != null && bodyFat == null) return _error(400, 'valid bodyFat is required');
  ```
  (`_handleWeightAdd`, same file.)
- **Notes:** The distinction between "key absent" (silently `null`) and "key present but invalid"
  (400 error) is enforced by the caller comparing `body['x'] != null`, not by this helper itself.

### `static String? _optionalTrimmedString(Object? value)` <a id="_optionaltrimmedstring"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1393)
- **Purpose:** Parse an optional string field, trimming whitespace and collapsing blanks to `null`.
- **Inputs:** `value`.
- **Returns:** `String?`.
- **Side effects:** None.
- **Algorithm:** `null` if not a `String`; else trim and return `null` if the trimmed result is
  empty, otherwise the trimmed string.
- **Usage:**
  ```dart
  note: _optionalTrimmedString(body['note']),
  ```
  (`_handleTodoAdd`, same file.)
- **Notes:** None.

### `static List<SubTask> _parseSubtasks(Object? value)` <a id="_parsesubtasks"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1404)
- **Purpose:** Parse a JSON `subtasks` array into `SubTask` objects.
- **Inputs:** `value` (expected a `List` of `String`s and/or `Map`s).
- **Returns:** `List<SubTask>` (empty if `value` isn't a `List`).
- **Side effects:** None.
- **Algorithm:** For each item: a bare `String` becomes the (trimmed) title with `isCompleted:
  false`; a `Map` reads `title` (trimmed) and optional `isCompleted`; any item yielding an empty or
  missing title is skipped entirely.
- **Usage:**
  ```dart
  subtasks: _parseSubtasks(body['subtasks']),
  ```
  (`_handleTodoAdd`, same file.)
- **Notes:** Accepts two input shapes (plain strings or `{title, isCompleted}` objects) in the same
  array — mixed arrays are allowed.

### `static TaskRecurrence? _parseRecurrence(Object? value)` <a id="_parserecurrence"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1428)
- **Purpose:** Parse a JSON recurrence object into a `TaskRecurrence`.
- **Inputs:** `value` (expected `{type, ...}`).
- **Returns:** `TaskRecurrence?` (`null` on any structural problem).
- **Side effects:** None.
- **Algorithm:** `null` if `value` is `null` or not a `Map`; normalize keys to `String`; switch on
  `type`: `'everyNDays'` requires a positive numeric `intervalDays` →
  `TaskRecurrence.everyNDays`; `'monthlyOnDay'` requires a positive numeric `dayOfMonth` →
  `TaskRecurrence.monthlyOnDay`; `'yearlyOnMonthDay'` requires positive numeric `monthOfYear` and
  `dayOfMonth` → `TaskRecurrence.yearlyOnMonthDay`; any other `type` (or a missing/invalid field
  for the matched case) returns `null`.
- **Usage:**
  ```dart
  final recurrence = _parseRecurrence(body['recurrence']);
  if (body['recurrence'] != null && recurrence == null) return _error(400, 'invalid recurrence');
  ```
  (`_handleTodoAdd`, same file.)
- **Notes:** Only these three recurrence shapes are accepted over the API — matches the
  `TaskRecurrence` factory constructors exposed by the todo model.

### `static TaskType? _taskTypeByName(String? name)` <a id="_tasktypebyname"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1459)
- **Purpose:** Resolve a `TaskType` enum value from its API name string.
- **Inputs:** `name`.
- **Returns:** `TaskType?`.
- **Side effects:** None.
- **Algorithm:** Linear scan of `TaskType.values` for a matching `.name`; `null` if `name` is
  `null` or nothing matches.
- **Usage:**
  ```dart
  final type = _taskTypeByName(typeStr);
  if (type == null) return _error(400, 'invalid task type');
  ```
  (`_handleTodoAdd`, same file.)
- **Notes:** Unknown/misspelled type names are rejected rather than silently defaulted.

### `static TransactionType? _transactionTypeByName(String? name)` <a id="_transactiontypebyname"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1472)
- **Purpose:** Resolve a `TransactionType` enum value from its API name string.
- **Inputs:** `name`.
- **Returns:** `TransactionType?`.
- **Side effects:** None.
- **Algorithm:** Same linear-scan pattern as `_taskTypeByName`, over `TransactionType.values`.
- **Usage:**
  ```dart
  final type = typeStr == null ? null : _transactionTypeByName(typeStr);
  ```
  (`_handleFinanceCategories`, same file.)
- **Notes:** None.

### `static AccountType? _accountTypeByName(String name)` <a id="_accounttypebyname"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1485)
- **Purpose:** Resolve an `AccountType` enum value from its API name string.
- **Inputs:** `name` (non-nullable, unlike its two siblings above).
- **Returns:** `AccountType?`.
- **Side effects:** None.
- **Algorithm:** Same linear-scan pattern, over `AccountType.values`.
- **Usage:**
  ```dart
  final type = typeStr == null ? null : _accountTypeByName(typeStr);
  ```
  (`_handleFinanceAccounts`, same file — the caller only invokes it once `typeStr` is already known
  non-null.)
- **Notes:** Unlike `_taskTypeByName`/`_transactionTypeByName`, this helper takes a non-nullable
  `String`; callers guard the null case themselves before calling it.

### `static double _round(double value, {int digits = 2})` <a id="_round"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1497)
- **Purpose:** Round a `double` to a fixed number of decimal digits for stable JSON output.
- **Inputs:** `value`, `digits` (default 2).
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** `double.parse(value.toStringAsFixed(digits))` — round-trips through a decimal
  string rather than doing binary-float arithmetic directly.
- **Usage:**
  ```dart
  'amount': _round(total.amount),
  ```
  (`_handleFinanceSummary`, same file.)
- **Notes:** The string round-trip avoids surfacing binary floating-point noise (e.g. `19.999999999998`)
  in API responses.

### `static double? _nullableRound(double? value, {int digits = 2})` <a id="_nullableround"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1506)
- **Purpose:** `null`-safe wrapper around `_round`.
- **Inputs:** `value`, `digits` (default 2).
- **Returns:** `double?`.
- **Side effects:** None.
- **Algorithm:** `value == null ? null : _round(value, digits: digits)`.
- **Usage:**
  ```dart
  'bmi': _nullableRound(WeightData.calculateBMI(data.height, latest)),
  ```
  (`_handleWeightStats`, same file.)
- **Notes:** None.

### `static Response _json(Object? data)` <a id="_json"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1515)
- **Purpose:** Encode any JSON-compatible value as a `200 OK` response.
- **Inputs:** `data`.
- **Returns:** `Response`.
- **Side effects:** None.
- **Algorithm:** `Response.ok(jsonEncode(data), headers: {'Content-Type': 'application/json'})`.
- **Usage:** Used by every route handler in this file to build its success response, e.g.
  `return _json({'status': 'ok'});` in `_handlePing`.
- **Notes:** Every successful API response is `application/json`, with no exceptions.

### `static Response _error(int status, String message)` <a id="_error"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1525)
- **Purpose:** Encode a JSON error response with a given HTTP status.
- **Inputs:** `status`, `message`.
- **Returns:** `Response`.
- **Side effects:** None.
- **Algorithm:** `Response(status, body: jsonEncode({'error': message}), headers: {...json...})`.
- **Usage:**
  ```dart
  if (title == null || title.isEmpty) return _error(400, 'title is required');
  ```
  (`_handleTodoAdd`, same file; also used for the `data_unreadable` 500 in `_errorMiddleware`.)
- **Notes:** Error bodies always expose a single `error` string key, never a stack trace.

### `static Future<Map<String, dynamic>?> _parseBody(Request request)` <a id="_parsebody"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1536)
- **Purpose:** Read and JSON-decode a request body, tolerating empty or malformed input.
- **Inputs:** `request`.
- **Returns:** `Future<Map<String, dynamic>?>` (`null` on empty/malformed body).
- **Side effects:** Consumes the request body stream (`request.readAsString()`).
- **Algorithm:** Read the body as a string; if blank after trimming, return `null`; otherwise
  `jsonDecode` and cast to `Map<String, dynamic>`; any thrown exception (bad JSON, wrong top-level
  type) is caught and turned into `null`.
- **Usage:**
  ```dart
  final body = await _parseBody(request);
  if (body == null) return _error(400, 'invalid JSON body');
  ```
  (`_handleTodoAdd` and every other POST handler in this file.)
- **Notes:** A JSON body whose top level isn't an object (e.g. a bare array or number) is treated
  the same as malformed JSON, since the cast to `Map<String, dynamic>` throws.

### `static Middleware _corsMiddleware()` <a id="_corsmiddleware"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1553)
- **Purpose:** Add permissive CORS headers to every response and answer `OPTIONS` preflight
  requests directly.
- **Inputs:** None.
- **Returns:** `Middleware`.
- **Side effects:** None (the returned middleware has side effects at request time, but building it
  does not).
- **Algorithm:** For `OPTIONS` requests, return `Response.ok('', headers: _corsHeaders)`
  immediately (skipping the wrapped handler entirely); otherwise call the inner handler and apply
  `_corsHeaders` to its response via `.change(headers: ...)`.
- **Usage:** Applied in `_buildHandler()`: `.addMiddleware(_corsMiddleware())`, as the outermost
  middleware.
- **Notes:** `_corsHeaders` allows any origin (`Access-Control-Allow-Origin: '*'`) — see
  [../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api) for why
  this is considered acceptable for a loopback-bound local tool.

### `static Middleware _authMiddleware()` <a id="_authmiddleware"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1576)
- **Purpose:** Enforce the local API's authentication policy: Basic Auth when credentials are
  configured, loopback-only otherwise.
- **Inputs:** None.
- **Returns:** `Middleware`.
- **Side effects:** None at build time.
- **Algorithm:**
  1. Read the caller's remote address from `shelf.io.connection_info`; treat a missing connection
     info as loopback (`isLoopback = remoteAddr == null || remoteAddr.isLoopback`).
  2. If `_hasCredentials`: require a valid `Authorization: Basic ...` header
     (`_validateBasicAuth`) for **every** request, including from loopback — missing/invalid header
     returns `401` with a `WWW-Authenticate: Basic realm="MyDay API"` header.
  3. Else (`!_hasCredentials`): reject non-loopback callers with `403` ("authentication required for
     non-localhost access"); loopback callers pass through unauthenticated.
  4. Otherwise call the inner handler.
- **Usage:** Applied in `_buildHandler()`: `.addMiddleware(_authMiddleware())`, after CORS and
  before the error middleware.
- **Notes:** When credentials are configured, they are required even for `127.0.0.1`/`localhost` —
  configuring credentials does not just gate remote access, it gates all access. See
  [../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api).

### `static bool get _hasCredentials` <a id="_hascredentials"></a>
- **Kind:** private static getter of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1611)
- **Purpose:** Report whether both an API username and password are configured and non-empty.
- **Inputs:** None (reads `_username`/`_password`).
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `_username != null && _username!.isNotEmpty && _password != null &&
  _password!.isNotEmpty`.
- **Usage:**
  ```dart
  if (isNonLoopback && !_hasCredentials) { _lastError = 'credentials_required'; return; }
  ```
  (`start()`, same file; also gates the branch in `_authMiddleware()`.)
- **Notes:** A username or password consisting only of an empty string counts as "not configured" —
  this is the single source of truth for both `start()`'s non-loopback refusal and
  `_authMiddleware()`'s Basic-Auth-vs-loopback-only branch, so the two stay consistent.

### `static bool _validateBasicAuth(String header)` <a id="_validatebasicauth"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1622)
- **Purpose:** Validate an HTTP `Authorization: Basic ...` header against the configured
  credentials.
- **Inputs:** `header` (the raw header value).
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Require the `'Basic '` prefix; base64-decode and UTF-8-decode the remainder;
  split on `:`; require at least 2 parts; compare `parts[0]` to `_username` and
  `parts.sublist(1).join(':')` (rejoining any additional colons) to `_password`. Any decode
  exception is caught and treated as invalid.
- **Usage:**
  ```dart
  if (authHeader == null || !_validateBasicAuth(authHeader)) { ...401... }
  ```
  (`_authMiddleware`, same file.)
- **Notes:** Rejoining `parts.sublist(1)` with `:` means a password itself containing colons is
  handled correctly — only the first colon splits user from password.

### `static Middleware _errorMiddleware()` <a id="_errormiddleware"></a>
- **Kind:** private static method of `LocalApiServer`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1641)
- **Purpose:** Convert uncaught exceptions from route handlers into JSON error responses, including
  the dedicated `data_unreadable` contract for corrupted storage files.
- **Inputs:** None.
- **Returns:** `Middleware`.
- **Side effects:** None at build time.
- **Algorithm:** `try` the inner handler; on `TodoStorageException`, `WeightStorageException`, or
  `FinanceStorageException`, return `_error(500, 'data_unreadable')`; on any other exception,
  return `_error(500, 'internal error: $e')`.
- **Usage:** Applied innermost in `_buildHandler()`: `.addMiddleware(_errorMiddleware())`, wrapping
  the router directly.
- **Notes:** This is the mechanism behind the `data_unreadable` 500 documented at
  [../../../platform-notes.md#local-http-api](../../../platform-notes.md#local-http-api): the
  `*Storage.load()`/`save()` calls throw a typed exception when an *existing* data file fails to
  parse (a missing file is not an error and uses the endpoint's own empty-data behavior instead),
  and POST handlers throw before persisting any change, so a write never partially applies.

### `const _CategoryTotal({required this.categoryId, required this.type, required this.amount, required this.count})` <a id="_categorytotal-new"></a>
- **Kind:** constructor of `_CategoryTotal`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1671)
- **Purpose:** Construct an immutable accumulated finance category total.
- **Inputs:** `categoryId`, `type`, `amount`, `count` (all required).
- **Returns:** A new `_CategoryTotal`.
- **Side effects:** None.
- **Algorithm:** Direct field assignment (`const` constructor, no logic).
- **Usage:**
  ```dart
  totals[key] = _CategoryTotal(categoryId: tx.categoryId ?? '', type: tx.type,
      amount: converted, count: 1);
  ```
  (`_addCategoryTotal`, same file.)
- **Notes:** `_CategoryTotal` is a private helper class used only within this file to accumulate
  `_handleFinanceSummary`'s per-category totals before they're serialized.

### `_CategoryTotal add(double value)` <a id="add"></a>
- **Kind:** method of `_CategoryTotal`
- **Source:** `lib/shared/services/local_api_server.dart` (line 1683)
- **Purpose:** Return a new `_CategoryTotal` with `value` added to the running amount and the count
  incremented.
- **Inputs:** `value`.
- **Returns:** `_CategoryTotal`.
- **Side effects:** None (immutable — returns a new instance).
- **Algorithm:** `_CategoryTotal(categoryId: categoryId, type: type, amount: amount + value, count:
  count + 1)`.
- **Usage:**
  ```dart
  totals[key] = existing.add(converted);
  ```
  (`_addCategoryTotal`, same file.)
- **Notes:** Preserves `categoryId` and `type` unchanged; only `amount` and `count` accumulate.
