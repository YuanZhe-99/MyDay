# lib/features/finance/views/exchange_rates_page.dart

汇率列表/编辑页：显示每个配置的 `'FROM_TO'` 币种对及其汇率，让用户手动增/删/改对，并每天最多从实时 API 自动刷新一次。这是汇率历史的 UI 半边——持久化和快照历史模型在 [`ExchangeRateStorage`](../services/exchange_rate_storage.md)，实时获取客户端在 [`ExchangeRateApi`](../services/exchange_rate_api.md)。功能级概览见 [财务](../../../../features/finance.md#exchange-rates)，包括本页汇率喂入财务别处的回退/1:1 转换行为。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `ExchangeRatesPage({super.key})` | 构造函数（`ExchangeRatesPage`） | B | 创建汇率页实例。 |
| `createState` | 方法（`ExchangeRatesPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_ExchangeRatesPageState`） | B | 启动 `_loadRates`。 |
| [`_loadRates`](#loadrates) | 方法（`_ExchangeRatesPageState`） | A | 加载持久化汇率，今天未获取过则自动获取。 |
| [`_fetchOnline`](#fetchonline) | 方法（`_ExchangeRatesPageState`） | A | 获取实时汇率并持久化合并结果。 |
| [`_saveRates`](#saverates) | 方法（`_ExchangeRatesPageState`） | A | 把当前内存汇率映射作为新快照持久化。 |
| [`_addRate`](#addrate) | 方法（`_ExchangeRatesPageState`） | A | 经对话框添加新币种对汇率。 |
| [`_editRate`](#editrate) | 方法（`_ExchangeRatesPageState`） | A | 经对话框编辑既有对的币种/汇率。 |
| [`_deleteRate`](#deleterate) | 方法（`_ExchangeRatesPageState`） | A | 移除币种对汇率并持久化变更。 |
| `build` | 方法（`_ExchangeRatesPageState`） | B | 构建应用栏（带刷新操作）、汇率列表和添加按钮。 |
| `_RateDialog({...})` | 构造函数（`_RateDialog`） | B | 创建汇率对话框实例。 |
| `createState` | 方法（`_RateDialog`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_RateDialogState`） | B | 从组件预填 from/to 币种和汇率控制器，捕获初始签名。 |
| `dispose` | 方法（`_RateDialogState`） | B | 释放汇率文本控制器。 |
| `build` | 方法（`_RateDialogState`） | B | 构建 from/to 币种下拉框、汇率字段和操作。 |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | 方法（`_RateDialogState`） | A | 报告表单是否与其初始状态不同。 |
| [`_signature`](#signature) | 方法（`_RateDialogState`） | A | 构建对话框字段的可比较字符串快照。 |
| [`_submit`](#submit) | 方法（`_RateDialogState`） | A | 校验汇率/币种并带 `'FROM_TO'` 条目弹出。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/views/exchange_rates_page.dart` 返回 18，与上面 18 行精确匹配——每个块都恰好位于其真实声明（构造函数、`createState`、`initState`、`dispose` 或方法）正上方；未发现错附在调用点语句上方，也未发现未文档化的真实声明。类声明本身（`ExchangeRatesPage`、`_ExchangeRatesPageState`、`_RateDialog`、`_RateDialogState`）和 `static const _currencies` 列表不带 `/// Purpose:` 块，与本代码库记录可调用成员而非类或普通数据的约定一致。

## 文档

### `Future<void> _loadRates()` <a id="loadrates"></a>
- **种类：** `_ExchangeRatesPageState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 49-60 行）
- **用途：** 加载持久化汇率数据、立即显示，然后今天还没刷新过则触发在线刷新。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 经 [`ExchangeRateStorage.load`](../services/exchange_rate_storage.md#load) 读取 `exchange_rates.json`；可能经 [`_fetchOnline`](#fetchonline) 触发网络获取。
- **算法：**
  1. 从存储加载 `ExchangeRateData`。
  2. 立即从中填充 `_data`/`_rates`/`_loaded`，使页面不等网络就显示上次保存的汇率。
  3. 对照 `data.lastFetchedAt` 检查 [`ExchangeRateApi.shouldFetchToday`](../services/exchange_rate_api.md#shouldfetchtoday)；该获取了则 `await` [`_fetchOnline()`](#fetchonline)。
- **用法：**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadRates();
  }
  ```
- **备注：** 因为第 2 步总是先显示先前保存的汇率再进入第 3 步的网络检查，慢或失败的背景获取绝不阻塞页面显示数据。

### `Future<void> _fetchOnline()` <a id="fetchonline"></a>
- **种类：** `_ExchangeRatesPageState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 67-85 行）
- **用途：** 为用户配置的币种对获取实时汇率并持久化合并结果，防护并发或重复获取。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 经 [`ExchangeRateApi.fetchAndMerge`](../services/exchange_rate_api.md#fetchandmerge) 执行 HTTP GET；可能写 `exchange_rates.json` 并调用 `AutoSyncService.instance.notifySaved()`；切换 `_fetching` 驱动刷新转圈。
- **算法：**
  1. 尚无加载数据（`_data == null`）或获取已在途（`_fetching`）时立即退出。
  2. 设 `_fetching = true` 显示应用栏转圈。
  3. 调用 `ExchangeRateApi.fetchAndMerge(_data!)`——只更新本地已配置的币种对。
  4. 返回非 null 数据且组件仍 mounted 时：给结果盖章新鲜 `lastFetchedAt: DateTime.now()`，经 [`ExchangeRateStorage.save`](../services/exchange_rate_storage.md#save) 持久化它，通知 `AutoSyncService`，并更新本地 `_data`/`_rates`。
  5. 无论结果如何，仍 mounted 时清除 `_fetching`。
- **用法：**
  ```dart
  IconButton(
    onPressed: _fetching ? null : _fetchOnline,
    icon: _fetching
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.refresh),
  ),
  ```
- **备注：** `fetchAndMerge` 返回 `null`（无配置对，或每个 HTTP 请求都失败）时，此方法除清除 `_fetching` 外静默什么都不做——手动或自动刷新失败不向用户浮出错误。

### `Future<void> _saveRates()` <a id="saverates"></a>
- **种类：** `_ExchangeRatesPageState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 92-98 行）
- **用途：** 把当前内存 `_rates` 映射作为新汇率快照持久化（只在它确实与当前不同时创建）并标记同步层有挂起的本地变更。
- **输入：** 无（读取 `_data`、`_rates`）。
- **返回：** `Future<void>`。
- **副作用：** 经 [`ExchangeRateStorage.save`](../services/exchange_rate_storage.md#save) 写 `exchange_rates.json`（按 [`updateRates`](../services/exchange_rate_storage.md#updaterates)，只在汇率变化时）；调用 `AutoSyncService.instance.notifySaved()`。
- **算法：**
  1. `_data` 尚未加载时空操作。
  2. 委托给 [`ExchangeRateStorage.updateRates`](../services/exchange_rate_storage.md#updaterates)，它只在 `_rates` 与当前快照的汇率不同时创建新快照。
  3. 把（可能不变的）结果存回 `_data` 并经 `save` 写入。
  4. 通知 `AutoSyncService`。
- **用法：** 每次汇率变更后调用：[`_addRate`](#addrate)、[`_editRate`](#editrate)、[`_deleteRate`](#deleterate)。
- **备注：** 即使 `updateRates` 没有变化也总是调用 `ExchangeRateStorage.save`，因此恰好匹配既有汇率的手动编辑仍产生（空操作的）写入和同步通知。

### `Future<void> _addRate()` <a id="addrate"></a>
- **种类：** `_ExchangeRatesPageState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 105-114 行）
- **用途：** 打开空白汇率对话框，确认后添加新币种对汇率。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 显示 [`_RateDialog`](#submit)；确认后修改 `_rates` 并经 [`_saveRates`](#saverates) 持久化。
- **算法：**
  1. 显示无预填币种/汇率的 `_RateDialog`。
  2. 用户提交结果（`MapEntry`，键是 [`_RateDialogState._submit`](#submit) 构建的 `'FROM_TO'` 对字符串）时，把它存储进 `_rates` 并 await `_saveRates()`。
- **用法：**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _addRate,
    child: const Icon(Icons.add),
  ),
  ```
- **备注：** `_rates` 是普通 `Map<String, double>`，因此添加已存在的对（相同 `from`/`to`）静默覆盖旧汇率——没有既有条目检查。

### `Future<void> _editRate(String key, double value)` <a id="editrate"></a>
- **种类：** `_ExchangeRatesPageState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 121-139 行）
- **用途：** 打开预填既有对的币种和值的汇率对话框，然后应用（可能改名后的）结果。
- **输入：** `key` — 当前 `'FROM_TO'` 对键；`value` — 其当前汇率。
- **返回：** `Future<void>`。
- **副作用：** 显示 `_RateDialog`；确认后从 `_rates` 移除旧键并存储新键/值；经 [`_saveRates`](#saverates) 持久化。
- **算法：**
  1. 把 `key` 按 `_` 拆分为 `[from, to]`；不是恰好两部分时立即返回（对格式错误存储键的防御）。
  2. 显示带解析币种和当前汇率预填的 `_RateDialog`。
  3. 确认时，从 `_rates` 移除*旧*键，把对话框的结果插入其（可能不同的）键下，然后 `await _saveRates()`。
- **用法：**
  ```dart
  onTap: () => _editRate(entry.key, entry.value),
  ```
- **备注：** 因为对话框让用户改任一币种，编辑可以有效地重命名一对（如 `USD_CNY` -> `USD_EUR`）；插入新键前显式 `_rates.remove(key)` 正是防止过期条目在旧键下存活的东西。

### `void _deleteRate(String key)` <a id="deleterate"></a>
- **种类：** `_ExchangeRatesPageState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 146-149 行）
- **用途：** 移除币种对汇率并持久化变更。
- **输入：** `key`。
- **返回：** 无。
- **副作用：** 修改 `_rates`；经 [`_saveRates`](#saverates) 持久化（不 `await` 调用）。
- **算法：** 在 `setState` 内从 `_rates` 移除 `key`，然后调用 `_saveRates()`。
- **用法：**
  ```dart
  onDismissed: (_) => _deleteRate(entry.key),
  ```
- **备注：** 与 [`_addRate`](#addrate)/[`_editRate`](#editrate) 不同，这里的 `_saveRates()` 调用不 await——删除后立即接另一个汇率操作理论上可能竞争，虽然这么做需要先再来一次对话框往返。

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **种类：** `_RateDialogState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 424 行）
- **用途：** 告诉 `UnsavedChangesGuard`（[`../../../shared/widgets/unsaved_changes_guard.md`](../../../shared/widgets/unsaved_changes_guard.md)）表单是否已偏离其初始状态。
- **输入：** 无（只读实例状态）。
- **返回：** `bool` — 当前签名与 `_initialSignature` 不同时为 `true`。
- **副作用：** 无。
- **算法：** 把 [`_signature()`](#signature) 与 `initState` 末尾捕获一次的 `_initialSignature` 比较。
- **用法：**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **备注：** 作为撕离函数传入，因此每次弹出尝试都重新评估而不是缓存。

### `String _signature()` <a id="signature"></a>
- **种类：** `_RateDialogState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 431-432 行）
- **用途：** 产生一个当且仅当 from/to 币种或汇率文本变化时变化的单字符串，用作脏检查基线/比较。
- **输入：** 无（只读实例状态）。
- **返回：** `String` — `formSignature`（`../../../shared/widgets/unsaved_changes_guard.md`）的连接签名。
- **副作用：** 无。
- **算法：** 委托给 `formSignature([_from, _to, _rateController.text.trim()])`。
- **用法：**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **备注：** 无。

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **种类：** `_RateDialogState` 的方法
- **来源：** `lib/features/finance/views/exchange_rates_page.dart`（第 439-444 行）
- **用途：** 校验输入的汇率和币种对，然后带 `'FROM_TO'` -> 汇率条目弹出对话框。
- **输入：** `guard` — `UnsavedChangesGuard.builder` 提供的 `UnsavedChangesController`。
- **返回：** 无。
- **副作用：** 只在表单有效时带结果弹出路由（经 `guard.pop`）。
- **算法：**
  1. 把汇率文本解析为 `double`；不可解析或 `<= 0` 时静默返回。
  2. `_from == _to` 时静默返回（币种不能转换给自己）。
  3. 否则带 `MapEntry('${_from}_$_to', rate)` 弹出——这个下划线连接字符串是整个 `_rates`、`ExchangeRateStorage` 和 `balance_util.dart` 转换查找使用的规范对键格式。
- **用法：**
  ```dart
  onSubmitted: (_) => _submit(guard),
  ...
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(isEditing ? l10n.commonSave : l10n.commonAdd),
  ),
  ```
- **备注：** 校验失败静默——无效汇率、同币种对或空输入都不显示错误文本；对话框只是不关闭。

## 相关页面

- [财务](../../../../features/finance.md) — 汇率功能概览，包括消费这些汇率的直接/反向/中间/1:1 回退转换顺序。
- [`ExchangeRateStorage`](../services/exchange_rate_storage.md) — 本页是其薄 UI 的快照历史持久化层（`load`、`save`、`updateRates`）。
- [`ExchangeRateApi`](../services/exchange_rate_api.md) — `fetchAndMerge`/`shouldFetchToday`，[`_loadRates`](#loadrates)/[`_fetchOnline`](#fetchonline) 使用的实时获取客户端。
- [`unsaved_changes_guard.dart`](../../../shared/widgets/unsaved_changes_guard.md) — `_RateDialog` 使用的共享脏检查/丢弃确认模式。
