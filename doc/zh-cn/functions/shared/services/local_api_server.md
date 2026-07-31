# lib/shared/services/local_api_server.dart

仅桌面静态服务（`LocalApiServer`）运行 MyDay 本地 HTTP API：基于 Shelf 的服务器在纯 JSON 上暴露 `/ping`、`/todo/*`、`/finance/*` 和 `/weight/*` 端点，使本地工具（快捷方式、组件、脚本）能读写应用自己使用的相同磁盘数据。从 `main()` 启动（见 [架构 — 启动序列](../../../architecture.md#startup-sequence)）并从设置页桌面小节控制（[设置](../../../features/settings.md)）。配置（`apiPort`、`apiListenAddress`、`apiEnabled`、`apiUsername`、`apiPassword`）、非回环凭据要求、宽松 CORS/Basic 认证中间件栈和 `data_unreadable` 500 契约全部在 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api) 文档化——本页覆盖那个契约背后的实现。端点列表本身也总结在 `AGENTS.md` 的"Local HTTP API"小节和 [同步](../../../sync.md)。

本文件与 `TodoStorage`、`FinanceStorage`、`ExchangeRateStorage` 和 `WeightStorage` 协作持久化（每个都能在不可解析数据上抛类型化 `*StorageException`，被 `_errorMiddleware` 捕获），并与 `balance_util.dart` 的 `accountBalance`/`convertCurrency` 协作财务货币转换。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `port` | 静态 getter（`LocalApiServer`） | B | 返回配置/绑定的 API 端口。 |
| `listenAddress` | 静态 getter（`LocalApiServer`） | B | 返回配置的监听地址。 |
| `enabled` | 静态 getter（`LocalApiServer`） | B | 返回本地 API 是否在配置中启用。 |
| `isRunning` | 静态 getter（`LocalApiServer`） | B | 返回 HTTP 监听器当前是否打开。 |
| `lastError` | 静态 getter（`LocalApiServer`） | B | 返回上次启动失败原因（如有）。 |
| [`loadConfig`](#loadconfig) | 静态方法（`LocalApiServer`） | A | 从 `storage_config.json` 加载 API 设置。 |
| [`start`](#start) | 静态方法（`LocalApiServer`） | A | 启用且允许时启动 HTTP 监听器。 |
| [`stop`](#stop) | 静态方法（`LocalApiServer`） | A | 关闭活动 HTTP 监听器。 |
| [`restart`](#restart) | 静态方法（`LocalApiServer`） | A | 重新加载配置并重启监听器。 |
| [`buildHandlerForTesting`](#buildhandlerfortesting) | 静态方法（`LocalApiServer`） | A | 用注入测试凭据构建路由处理器。 |
| [`_buildHandler`](#_buildhandler) | 静态方法（`LocalApiServer`） | A | 接线路由表和中间件管线。 |
| [`_bindAddress`](#_bindaddress) | 静态方法（`LocalApiServer`） | A | 把配置监听地址解析为 `InternetAddress`。 |
| [`_handlePing`](#_handleping) | 静态方法（`LocalApiServer`） | A | 处理 `GET /ping`。 |
| [`_handleTodoList`](#_handletodolist) | 静态方法（`LocalApiServer`） | A | 处理 `GET /todo/list`。 |
| [`_handleTodoDay`](#_handletododay) | 静态方法（`LocalApiServer`） | A | 处理 `GET /todo/day`。 |
| [`_handleTodoAdd`](#_handletodoadd) | 静态方法（`LocalApiServer`） | A | 处理 `POST /todo/add`。 |
| [`_handleTodoComplete`](#_handletodocomplete) | 静态方法（`LocalApiServer`） | A | 处理 `POST /todo/complete`。 |
| [`_handleTodoScore`](#_handletodoscore) | 静态方法（`LocalApiServer`） | A | 处理 `POST /todo/score`。 |
| [`_handleTodoStats`](#_handletodostats) | 静态方法（`LocalApiServer`） | A | 处理 `GET /todo/stats`。 |
| [`_handleFinanceSummary`](#_handlefinancesummary) | 静态方法（`LocalApiServer`） | A | 处理 `GET /finance/summary`。 |
| [`_handleFinanceAccounts`](#_handlefinanceaccounts) | 静态方法（`LocalApiServer`） | A | 处理 `GET /finance/accounts`。 |
| [`_handleFinanceCategories`](#_handlefinancecategories) | 静态方法（`LocalApiServer`） | A | 处理 `GET /finance/categories`。 |
| [`_handleFinanceTransactions`](#_handlefinancetransactions) | 静态方法（`LocalApiServer`） | A | 处理 `GET /finance/transactions`。 |
| [`_handleFinanceAddTransaction`](#_handlefinanceaddtransaction) | 静态方法（`LocalApiServer`） | A | 处理 `POST /finance/add_transaction`。 |
| [`_handleFinanceSubscriptions`](#_handlefinancesubscriptions) | 静态方法（`LocalApiServer`） | A | 处理 `GET /finance/subscriptions`。 |
| [`_handleWeightList`](#_handleweightlist) | 静态方法（`LocalApiServer`） | A | 处理 `GET /weight/list`。 |
| [`_handleWeightAdd`](#_handleweightadd) | 静态方法（`LocalApiServer`） | A | 处理 `POST /weight/add`。 |
| [`_handleWeightStats`](#_handleweightstats) | 静态方法（`LocalApiServer`） | A | 处理 `GET /weight/stats`。 |
| [`_visibleTodoTasks`](#_visibletodotasks) | 静态方法（`LocalApiServer`） | A | 计算给定日期可见的 todo 任务。 |
| [`_todoTaskJson`](#_todotaskjson) | 静态方法（`LocalApiServer`） | A | 把 `Task` 序列化为 API JSON。 |
| [`_accountJson`](#_accountjson) | 静态方法（`LocalApiServer`） | A | 把 `Account` 序列化为 API JSON，不含机密字段。 |
| [`_categoryJson`](#_categoryjson) | 静态方法（`LocalApiServer`） | A | 把 `Category` 序列化为 API JSON。 |
| [`_transactionJson`](#_transactionjson) | 静态方法（`LocalApiServer`） | A | 把 `Transaction` 序列化为 API JSON。 |
| [`_weightRecordJson`](#_weightrecordjson) | 静态方法（`LocalApiServer`） | A | 把 `WeightRecord` 序列化为 API JSON。 |
| [`_measurementsJson`](#_measurementsjson) | 静态方法（`LocalApiServer`） | A | 把有效身体测量序列化为 JSON。 |
| [`_todoDataWith`](#_tododatawith) | 静态方法（`LocalApiServer`） | A | 复制 `TodoData` 同时替换所选任务列表。 |
| [`_copyOneTimeTask`](#_copyonetimetask) | 静态方法（`LocalApiServer`） | A | 复制一次性 `Task`，允许 `completedDate` 清除。 |
| [`_addCategoryTotal`](#_addcategorytotal) | 静态方法（`LocalApiServer`） | A | 把转换金额累积进类别总计映射。 |
| [`_queryMonth`](#_querymonth) | 静态方法（`LocalApiServer`） | A | 解析 `yyyy-MM` 查询参数。 |
| [`_queryInt`](#_queryint) | 静态方法（`LocalApiServer`） | A | 解析带默认的整数查询参数。 |
| [`_queryBool`](#_querybool) | 静态方法（`LocalApiServer`） | A | 解析布尔查询参数。 |
| [`_queryDate`](#_querydate) | 静态方法（`LocalApiServer`） | A | 解析日期查询参数。 |
| [`_optionalBodyDate`](#_optionalbodydate) | 静态方法（`LocalApiServer`） | A | 从 JSON 体解析可选日期字段。 |
| [`_positiveDouble`](#_positivedouble) | 静态方法（`LocalApiServer`） | A | 解析必填正数值。 |
| [`_optionalPositiveDouble`](#_optionalpositivedouble) | 静态方法（`LocalApiServer`） | A | 解析可选正数值。 |
| [`_optionalTrimmedString`](#_optionaltrimmedstring) | 静态方法（`LocalApiServer`） | A | 解析并修剪可选字符串。 |
| [`_parseSubtasks`](#_parsesubtasks) | 静态方法（`LocalApiServer`） | A | 从 JSON 输入解析子任务。 |
| [`_parseRecurrence`](#_parserecurrence) | 静态方法（`LocalApiServer`） | A | 从 JSON 输入解析 `TaskRecurrence`。 |
| [`_taskTypeByName`](#_tasktypebyname) | 静态方法（`LocalApiServer`） | A | 按 API 名称解析 `TaskType`。 |
| [`_transactionTypeByName`](#_transactiontypebyname) | 静态方法（`LocalApiServer`） | A | 按 API 名称解析 `TransactionType`。 |
| [`_accountTypeByName`](#_accounttypebyname) | 静态方法（`LocalApiServer`） | A | 按 API 名称解析 `AccountType`。 |
| [`_round`](#_round) | 静态方法（`LocalApiServer`） | A | 为稳定 JSON 输出舍入 double。 |
| [`_nullableRound`](#_nullableround) | 静态方法（`LocalApiServer`） | A | 为 JSON 输出舍入可空 double。 |
| [`_json`](#_json) | 静态方法（`LocalApiServer`） | A | 编码成功 JSON 响应。 |
| [`_error`](#_error) | 静态方法（`LocalApiServer`） | A | 编码 JSON 错误响应。 |
| [`_parseBody`](#_parsebody) | 静态方法（`LocalApiServer`） | A | 把请求体解析为 JSON。 |
| [`_corsMiddleware`](#_corsmiddleware) | 静态方法（`LocalApiServer`） | A | 添加宽松 CORS 页头并应答 `OPTIONS`。 |
| [`_authMiddleware`](#_authmiddleware) | 静态方法（`LocalApiServer`） | A | 执行 Basic 认证 / 仅回环策略。 |
| [`_hasCredentials`](#_hascredentials) | 静态 getter（`LocalApiServer`） | A | 返回两个 API 凭据字段是否都已配置。 |
| [`_validateBasicAuth`](#_validatebasicauth) | 静态方法（`LocalApiServer`） | A | 验证 `Basic` Authorization 页头。 |
| [`_errorMiddleware`](#_errormiddleware) | 静态方法（`LocalApiServer`） | A | 把未捕获存储异常转换为 JSON 500。 |
| [`_CategoryTotal.new`](#_categorytotal-new) | 构造函数（`_CategoryTotal`） | A | 存储累积财务类别总计。 |
| [`add`](#add) | 方法（`_CategoryTotal`） | A | 返回把 `value` 加到总计上的副本。 |

`grep -c 'Purpose:' lib/shared/services/local_api_server.dart` 报告 63，与本文件发现的全部 63 个真实声明匹配（5 个普通 getter 加 58 个带真实分支、解析、序列化或 IO 逻辑的方法/getter/构造函数）。未发现错附块和未文档化真实声明——每个 `/// Purpose:` 块都恰好位于其描述的类成员正上方。五个单行字段返回 getter（`port`、`listenAddress`、`enabled`、`isRunning`、`lastError`）是唯一 Tier B 行；此服务文件其他一切都有真实逻辑（验证、存储 IO、JSON 塑形或中间件行为）并按一揽子"服务"规则为 Tier A。两个私有静态字段（`_corsHeaders`）和七个普通私有状态字段（`_server`、`_port`、`_listenAddress`、`_enabled`、`_username`、`_password`、`_lastError`）不单独索引——它们不带文档注释，不是函数/getter/构造函数。

## 文档

### `static Future<void> loadConfig()` <a id="loadconfig"></a>
- **种类：** `LocalApiServer` 的静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 67 行）
- **用途：** 经 `TodoStorage.readConfig()` 从 `storage_config.json` 加载缓存 API 设置（`_port`、`_listenAddress`、`_enabled`、`_username`、`_password`）。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 覆盖类的静态配置字段。
- **算法：**
  1. 经 `TodoStorage.readConfig()` 读取配置 JSON。
  2. 从 JSON 分配 `apiPort`（默认 `7790`）、`apiListenAddress`（默认 `'localhost'`）、`apiEnabled`（默认 `false`）、`apiUsername`、`apiPassword`，逐键回退。
  3. 静默吞掉任何异常（`catch (_) {}`），保留先前缓存值。
- **用法：** （重新）打开监听器前从 `start()` 和 `restart()` 调用；通常不由应用代码直接调用。
- **备注：** 失败按设计静默——损坏或缺失配置保留最后已知良好值而非使启动崩溃。

### `static Future<void> start()` <a id="start"></a>
- **种类：** `LocalApiServer` 的静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 83 行）
- **用途：** 本地 HTTP API 服务器在配置中启用且允许绑定 时启动。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 调用 `loadConfig()` 和 `stop()`；成功时打开 `shelf_io` 监听器并更新 `_server`/`_port`；失败或拒绝时设 `_lastError`（`'credentials_required'` 或捕获异常的 `toString()`）。
- **算法：**
  1. `loadConfig()`，然后 `stop()`（关闭任何先前打开监听器）并清除 `_lastError`。
  2. `_enabled` 为 false 时立即返回。
  3. 计算 `isNonLoopback`：`_listenAddress == '0.0.0.0'`，或它既非 `'localhost'` 也非 `'127.0.0.1'` 时为 true。非回环且 `_hasCredentials` 为 false 时设 `_lastError = 'credentials_required'` 并在不绑定下返回。
  4. 否则调用 `shelf_io.serve(_buildHandler(), _bindAddress(), _port)`；成功时存储服务器和实际绑定端口（`_server!.port`——`_port` 为 `0` 时相关）；异常时存储 `_lastError` 并打印诊断行。
- **用法：**
  ```dart
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await LocalApiServer.start();
  }
  ```
  （`lib/main.dart`，启动序列。）
- **备注：** 任何非 `localhost`/`127.0.0.1` 的监听地址（含特定局域网 IP）被当作非回环，除非 `apiUsername` 和 `apiPassword` 都设置否则拒绝——见 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api)。可安全重复调用；它总是先停止任何先前监听器。

### `static Future<void> stop()` <a id="stop"></a>
- **种类：** `LocalApiServer` 的静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 114 行）
- **用途：** 关闭活动 HTTP 监听器（如有）。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 强制关闭 `_server` 并把它设为 `null`。
- **算法：** `await _server?.close(force: true); _server = null;`
- **用法：**
  ```dart
  await LocalApiServer.stop();
  ```
  （`test/local_api_server_test.dart`，`tearDown`；也设置页用户禁用 API 切换时。）
- **备注：** 无服务器运行时（`_server` 已 `null`）可安全调用。

### `static Future<void> restart()` <a id="restart"></a>
- **种类：** `LocalApiServer` 的静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 124 行）
- **用途：** 从存储重新加载 API 配置并用新设置重启监听器。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 与 `loadConfig()` + `start()` 组合相同。
- **算法：** `await loadConfig(); await start();`——注意 `start()` 自己也先调用 `loadConfig()`，因此配置被加载两次；因 `loadConfig()` 幂等而无害。
- **用法：**
  ```dart
  await LocalApiServer.restart();
  ```
  （`lib/features/settings/views/settings_page.dart`，在 API 设置对话框保存新端口/地址/凭据后。）
- **备注：** 无。

### `static Handler buildHandlerForTesting({String? username, String? password})` <a id="buildhandlerfortesting"></a>
- **种类：** `LocalApiServer` 的静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 134 行）
- **用途：** 构建生产中使用的相同请求处理器，带直接注入凭据，供组件/单元测试不经 `loadConfig()` 使用。
- **输入：** 可选 `username`/`password`。
- **返回：** `Handler`。
- **副作用：** 配置处理器时作为副作用覆盖静态 `_username`/`_password` 字段。
- **算法：** 从参数分配 `_username`/`_password`，然后返回 `_buildHandler()`。
- **用法：**
  ```dart
  handler = LocalApiServer.buildHandlerForTesting(
    username: 'api',
    password: 'secret',
  );
  ```
  （`test/local_api_server_test.dart`，Basic Auth 测试 case。）
- **备注：** 不打开真实 `HttpServer`——返回 `Handler` 在测试中直接对合成 `Request` 对象调用。

### `static Handler _buildHandler()` <a id="_buildhandler"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 145 行）
- **用途：** 构建 Shelf 路由器（全部 16 条路由）并把它包进 CORS / 认证 / 错误中间件管线。
- **输入：** 无。
- **返回：** `Handler`。
- **副作用：** 无（纯构造）。
- **算法：**
  1. 创建 `Router` 并把 `GET /ping`、七个 `/todo/*` 路由、六个 `/finance/*` 路由和三个 `/weight/*` 路由注册到其 `_handleXxx` 方法（完整端点列表见 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api)）。
  2. 用 `Pipeline().addMiddleware(_corsMiddleware()).addMiddleware(_authMiddleware()).addMiddleware(_errorMiddleware()).addHandler(router.call)` 包裹——CORS 最外层运行，然后认证、然后错误处理、然后路由器。
- **用法：** 从 `start()`（真实监听器）和 `buildHandlerForTesting()`（测试内存处理器）调用，使两条路径共享相同路由/中间件行为。
- **备注：** 中间件顺序重要：CORS 页头/`OPTIONS` 短路在认证检查前发生，因此预检请求从不需要凭据。

### `static InternetAddress _bindAddress()` <a id="_bindaddress"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 179 行）
- **用途：** 把配置的 `_listenAddress` 字符串翻译为适合 `shelf_io.serve` 的 `InternetAddress`。
- **输入：** 无（读取 `_listenAddress`）。
- **返回：** `InternetAddress`。
- **副作用：** 无。
- **算法：** `'0.0.0.0'` → `InternetAddress.anyIPv4`；`'localhost'` 或 `'127.0.0.1'` → `InternetAddress.loopbackIPv4`；任何其他 → `InternetAddress(_listenAddress, type: any)`（解析为字面数字地址）。
- **用法：** 打开监听器时从 `start()` 调用一次。
- **备注：** `'localhost'` 必须特判为 `loopbackIPv4`，因为 `InternetAddress('localhost')` 不是有效数字地址字面量且会抛。

### `static Future<Response> _handlePing(Request request)` <a id="_handleping"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 194 行）
- **用途：** 应答 `GET /ping`，使调用方检查 API 可达且已认证。
- **输入：** `request`（路由外未用）。
- **返回：** `Future<Response>`。
- **副作用：** 无。
- **算法：** 返回 `_json({'status': 'ok'})`。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/ping', _handlePing);`
- **备注：** 无。

### `static Future<Response> _handleTodoList(Request request)` <a id="_handletodolist"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 205 行）
- **用途：** 实现 `GET /todo/list?date=YYYY-MM-DD`——那天可见任务的扁平数组。
- **输入：** `request` 查询 `date`（默认现在）和可选 `type`。
- **返回：** `Future<Response>`。
- **副作用：** 读取 todo 存储（`TodoStorage.load()`）。
- **算法：** 解析 `date`；加载 todo 数据（无则空数组）；委托 `_visibleTodoTasks(data, date, typeStr: typeStr)` 并把结果包进 `_json`。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/todo/list', _handleTodoList);`
- **备注：** 返回裸 JSON 数组（非对象），为与既有 API 消费者向后兼容。

### `static Future<Response> _handleTodoDay(Request request)` <a id="_handletododay"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 218 行）
- **用途：** 实现 `GET /todo/day?date=YYYY-MM-DD`——日评分、总计和富化任务。
- **输入：** `request` 查询 `date`（默认现在）。
- **返回：** `Future<Response>`。
- **副作用：** 读取 todo 存储；无数据时替换为空内存 `TodoData`。
- **算法：**
  1. 加载数据，或不存在时构建空 `TodoData`（空列表、新鲜日志）。
  2. 经 `_visibleTodoTasks(data, date)` 计算可见任务；统计 `isCompleted == true`。
  3. 返回 `{date, score: data.dailyScores.scoreFor(date), total, completed, tasks}`。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/todo/day', _handleTodoDay);`
- **备注：** 缺失 todo 数据产生评分 `0` 和空任务列表而非 404，按 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api)。

### `static Future<Response> _handleTodoAdd(Request request)` <a id="_handletodoadd"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 245 行）
- **用途：** 实现 `POST /todo/add`——创建每日模板或一次性任务。
- **输入：** JSON 体：`title`（必填）、`type`（默认 `'workOnce'`）、可选 `dueDate`、`scheduledDate`、`reminderTime`、`note`、`emoji`、`subtasks`、`recurrence`。
- **返回：** `Future<Response>`。
- **副作用：** 写 todo 存储（`TodoStorage.save`）。
- **算法：**
  1. 解析体；缺失/无效 JSON、缺失/空 `title`、未知 `type` 或任何提供的日期/重复字段无法解析时 400。
  2. 构建 `Task`；`TaskType.daily` 时解析日期成为 `startDate`（非 `scheduledDate`）且 `recurrence` 被强制 `null`；其他类型时解析日期成为 `scheduledDate`（默认现在）且 `recurrence` 保留。
  3. 加载既有数据（或空 `TodoData`）；经 `_todoDataWith` 把新任务追加进 `dailyTemplates` 或 `oneTimeTasks`；保存。
  4. 返回 `{success: true, id, task: _todoTaskJson(task)}`。
- **用法：**
  ```dart
  final res = await handler(_request('POST', '/todo/add', body: {'title': 'Test task'}));
  ```
  （`test/local_api_server_test.dart`。）
- **备注：** 每日模板 `type` 刻意不能携带 `recurrence`——每日任务按定义已每天重复。

### `static Future<Response> _handleTodoComplete(Request request)` <a id="_handletodocomplete"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 310 行）
- **用途：** 实现 `POST /todo/complete`——完成/重开任务或其子任务之一，并可选生成下一次重复实例。
- **输入：** JSON 体：`id`（必填）、可选 `subtaskId`、`completed`（默认 `true`）、`createNextRecurrence`、`date`（默认现在）。
- **返回：** `Future<Response>`。
- **副作用：** 写 todo 存储；切换日期范围每日日志条目或修改一次性任务完成字段。
- **算法：**
  1. 解析体；缺失/无效 JSON、缺失 `id` 或无效 `date` 时 400。
  2. 加载数据；无则 404。
  3. `id` 匹配**每日模板**时：对 `subtaskId`，未知则 404，否则当前状态不同于 `completed` 时 `dailyLog.toggleSubtask(date, subtaskId)`；整个任务在相同仅-变化-才-切规则下 `dailyLog.toggle(date, id)`。保存并返回 `{success: true}`。
  4. 否则找匹配**一次性任务**；未找到 404。
  5. 对 `subtaskId`：未知则 404，否则在该子任务上 `copyWith(isCompleted: completed)` 并经 `_copyOneTimeTask(existing, subtasks: ...)` 重建任务。
  6. 否则经 `_copyOneTimeTask(existing, isCompleted: completed, completedDate: completed ? now : null)` 重建任务。这从不完整 → 完成转变、`createNextRecurrence` 为 true 且任务有 `recurrence` 时：计算 `nextDate = recurrence.nextDate(scheduledDate ?? date)`、构建新鲜 `Task`（相同标题/备注/emoji/类型/提醒，子任务重置不完整，存在时 `dueDate` 按相同重复前进）、追加它、一起保存更新和新任务，并带 `{success: true, nextTaskId, nextScheduledDate}` 提前返回。
  7. 未提前返回时保存更新一次性任务列表并返回 `{success: true}`。
- **用法：**
  ```dart
  await handler(_request('POST', '/todo/complete', body: {'id': taskId, 'completed': true}));
  ```
  （`test/local_api_server_test.dart`，todo 生命周期测试。）
- **备注：** 重复分支是本文件最复杂的路径——只在真实完成转变（而非重新完成已完成任务）且只对一次性任务触发，因为每日模板经每日日志隐式重复。

### `static Future<Response> _handleTodoScore(Request request)` <a id="_handletodoscore"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 409 行）
- **用途：** 实现 `POST /todo/score`——为日期设置日评分。
- **输入：** JSON 体：`score`（必填数字）、可选 `date`（默认现在）。
- **返回：** `Future<Response>`。
- **副作用：** 写 todo 存储。
- **算法：** 验证 `score` 是数字且 `date`（若给）可解析；加载/创建数据；`data.dailyScores.setScore(date, scoreValue.round())`；保存；返回结果 `{success, date, score}`（getter 经 `scoreFor(date)` 重读，它钳制到模型 -5..5 范围）。
- **用法：**
  ```dart
  await handler(_request('POST', '/todo/score', body: {'score': 3}));
  ```
  （`test/local_api_server_test.dart`。）
- **备注：** 响应回显 `data.dailyScores.scoreFor(date)` 而非原始输入，因此调用方看到的反映钳制。

### `static Future<Response> _handleTodoStats(Request request)` <a id="_handletodostats"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 440 行）
- **用途：** 实现 `GET /todo/stats`——今天的总/完成/过期计数。
- **输入：** `request`（路由外未用）。
- **返回：** `Future<Response>`。
- **副作用：** 读取 todo 存储。
- **算法：**
  1. 无数据时三个计数器全部返回零。
  2. 经 `_visibleTodoTasks` 计算今天可见任务；统计完成的。
  3. 统计不完整、有 `dueDate` 且截止日期键排今天键之前的一次性任务。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/todo/stats', _handleTodoStats);`
- **备注：** 为与既有插件/脚本兼容保留历史 snake_case 响应键（`today_total`、`today_completed`、`overdue`）。

### `static Future<Response> _handleFinanceSummary(Request request)` <a id="_handlefinancesummary"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 472 行）
- **用途：** 实现 `GET /finance/summary?month=yyyy-MM`——一个月的转换收入/支出/余额、总资产、逐账户余额和逐类别总计。
- **输入：** `request` 查询 `month`（默认当前月）。
- **返回：** `Future<Response>`。
- **副作用：** 读取财务和汇率存储。
- **算法：**
  1. 无财务数据时返回形状如正常响应的归零摘要。
  2. 对 `[monthStart, monthEnd)` 内每笔交易，用交易时生效的汇率**快照**（`rateData.ratesAt(tx.rateSnapshotId)`）转换其金额；只对收入和支出交易累积 `income`/`expense` 和逐类别总计（经 `_addCategoryTotal`）——转账跳过。
  3. 对每个账户计算其余额（`accountBalance`）并用**当前**汇率（`rateData.currentRates`）转换为默认货币——与步骤 2 不同的汇率来源，因为余额是时点快照而非历史交易。把转换余额求和进 `total_assets`。
  4. 按金额降序排序类别总计；取前 5 个支出类型条目作为 `top_expense_categories`。
- **用法：**
  ```dart
  final res = await handler(_request('GET', '/finance/summary?month=2026-07'));
  ```
  （`test/local_api_server_test.dart`，财务摘要测试。）
- **备注：** 历史交易转换用交易上存储的汇率快照；账户余额转换总是用今天汇率——混用会静默对 `income`/`expense` 误报 `total_assets`。

### `static Future<Response> _handleFinanceAccounts(Request request)` <a id="_handlefinanceaccounts"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 576 行）
- **用途：** 实现 `GET /finance/accounts?type=...`——省略卡机密 的账户详情。
- **输入：** `request` 查询可选 `type`（`AccountType` 名）。
- **返回：** `Future<Response>`。
- **副作用：** 读取财务和汇率存储。
- **算法：** 给定时验证 `type`（未知 400）；按类型过滤账户；对每个计算余额/转换余额并经 `_accountJson` 序列化。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/finance/accounts', _handleFinanceAccounts);`
- **备注：** 依赖 `_accountJson` 把 `securityCode`/卡号/有效期排除在响应外。

### `static Future<Response> _handleFinanceCategories(Request request)` <a id="_handlefinancecategories"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 611 行）
- **用途：** 实现 `GET /finance/categories?type=expense|income|transfer`。
- **输入：** `request` 查询可选 `type`（`TransactionType` 名）。
- **返回：** `Future<Response>`。
- **副作用：** 读取财务存储。
- **算法：** 给定时验证 `type`（未知 400）；按类型过滤类别；把每个经 `_categoryJson` 映射。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/finance/categories', _handleFinanceCategories);`
- **备注：** 支持转账类型类别，因为底层模型允许它们。

### `static Future<Response> _handleFinanceTransactions(Request request)` <a id="_handlefinancetransactions"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 632 行）
- **用途：** 实现带分页和多个过滤器的 `GET /finance/transactions`。
- **输入：** `request` 查询 `limit`（默认 20，钳制 0..200）、`offset`（默认 0，钳制 0..1,000,000）、可选 `type`、`month`（覆盖 `startDate`/`endDate`）、`startDate`/`start`、`endDate`/`end`、`accountId`、`categoryId`。
- **返回：** `Future<Response>`。
- **副作用：** 读取财务存储。
- **算法：**
  1. 给定时验证 `type`。
  2. 解析日期范围：显式 `month` 总是胜出并设 `[monthStart, monthStart+1 month)`；否则 `startDate`/`start` 和 `endDate`/`end` 用作包含下界和（非月范围）包含上界。
  3. 按类型、`accountId`（匹配 `accountId` 或 `toAccountId` 任一）、`categoryId` 和解析日期范围过滤交易；最新优先排序。
  4. 为账户/类别构建 id 键控查找映射；跳过 `offset`、取 `limit`，把每个幸存交易带查找映射经 `_transactionJson` 映射。
- **用法：**
  ```dart
  final res = await handler(_request('GET', '/finance/transactions?limit=5'));
  ```
  （`test/local_api_server_test.dart`。）
- **备注：** 返回裸 JSON 数组，匹配 `_handleTodoList` 的向后兼容选择。

### `static Future<Response> _handleFinanceAddTransaction(Request request)` <a id="_handlefinanceaddtransaction"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 699 行）
- **用途：** 实现带完整字段验证（含转账）的 `POST /finance/add_transaction`。
- **输入：** JSON 体：`type`（必填）、`amount`（必填正）、`accountId`（必填，必须存在）、可选 `categoryId`（若给必须存在且匹配 `type`）、转账的 `toAccountId`（必填，必须存在、必须不同于 `accountId`）、可选 `toAmount`（若给正）、可选 `currency`/`toCurrency`、可选 `date`、可选 `note`。
- **返回：** `Future<Response>`。
- **副作用：** 写财务存储。
- **算法：**
  1. 验证 `type`、`amount`、`accountId`/账户查找、`categoryId`/类别查找 + 类型匹配，和（转账）`toAccountId`/目标查找 + 不同性——第一个失败处返回 400/404。
  2. 验证可选 `toAmount` 和 `date`。
  3. 读取当前汇率快照 id（空时 `null`）。
  4. 构建 `Transaction`：除非给显式非空 `currency`（修剪 + 大写）否则 `currency` 默认源账户货币；转账时填充 `toAccountId`/`toAmount`/`toCurrency`（`toCurrency` 默认目标账户货币），非转账留 `null`。
  5. 把交易追加进 `FinanceData` 副本（逐字保留每个其他字段）并保存。
  6. 返回 `{success: true, id, transaction: _transactionJson(tx)}`。
- **用法：**
  ```dart
  await handler(_request('POST', '/finance/add_transaction', body: {
    'type': 'expense',
    'amount': 12.5,
    'accountId': accountId,
  }));
  ```
  （`test/local_api_server_test.dart`，财务添加交易测试。）
- **备注：** 存储当前汇率快照 id（非计算转换金额）正是让 `_handleFinanceSummary` 稍后用记录时当前的汇率转换此交易的东西。

### `static Future<Response> _handleFinanceSubscriptions(Request request)` <a id="_handlefinancesubscriptions"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 807 行）
- **用途：** 实现带解析账户和类别名称的 `GET /finance/subscriptions?includeInactive=true`。
- **输入：** `request` 查询可选 `includeInactive`（`true`/`1`/`yes`）。
- **返回：** `Future<Response>`。
- **副作用：** 读取财务存储。
- **算法：** 除非 `includeInactive` 否则过滤订阅到激活的；构建账户/类别 id 键控查找映射；把每个订阅内联映射为 JSON 对象（不经共享 `_xxxJson` 辅助），包括解析 `accountName`/`categoryName`。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/finance/subscriptions', _handleFinanceSubscriptions);`
- **备注：** 与其他序列化器不同，此端点的 JSON 形态内联构建而非经专用 `_subscriptionJson` 辅助——本文件别处无可为订阅链接的可复用序列化器。

### `static Future<Response> _handleWeightList(Request request)` <a id="_handleweightlist"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 853 行）
- **用途：** 实现 `GET /weight/list?limit=n`——带有效（继承）测量的最近体重记录。
- **输入：** `request` 查询 `limit`（默认 30，钳制 0..200）。
- **返回：** `Future<Response>`。
- **副作用：** 读取体重存储。
- **算法：** 按 `datetime` 最新优先排序记录；取 `limit`；把每个经 `_weightRecordJson(r, data)` 映射。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/weight/list', _handleWeightList);`
- **备注：** 返回裸 JSON 数组。

### `static Future<Response> _handleWeightAdd(Request request)` <a id="_handleweightadd"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 869 行）
- **用途：** 实现 `POST /weight/add`——记录带可选身体成分和周长测量的新体重条目。
- **输入：** JSON 体：`weight`（必填正）、可选 `bodyFat`/`bustCm`/`waistCm`/`hipCm`（存在但不是正数时各自被 400 拒绝）、可选 `date`、可选 `notes`。
- **返回：** `Future<Response>`。
- **副作用：** 写体重存储。
- **算法：**
  1. 独立验证 `weight` 和每个提供的可选数字字段——键完全缺席时各为 `null`，但键存在且值非正或非数字时 400 错误。
  2. 给定时验证 `date`。
  3. 构建 `WeightRecord`；把它追加进（加载或空）`WeightData`，逐字保留每个其他设置字段。
  4. 保存；返回 `{success: true, id, record: _weightRecordJson(record, next)}`。
- **用法：**
  ```dart
  await handler(_request('POST', '/weight/add', body: {'weight': 65.5}));
  ```
  （`test/local_api_server_test.dart`，体重添加测试。）
- **备注：** 可选字段"缺席 vs 无效"区分镜像 `_handleTodoAdd` 的日期处理：`body['x'] != null && parsed == null` 是复用的"存在但无效"模式。

### `static Future<Response> _handleWeightStats(Request request)` <a id="_handleweightstats"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 929 行）
- **用途：** 实现 `GET /weight/stats`——最新/平均/趋势加 BMI、腰臀比和有效测量。
- **输入：** `request`（路由外未用）。
- **返回：** `Future<Response>`。
- **副作用：** 读取体重存储。
- **算法：**
  1. 无记录时返回全 null/`'unknown'` 形态（数据存在时仍包含 `height`）。
  2. 最新优先排序记录；`latest` = 最近体重；`avg_7d`/`avg_30d` = 距现在 7/30 天内记录的平均体重（窗口为空 `null`）。
  3. 趋势（只在 30 天窗口至少 4 条记录时计算）：把窗口分成两半（`recent` = 降序列表前半，即更近一半；`older` = 后半）；平均各半；`diff = avgRecent - avgOlder`；`diff > 0.3` → `'up'`、`diff < -0.3` → `'down'`、否则 `'stable'`。少于 4 条记录留下 `trend = 'unknown'`。
  4. 经 `WeightData.effectiveMeasurementsUpTo(records, latestRecord.datetime)` 计算 `effective` 测量，然后对 `height`/`latest`/`effective` 经 `WeightData.calculateBMI`/`calculateWaistHipRatio` 计算 `bmi`/`waistHipRatio`。
- **用法：** 从 `_buildHandler()` 路由：`router.get('/weight/stats', _handleWeightStats);`
- **备注：** 保留历史响应键（`latest`、`avg_7d`、`avg_30d`、`trend`）同时添加新字段（`bmi`、`waistHipRatio`、`height`、`bodyFat`、`latestRecord`、`effectiveMeasurements`）——有效测量和宽限窗口逻辑在存储层如何表现见 [体重](../../../features/weight.md)。

### `static List<Map<String, dynamic>> _visibleTodoTasks(TodoData data, DateTime date, {String? typeStr})` <a id="_visibletodotasks"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1008 行）
- **用途：** 计算 `date` 上应可见的任务列表（每日模板 + 一次性任务），序列化为 JSON，被 `_handleTodoList`、`_handleTodoDay` 和 `_handleTodoStats` 共享。
- **输入：** `data`、`date`、可选 `typeStr` 过滤（对照 `task.type.name` 匹配）。
- **返回：** `_todoTaskJson` 结果的 `List<Map<String, dynamic>>`。
- **副作用：** 无。
- **算法：**
  1. 对每个每日模板：`typeStr` 不匹配则跳过，`task.type != daily` 则跳过，`date` 早于任务 `startDate`/`createdDate` 则跳过，任务在 `date` 或之前被软删除（`deletedDate`）则跳过；否则发出 `_todoTaskJson`，`isCompleted` 从 `data.dailyLog.isCompleted(date, task.id)` 读取。
  2. 对每个一次性任务：`typeStr` 不匹配则跳过，每日类型任务跳过（上面处理）；设了 `scheduledDate` 时，`date` 早于它则跳过、完成的任务除非 `date` 等于其安排日期否则跳过、安排日期相对 `date` 在将来的不完整任务跳过；否则发出带 `isCompleted: task.isCompleted` 的 `_todoTaskJson`。
- **用法：**
  ```dart
  return _json(_visibleTodoTasks(data, date, typeStr: typeStr));
  ```
  （`_handleTodoList`，同文件。）
- **备注：** 无 `scheduledDate` 的不完整一次性任务，或其安排日期已过仍不完整的，"顺延"并在较后日期保持可见——匹配被 `_handleTodoStats` 的 `overdue` 计数器测试的既有过期顺延行为。

### `static Map<String, dynamic> _todoTaskJson(Task task, {DateTime? date, bool? isCompleted, DailyCompletionLog? dailyLog})` <a id="_todotaskjson"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1058 行）
- **用途：** 把 `Task`（加其子任务）序列化为 API 的 JSON 任务形态。
- **输入：** `task`；日期范围完成的可选 `date`/`isCompleted`/`dailyLog`。
- **返回：** `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 发出 `id`/`title`/`note`/`emoji`/`type.name`；`isCompleted` 给定时用传入值，否则 `task.isCompleted`；每个子任务的 `isCompleted` 在 `date` 和 `dailyLog` 都提供时来自 `dailyLog.isSubtaskCompleted(date, subtask.id)`，否则来自 `subtask.isCompleted`；所有 `DateTime` 字段是 ISO-8601 字符串或 `null`；`recurrence` 是 `task.recurrence?.toJson()`。
- **用法：**
  ```dart
  results.add(_todoTaskJson(task, date: date, isCompleted: ..., dailyLog: data.dailyLog));
  ```
  （`_visibleTodoTasks`，同文件，每日模板。）
- **备注：** `date`/`dailyLog` 参数存在正为让每日模板的子任务完成逐日读取，而非从子任务上的单个存储标志。

### `static Map<String, dynamic> _accountJson(Account account, {double? balance, double? convertedBalance, required String defaultCurrency})` <a id="_accountjson"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1100 行）
- **用途：** 序列化 `Account` 供 API 输出，同时省略敏感卡字段。
- **输入：** `account`；可选 `balance`/`convertedBalance`；必填 `defaultCurrency`。
- **返回：** `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 发出 id/type/bankOrApp/name/currency/emoji/imagePath/费用免除字段和 `modifiedAt`；只在提供时条件包含 `balance`/`convertedBalance`（经 `_round` 舍入）。
- **用法：**
  ```dart
  return _accountJson(account, balance: balance, convertedBalance: convertedBalance,
      defaultCurrency: finData.defaultCurrency);
  ```
  （`_handleFinanceAccounts`，同文件。）
- **备注：** `securityCode`、卡号和有效期在这里刻意绝不被 `account` 读取——见 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api)。

### `static Map<String, dynamic> _categoryJson(Category category)` <a id="_categoryjson"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1129 行）
- **用途：** 序列化 `Category` 供 API 输出。
- **输入：** `category`。
- **返回：** `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 发出 id/name/emoji/`type.name`/`icon.toJson()`/`modifiedAt`。
- **用法：**
  ```dart
  finData.categories.where(...).map(_categoryJson).toList()
  ```
  （`_handleFinanceCategories`，同文件。）
- **备注：** 包含图标元数据，使 API 消费者能渲染与应用相同的类别图标。

### `static Map<String, dynamic> _transactionJson(Transaction tx, {Map<String, Account> accountsById = const {}, Map<String, Category> categoriesById = const {}})` <a id="_transactionjson"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1145 行）
- **用途：** 序列化 `Transaction`，提供查找映射时解析人类可读账户/类别名称。
- **输入：** `tx`；可选 `accountsById`/`categoriesById`（默认空）。
- **返回：** `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 发出交易字段加从查找映射解析的 `accountName`/`toAccountName`/`categoryName`（引用 id 缺失或未提供映射时 `null`）。
- **用法：**
  ```dart
  'transaction': _transactionJson(tx),
  ```
  （`_handleFinanceAddTransaction`，同文件——无查找映射调用，因此名称在那里为 `null`；`_handleFinanceTransactions` 传两个映射。）
- **备注：** 设计为无查找映射调用时优雅降级（如刚创建交易后、需要名称前）。

### `static Map<String, dynamic> _weightRecordJson(WeightRecord record, WeightData data)` <a id="_weightrecordjson"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1180 行）
- **用途：** 带显示有效测量序列化 `WeightRecord`。
- **输入：** `record`、`data`（完整记录集，计算继承需要）。
- **返回：** `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 计算 `WeightData.effectiveMeasurementsUpTo(data.records, record.datetime)`；发出 weight/bodyFat/bustCm/waistCm/hipCm/`effectiveMeasurements`（经 `_measurementsJson`）/`date`（`yyyy-MM-dd`）/`datetime`/notes/`modifiedAt`。
- **用法：**
  ```dart
  sorted.take(limit).map((r) => _weightRecordJson(r, data)).toList()
  ```
  （`_handleWeightList`，同文件。）
- **备注：** 有效测量仅为显示计算——即使值从较早记录继承，也没有任何东西写回 `record`。

### `static Map<String, dynamic> _measurementsJson(EffectiveWeightMeasurements measurements)` <a id="_measurementsjson"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1208 行）
- **用途：** 把 `EffectiveWeightMeasurements` 值序列化为 JSON。
- **输入：** `measurements`。
- **返回：** 带 `bustCm`/`waistCm`/`hipCm` 的 `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 直接字段透传，无计算。
- **用法：**
  ```dart
  'effectiveMeasurements': _measurementsJson(effective),
  ```
  （`_handleWeightStats` 和 `_weightRecordJson`，同文件。）
- **备注：** `null` 字段意味着截至参考日期该测量无正值存在——与零不同义。

### `static TodoData _todoDataWith(TodoData data, {List<Task>? dailyTemplates, List<Task>? oneTimeTasks})` <a id="_tododatawith"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1225 行）
- **用途：** 克隆 `TodoData`，可选替换其 `dailyTemplates`/`oneTimeTasks` 列表。
- **输入：** `data`；可选替换 `dailyTemplates`/`oneTimeTasks`。
- **返回：** `TodoData`。
- **副作用：** 无。
- **算法：** 给定时用替换列表否则用原始列表构建新 `TodoData`，并逐字复制每个其他字段（`dailyLog`、`dailyScores`、两个提醒时/分对、排序模式/自定义顺序、`settingsModifiedAt`）。
- **用法：**
  ```dart
  final next = type == TaskType.daily
      ? _todoDataWith(data, dailyTemplates: [...data.dailyTemplates, task])
      : _todoDataWith(data, oneTimeTasks: [...data.oneTimeTasks, task]);
  ```
  （`_handleTodoAdd`，同文件。）
- **备注：** 存在是因为本地 API 每次只需替换两个任务列表之一，不像通用 `copyWith`。

### `static Task _copyOneTimeTask(Task task, {bool? isCompleted, DateTime? completedDate, List<SubTask>? subtasks})` <a id="_copyonetimetask"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1250 行）
- **用途：** 复制一次性 `Task`，允许 `completedDate` 显式清除为 `null`。
- **输入：** `task`；可选 `isCompleted`/`completedDate`/`subtasks` 覆盖。
- **返回：** `Task`。
- **副作用：** 无。
- **算法：** 从 `task` 每个字段构造新 `Task`，代入给定覆盖，总是盖章 `modifiedAt: DateTime.now().toUtc()`。
- **用法：**
  ```dart
  updated = _copyOneTimeTask(existing, isCompleted: completed,
      completedDate: completed ? DateTime.now() : null);
  ```
  （`_handleTodoComplete`，同文件。）
- **备注：** 存在正因 `Task.copyWith` 无法为 `completedDate` 传显式 `null`（重开任务必须清除它）——普通 `copyWith(completedDate: null)` 在通常 copyWith 约定下与"不改变此字段"无法区分。

### `static void _addCategoryTotal(Map<String, _CategoryTotal> totals, Transaction tx, double converted)` <a id="_addcategorytotal"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1281 行）
- **用途：** 把转换交易金额累积进 `type:categoryId` 键控总计映射。
- **输入：** `totals`（被修改）、`tx`、`converted`（已货币转换金额）。
- **返回：** `void`。
- **副作用：** 原地修改 `totals`。
- **算法：** 键 = `'${tx.type.name}:${tx.categoryId ?? ''}'`；缺席时插入 `count: 1` 的新 `_CategoryTotal`；否则用 `existing.add(converted)` 替换。
- **用法：**
  ```dart
  _addCategoryTotal(categoryTotals, tx, converted);
  ```
  （`_handleFinanceSummary`，同文件，收入和支出交易。）
- **备注：** 空 `categoryId`（`''`）代表未分类收入/支出，作为自己的桶保留而非与命名类别合并。

### `static DateTime? _queryMonth(Request request)` <a id="_querymonth"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1305 行）
- **用途：** 把 `?month=yyyy-MM` 查询参数解析为该月第一天。
- **输入：** `request`。
- **返回：** `DateTime?`。
- **副作用：** 无。
- **算法：** 按 `-` 拆分；要求恰好 2 部分、都可整数解析、`month` 在 1..12；返回 `DateTime(year, month)`，否则 `null`。
- **用法：**
  ```dart
  final monthStart = _queryMonth(request) ?? DateTime(now.year, now.month);
  ```
  （`_handleFinanceSummary`，同文件。）
- **备注：** 缺席或格式错误 `month` 返回 `null`，使调用方能提供自己的默认而非报错。

### `static int _queryInt(Request request, String name, {required int defaultValue})` <a id="_queryint"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1321 行）
- **用途：** 解析命名整数查询参数，回退默认。
- **输入：** `request`、`name`、`defaultValue`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** `int.tryParse(queryParameters[name] ?? '') ?? defaultValue`。
- **用法：**
  ```dart
  final limit = _queryInt(request, 'limit', defaultValue: 20).clamp(0, 200);
  ```
  （`_handleFinanceTransactions`，同文件。）
- **备注：** 调用方负责把结果钳制到合理范围；此辅助自己不加边界。

### `static bool _queryBool(Request request, String name)` <a id="_querybool"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1335 行）
- **用途：** 解析命名布尔式查询参数。
- **输入：** `request`、`name`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 小写值；当且仅当等于 `'true'`、`'1'` 或 `'yes'` 时为 true。
- **用法：**
  ```dart
  final includeInactive = _queryBool(request, 'includeInactive');
  ```
  （`_handleFinanceSubscriptions`，同文件。）
- **备注：** 任何其他值（含缺席）为 `false`——无错误路径。

### `static DateTime? _queryDate(Request request, String name)` <a id="_querydate"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1345 行）
- **用途：** 解析命名 ISO 式日期查询参数。
- **输入：** `request`、`name`。
- **返回：** `DateTime?`。
- **副作用：** 无。
- **算法：** 存在且非空时 `DateTime.tryParse(value)`，否则 `null`。
- **用法：**
  ```dart
  final date = _queryDate(request, 'date') ?? DateTime.now();
  ```
  （`_handleTodoList`，同文件。）
- **备注：** 用 Dart 内置 ISO-8601 兼容解析器；无自定义格式处理。

### `static DateTime? _optionalBodyDate(Map<String, dynamic> body, String name)` <a id="_optionalbodydate"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1356 行）
- **用途：** 从解码 JSON 请求体解析命名日期字段。
- **输入：** `body`、`name`。
- **返回：** `DateTime?`。
- **副作用：** 无。
- **算法：** 键缺失 `null`；值不是非空 `String` `null`；否则 `DateTime.tryParse(value.trim())`。
- **用法：**
  ```dart
  final dueDate = _optionalBodyDate(body, 'dueDate');
  if (body['dueDate'] != null && dueDate == null) return _error(400, 'invalid dueDate');
  ```
  （`_handleTodoAdd`，同文件——本文件每个 POST 处理器使用的重复"存在但无效"检查模式。）
- **备注：** 日期字段的非 `String` JSON 值（如数字）被当作与无效字符串相同，不强转。

### `static double? _positiveDouble(Object? value)` <a id="_positivedouble"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1368 行）
- **用途：** 从无类型 JSON 输入解析必填严格正数值。
- **输入：** `value`（预期 `num` 或数字 `String`）。
- **返回：** `double?`（失败 `null`）。
- **副作用：** 无。
- **算法：** 按运行时类型 `switch`：`num` → `.toDouble()`；`String` → 对修剪文本 `double.tryParse`；其他 → `null`。然后拒绝 `null` 或 `<= 0`。
- **用法：**
  ```dart
  final amount = _positiveDouble(body['amount']);
  if (amount == null) return _error(400, 'valid amount is required');
  ```
  （`_handleFinanceAddTransaction`，同文件。）
- **备注：** 零与负数一起被拒绝——本文件通篇金额/体重/测量必须严格为正。

### `static double? _optionalPositiveDouble(Object? value)` <a id="_optionalpositivedouble"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1383 行）
- **用途：** 解析可选严格正数字段，缺席键当作 `null`。
- **输入：** `value`。
- **返回：** `double?`。
- **副作用：** 无。
- **算法：** `value == null` 时 `null`；否则委托 `_positiveDouble(value)`。
- **用法：**
  ```dart
  final bodyFat = _optionalPositiveDouble(body['bodyFat']);
  if (body['bodyFat'] != null && bodyFat == null) return _error(400, 'valid bodyFat is required');
  ```
  （`_handleWeightAdd`，同文件。）
- **备注：** "键缺席"（静默 `null`）与"键存在但无效"（400 错误）的区分由调用方比较 `body['x'] != null` 执行，不是此辅助自己。

### `static String? _optionalTrimmedString(Object? value)` <a id="_optionaltrimmedstring"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1393 行）
- **用途：** 解析可选字符串字段，修剪空白并把空白坍缩为 `null`。
- **输入：** `value`。
- **返回：** `String?`。
- **副作用：** 无。
- **算法：** 非 `String` `null`；否则修剪并修剪结果为空则返回 `null`，否则修剪字符串。
- **用法：**
  ```dart
  note: _optionalTrimmedString(body['note']),
  ```
  （`_handleTodoAdd`，同文件。）
- **备注：** 无。

### `static List<SubTask> _parseSubtasks(Object? value)` <a id="_parsesubtasks"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1404 行）
- **用途：** 把 JSON `subtasks` 数组解析为 `SubTask` 对象。
- **输入：** `value`（预期 `String` 和/或 `Map` 的 `List`）。
- **返回：** `List<SubTask>`（`value` 非 `List` 时为空）。
- **副作用：** 无。
- **算法：** 对每个项：裸 `String` 成为（修剪）标题且 `isCompleted: false`；`Map` 读取 `title`（修剪）和可选 `isCompleted`；产生空或缺失标题的任何项完全跳过。
- **用法：**
  ```dart
  subtasks: _parseSubtasks(body['subtasks']),
  ```
  （`_handleTodoAdd`，同文件。）
- **备注：** 同一数组中接受两种输入形态（普通字符串或 `{title, isCompleted}` 对象）——允许混合数组。

### `static TaskRecurrence? _parseRecurrence(Object? value)` <a id="_parserecurrence"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1428 行）
- **用途：** 把 JSON 重复对象解析为 `TaskRecurrence`。
- **输入：** `value`（预期 `{type, ...}`）。
- **返回：** `TaskRecurrence?`（任何结构问题 `null`）。
- **副作用：** 无。
- **算法：** `value` 为 `null` 或非 `Map` 时 `null`；把键规范化为 `String`；按 `type` 切换：`'everyNDays'` 需要正数字 `intervalDays` → `TaskRecurrence.everyNDays`；`'monthlyOnDay'` 需要正数字 `dayOfMonth` → `TaskRecurrence.monthlyOnDay`；`'yearlyOnMonthDay'` 需要正数字 `monthOfYear` 和 `dayOfMonth` → `TaskRecurrence.yearlyOnMonthDay`；任何其他 `type`（或匹配 case 的缺失/无效字段）返回 `null`。
- **用法：**
  ```dart
  final recurrence = _parseRecurrence(body['recurrence']);
  if (body['recurrence'] != null && recurrence == null) return _error(400, 'invalid recurrence');
  ```
  （`_handleTodoAdd`，同文件。）
- **备注：** API 只接受这三种重复形态——匹配 todo 模型暴露的 `TaskRecurrence` 工厂构造函数。

### `static TaskType? _taskTypeByName(String? name)` <a id="_tasktypebyname"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1459 行）
- **用途：** 从其 API 名称字符串解析 `TaskType` 枚举值。
- **输入：** `name`。
- **返回：** `TaskType?`。
- **副作用：** 无。
- **算法：** 线性扫描 `TaskType.values` 找匹配 `.name`；`name` 为 `null` 或无匹配时 `null`。
- **用法：**
  ```dart
  final type = _taskTypeByName(typeStr);
  if (type == null) return _error(400, 'invalid task type');
  ```
  （`_handleTodoAdd`，同文件。）
- **备注：** 未知/拼错类型名被拒绝而非静默默认。

### `static TransactionType? _transactionTypeByName(String? name)` <a id="_transactiontypebyname"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1472 行）
- **用途：** 从其 API 名称字符串解析 `TransactionType` 枚举值。
- **输入：** `name`。
- **返回：** `TransactionType?`。
- **副作用：** 无。
- **算法：** 与 `_taskTypeByName` 相同的线性扫描模式，对 `TransactionType.values`。
- **用法：**
  ```dart
  final type = typeStr == null ? null : _transactionTypeByName(typeStr);
  ```
  （`_handleFinanceCategories`，同文件。）
- **备注：** 无。

### `static AccountType? _accountTypeByName(String name)` <a id="_accounttypebyname"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1485 行）
- **用途：** 从其 API 名称字符串解析 `AccountType` 枚举值。
- **输入：** `name`（非可空，不同于上面两个兄弟）。
- **返回：** `AccountType?`。
- **副作用：** 无。
- **算法：** 相同线性扫描模式，对 `AccountType.values`。
- **用法：**
  ```dart
  final type = typeStr == null ? null : _accountTypeByName(typeStr);
  ```
  （`_handleFinanceAccounts`，同文件——调用方只在 `typeStr` 已知非 null 后调用它。）
- **备注：** 与 `_taskTypeByName`/`_transactionTypeByName` 不同，此辅助取非可空 `String`；调用方调用前自己守卫 null case。

### `static double _round(double value, {int digits = 2})` <a id="_round"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1497 行）
- **用途：** 为稳定 JSON 输出把 `double` 舍入到固定小数位。
- **输入：** `value`、`digits`（默认 2）。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** `double.parse(value.toStringAsFixed(digits))`——经十进制字符串往返而非直接二进制浮点算术。
- **用法：**
  ```dart
  'amount': _round(total.amount),
  ```
  （`_handleFinanceSummary`，同文件。）
- **备注：** 字符串往返避免在 API 响应中浮出二进制浮点噪声（如 `19.999999999998`）。

### `static double? _nullableRound(double? value, {int digits = 2})` <a id="_nullableround"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1506 行）
- **用途：** `_round` 的 `null` 安全包装。
- **输入：** `value`、`digits`（默认 2）。
- **返回：** `double?`。
- **副作用：** 无。
- **算法：** `value == null ? null : _round(value, digits: digits)`。
- **用法：**
  ```dart
  'bmi': _nullableRound(WeightData.calculateBMI(data.height, latest)),
  ```
  （`_handleWeightStats`，同文件。）
- **备注：** 无。

### `static Response _json(Object? data)` <a id="_json"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1515 行）
- **用途：** 把任何 JSON 兼容值编码为 `200 OK` 响应。
- **输入：** `data`。
- **返回：** `Response`。
- **副作用：** 无。
- **算法：** `Response.ok(jsonEncode(data), headers: {'Content-Type': 'application/json'})`。
- **用法：** 被本文件每个路由处理器用于构建成功响应，如 `_handlePing` 的 `return _json({'status': 'ok'});`。
- **备注：** 每个成功 API 响应都是 `application/json`，无例外。

### `static Response _error(int status, String message)` <a id="_error"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1525 行）
- **用途：** 用给定 HTTP 状态编码 JSON 错误响应。
- **输入：** `status`、`message`。
- **返回：** `Response`。
- **副作用：** 无。
- **算法：** `Response(status, body: jsonEncode({'error': message}), headers: {...json...})`。
- **用法：**
  ```dart
  if (title == null || title.isEmpty) return _error(400, 'title is required');
  ```
  （`_handleTodoAdd`，同文件；也用于 `_errorMiddleware` 的 `data_unreadable` 500。）
- **备注：** 错误体总是暴露单个 `error` 字符串键，绝无堆栈跟踪。

### `static Future<Map<String, dynamic>?> _parseBody(Request request)` <a id="_parsebody"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1536 行）
- **用途：** 读取并 JSON 解码请求体，容忍空或格式错误输入。
- **输入：** `request`。
- **返回：** `Future<Map<String, dynamic>?>`（空/格式错误体 `null`）。
- **副作用：** 消耗请求体流（`request.readAsString()`）。
- **算法：** 把体作为字符串读取；修剪后为空白返回 `null`；否则 `jsonDecode` 并转换为 `Map<String, dynamic>`；任何抛出异常（坏 JSON、错误顶层类型）被捕获转为 `null`。
- **用法：**
  ```dart
  final body = await _parseBody(request);
  if (body == null) return _error(400, 'invalid JSON body');
  ```
  （`_handleTodoAdd` 和本文件每个其他 POST 处理器。）
- **备注：** 顶层非对象的 JSON 体（如裸数组或数字）被当作与格式错误 JSON 相同，因为到 `Map<String, dynamic>` 的转换抛。

### `static Middleware _corsMiddleware()` <a id="_corsmiddleware"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1553 行）
- **用途：** 给每个响应添加宽松 CORS 页头并直接应答 `OPTIONS` 预检请求。
- **输入：** 无。
- **返回：** `Middleware`。
- **副作用：** 无（返回中间件在请求时有副作用，但构建它没有）。
- **算法：** 对 `OPTIONS` 请求立即返回 `Response.ok('', headers: _corsHeaders)`（完全跳过包裹处理器）；否则调用内层处理器并经 `.change(headers: ...)` 把 `_corsHeaders` 应用到其响应。
- **用法：** 在 `_buildHandler()` 中应用：`.addMiddleware(_corsMiddleware())`，作为最外层中间件。
- **备注：** `_corsHeaders` 允许任何源（`Access-Control-Allow-Origin: '*'`）——对回环绑定本地工具为何认为这可接受见 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api)。

### `static Middleware _authMiddleware()` <a id="_authmiddleware"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1576 行）
- **用途：** 执行本地 API 认证策略：配置凭据时 Basic 认证，否则仅回环。
- **输入：** 无。
- **返回：** `Middleware`。
- **副作用：** 构建时无。
- **算法：**
  1. 从 `shelf.io.connection_info` 读取调用方远程地址；缺失连接信息当作回环（`isLoopback = remoteAddr == null || remoteAddr.isLoopback`）。
  2. `_hasCredentials` 时：对**每个**请求要求有效 `Authorization: Basic ...` 页头（`_validateBasicAuth`），包括来自回环的——缺失/无效页头返回带 `WWW-Authenticate: Basic realm="MyDay API"` 页头的 `401`。
  3. 否则（`!_hasCredentials`）：用 `403`（"authentication required for non-localhost access"）拒绝非回环调用方；回环调用方免认证通过。
  4. 否则调用内层处理器。
- **用法：** 在 `_buildHandler()` 中应用：`.addMiddleware(_authMiddleware())`，在 CORS 后、错误中间件前。
- **备注：** 配置凭据时，即使 `127.0.0.1`/`localhost` 也需要——配置凭据不只是门控远程访问，它门控所有访问。见 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api)。

### `static bool get _hasCredentials` <a id="_hascredentials"></a>
- **种类：** `LocalApiServer` 的私有静态 getter
- **来源：** `lib/shared/services/local_api_server.dart`（第 1611 行）
- **用途：** 报告 API 用户名和密码是否都已配置且非空。
- **输入：** 无（读取 `_username`/`_password`）。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `_username != null && _username!.isNotEmpty && _password != null && _password!.isNotEmpty`。
- **用法：**
  ```dart
  if (isNonLoopback && !_hasCredentials) { _lastError = 'credentials_required'; return; }
  ```
  （`start()`，同文件；也门控 `_authMiddleware()` 中的分支。）
- **备注：** 只由空字符串组成的用户名或密码算"未配置"——这是 `start()` 非回环拒绝和 `_authMiddleware()` Basic-认证-vs-仅回环分支两者的单一真相源，使两者保持一致。

### `static bool _validateBasicAuth(String header)` <a id="_validatebasicauth"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1622 行）
- **用途：** 对照配置凭据验证 HTTP `Authorization: Basic ...` 页头。
- **输入：** `header`（原始页头值）。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 要求 `'Basic '` 前缀；base64 解码并 UTF-8 解码剩余；按 `:` 拆分；要求至少 2 部分；把 `parts[0]` 与 `_username`、`parts.sublist(1).join(':')`（重新连接任何额外冒号）与 `_password` 比较。任何解码异常被捕获并当作无效。
- **用法：**
  ```dart
  if (authHeader == null || !_validateBasicAuth(authHeader)) { ...401... }
  ```
  （`_authMiddleware`，同文件。）
- **备注：** 用 `:` 重新连接 `parts.sublist(1)` 意味着自身含冒号的密码被正确处理——只有第一个冒号拆分用户与密码。

### `static Middleware _errorMiddleware()` <a id="_errormiddleware"></a>
- **种类：** `LocalApiServer` 的私有静态方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1641 行）
- **用途：** 把路由处理器的未捕获异常转换为 JSON 错误响应，包括损坏存储文件的专用 `data_unreadable` 契约。
- **输入：** 无。
- **返回：** `Middleware`。
- **副作用：** 构建时无。
- **算法：** `try` 内层处理器；`TodoStorageException`、`WeightStorageException` 或 `FinanceStorageException` 时返回 `_error(500, 'data_unreadable')`；任何其他异常返回 `_error(500, 'internal error: $e')`。
- **用法：** 在 `_buildHandler()` 最内层应用：`.addMiddleware(_errorMiddleware())`，直接包裹路由器。
- **备注：** 这是 [平台说明 — 本地 HTTP API](../../../platform-notes.md#local-http-api) 文档化 `data_unreadable` 500 背后的机制：`*Storage.load()`/`save()` 调用在*既有*数据文件解析失败时抛类型化异常（缺失文件不是错误，用端点自己的空数据行为代替），POST 处理器在持久化任何变更前抛，因此写入绝不部分应用。

### `const _CategoryTotal({required this.categoryId, required this.type, required this.amount, required this.count})` <a id="_categorytotal-new"></a>
- **种类：** `_CategoryTotal` 的构造函数
- **来源：** `lib/shared/services/local_api_server.dart`（第 1671 行）
- **用途：** 构造不可变累积财务类别总计。
- **输入：** `categoryId`、`type`、`amount`、`count`（都必填）。
- **返回：** 新 `_CategoryTotal`。
- **副作用：** 无。
- **算法：** 直接字段赋值（`const` 构造函数，无逻辑）。
- **用法：**
  ```dart
  totals[key] = _CategoryTotal(categoryId: tx.categoryId ?? '', type: tx.type,
      amount: converted, count: 1);
  ```
  （`_addCategoryTotal`，同文件。）
- **备注：** `_CategoryTotal` 是仅在本文件内用于在序列化前累积 `_handleFinanceSummary` 逐类别总计的私有辅助类。

### `_CategoryTotal add(double value)` <a id="add"></a>
- **种类：** `_CategoryTotal` 的方法
- **来源：** `lib/shared/services/local_api_server.dart`（第 1683 行）
- **用途：** 返回把 `value` 加到运行金额且计数递增的新 `_CategoryTotal`。
- **输入：** `value`。
- **返回：** `_CategoryTotal`。
- **副作用：** 无（不可变——返回新实例）。
- **算法：** `_CategoryTotal(categoryId: categoryId, type: type, amount: amount + value, count: count + 1)`。
- **用法：**
  ```dart
  totals[key] = existing.add(converted);
  ```
  （`_addCategoryTotal`，同文件。）
- **备注：** `categoryId` 和 `type` 不变保留；只有 `amount` 和 `count` 累积。
