# lib/features/finance/services/exchange_rate_api.dart

对免费 [open.er-api.com](https://open.er-api.com) 汇率 API 的薄 HTTP 客户端（无 API 密钥，每月 1,500 次免费请求）。它只更新用户已在 [`ExchangeRateData`](exchange_rate_storage.md) 中配置的币种对——它自己绝不引入新对——汇率页经 [`shouldFetchToday`](#shouldfetchtoday) 把调用门控为每天最多一次。它与 [`ExchangeRateStorage`](exchange_rate_storage.md) 的配合见 [财务](../../../../features/finance.md#exchange-rates)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`fetchAndMerge`](#fetchandmerge) | 静态方法（`ExchangeRateApi`） | A | 获取实时汇率并合并进既有汇率数据。 |
| [`_fetchRates`](#fetchrates) | 静态方法（`ExchangeRateApi`） | A | 对一个基础币种的汇率表的原始获取。 |
| [`shouldFetchToday`](#shouldfetchtoday) | 静态方法（`ExchangeRateApi`） | A | 决定今天是否该自动获取。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/exchange_rate_api.dart` 返回 3，与上面 3 行精确匹配——每个块都恰好位于其真实静态方法声明正上方；未发现错附在调用点语句上方。文件中唯一的其他声明是私有 `static const _baseUrl` 字段，它（与本代码库约定一致）不带 `/// Purpose:` 块，因为它是普通数据，不是可调用物。三个方法都分类为 Tier A：它们执行真实网络 IO 和/或分支逻辑，匹配定级规则显式的服务/IO 桶。

## 文档

### `static Future<ExchangeRateData?> fetchAndMerge(ExchangeRateData data)` <a id="fetchandmerge"></a>
- **种类：** `ExchangeRateApi` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_api.dart`（第 22 行）
- **用途：** 为用户当前配置的对隐含的每个基础币种获取实时汇率，然后把获取值合并进新的 `ExchangeRateData` 快照——只更新本地已存在的对。
- **输入：** `data` — 当前 `ExchangeRateData`，其 `currentRates` 键（`'FROM_TO'` 字符串）决定查询哪些对和基础币种。
- **返回：** `Future<ExchangeRateData?>` — 没有配置的对或每次获取都失败时为 `null`；否则是 [`ExchangeRateStorage.updateRates`](exchange_rate_storage.md#updaterates) 的结果。
- **副作用：** 对配置对中每个唯一基础币种执行一次 HTTP GET。
- **算法：**
  1. 把 `data.currentRates.keys` 读为对列表；为空时立即返回 `null`。
  2. 收集唯一基础币种集合（每个 `'FROM_TO'` 对键中 `_` 之前的部分）。
  3. 对每个基础币种调用一次 [`_fetchRates`](#fetchrates)，跳过返回 `null` 的；全部失败则返回 `null`。
  4. 对每个配置对，在获取的基础汇率表中查找并覆盖 `data.currentRates` 副本中该对的条目（存在时）。
  5. 委托给 `ExchangeRateStorage.updateRates(data, newRates)`，它只在合并汇率与当前实际不同时创建新 `RateSnapshot`。
- **用法：**
  ```dart
  final updated = await ExchangeRateApi.fetchAndMerge(_data!);
  if (updated != null && mounted) {
    final withTimestamp = ExchangeRateData(
      currentSnapshotId: updated.currentSnapshotId,
      snapshots: updated.snapshots,
      lastFetchedAt: DateTime.now(),
    );
    await ExchangeRateStorage.save(withTimestamp);
  }
  ```
  （`lib/features/finance/views/exchange_rates_page.dart:70-77`，`_fetchOnline`，成功合并后盖章 `lastFetchedAt`，使 [`shouldFetchToday`](#shouldfetchtoday) 同一天不会重新获取。）
- **备注：** 基础币种获取失败（或目标币种不在获取表中）的对在 `newRates` 中原样保留而不是移除——部分网络失败绝不丢弃先前配置的对。

### `static Future<Map<String, double>?> _fetchRates(String base)` <a id="fetchrates"></a>
- **种类：** `ExchangeRateApi` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_api.dart`（第 64 行）
- **用途：** 对一个基础币种执行对 `open.er-api.com` 的原始 HTTP GET 并解析其汇率表。
- **输入：** `base` — ISO 币种代码，如 `'CNY'`。
- **返回：** `Future<Map<String, double>?>` — 如 `{'CNY': 7.25, 'EUR': 0.92, ...}`，任何失败为 `null`。
- **副作用：** 对 `https://open.er-api.com/v6/latest/<base>` 一次 HTTP GET，10 秒超时。
- **算法：**
  1. GET 该 URL；状态码不是 200 时返回 `null`。
  2. 解码 JSON 正文；`json['result'] != 'success'` 时返回 `null`。
  3. 把 `json['rates']`（`Map<String, dynamic>`）映射为 `Map<String, double>`。
  4. 任何异常（网络错误、超时、格式错误 JSON）被捕获并映射为 `null`。
- **用法：** 在 [`fetchAndMerge`](#fetchandmerge) 内对每个唯一基础币种调用一次：`final result = await _fetchRates(base);`。
- **备注：** 仅本文件内部使用的辅助；绝不向其调用方抛出。

### `static bool shouldFetchToday(DateTime? lastFetch)` <a id="shouldfetchtoday"></a>
- **种类：** `ExchangeRateApi` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_api.dart`（第 85 行）
- **用途：** 决定自动汇率刷新是否到期，把免费 API 门控为每个日历日最多一次获取。
- **输入：** `lastFetch` — 先前记录的 `ExchangeRateData.lastFetchedAt`，从未获取时为 `null`。
- **返回：** `bool` — `lastFetch` 为 `null` 或落在与现在不同的日历日时为 `true`。
- **副作用：** 无。
- **算法：** 把 `now.year`/`now.month`/`now.day` 与 `lastFetch` 的对应字段比较；任何不匹配（或 `lastFetch` 为 `null`）意味着该获取了。
- **用法：**
  ```dart
  if (ExchangeRateApi.shouldFetchToday(data.lastFetchedAt)) {
    await _fetchOnline();
  }
  ```
  （`lib/features/finance/views/exchange_rates_page.dart:57-59`，汇率页加载数据后立即运行一次。）
- **备注：** 用本地日历日比较，不是滚动 24 小时窗口——午夜前一次获取和午夜后一次获取即使相隔不到一分钟也算"不同天"。
