# lib/features/finance/services/subscription_summary.dart

不止一个页面显示的订阅数字与排序。在 v1.4.3 之前这些都是订阅页的私有成员；当财务主页在其摘要窗格中获得订阅概览后，三项统计、排序和即将续费过滤器移到这里，使两个界面读取同一份实现，对同一份数据不可能得出不同结果。本模块不从 Flutter 导入任何东西。两个界面的位置见 [财务](../../../../features/finance.md#views-and-analysis-page)，`nextBillingDate` 如何推进见 [订阅计费](../../../../algorithms/subscription-billing.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `SubscriptionSummary` | 顶层 `typedef`（record） | B | 以默认币种计的 `monthlyDue` / `monthlyAvg` / `yearlyAvg` 三元组。 |
| `subscriptionSortNextRenewal` | 顶层 `const String` | B | 排序模式 id `'nextRenewal'`：下次计费日期最早的在前，无日期的在最后。 |
| `subscriptionSortName` | 顶层 `const String` | B | 排序模式 id `'name'`：按名称、不区分大小写。 |
| `subscriptionSortCustom` | 顶层 `const String` | B | 排序模式 id `'custom'`：用户的拖拽顺序。 |
| [`summarizeSubscriptions`](#summarizesubscriptions) | 顶层函数 | A | 为激活订阅计算月应付、月均和年均。 |
| [`sortSubscriptions`](#sortsubscriptions) | 顶层函数 | A | 返回按某排序模式排好序的订阅列表副本。 |
| [`upcomingSubscriptions`](#upcomingsubscriptions) | 顶层函数 | A | 列出 N 天内计费的订阅，最早优先。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/subscription_summary.dart` 报告 3，与三个函数匹配；typedef 和三个排序模式常量带的是一行散文注释而不是 `Purpose:` 块，与别处的顶层常量一致，因为它们是文件的公开表面所以有对应行。3 个 Tier A，4 个 Tier B。

## 文档

### `SubscriptionSummary summarizeSubscriptions({required List<Subscription> subscriptions, required List<Transaction> transactions, required ExchangeRateData rateData, required String defaultCurrency, DateTime? now})` <a id="summarizesubscriptions"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/subscription_summary.dart`（第 37 行）
- **用途：** 以默认币种计算三个订阅头条数字。
- **输入：** `subscriptions`——非激活的被忽略；`transactions`——只有带 `subscriptionId` 的计入；`rateData`；`defaultCurrency`；`now`，可为测试注入。
- **返回：** `SubscriptionSummary`。
- **副作用：** 无。
- **算法：**
  1. `monthlyDue`：对每个激活订阅，月付周期取 `amount / interval`，年付周期取 `amount / (interval * 12)`，经 [`convertCurrency`](balance_util.md#convertcurrency) 按 `rateData.currentRates` 转换后求和。
  2. `monthlyAvg`：过滤出带订阅标记的交易；若没有，用 `monthlyDue`。否则取最早一笔的日期，数到 `now` 的整日历月数；不足两个月用 `monthlyDue`；否则把每笔带标记交易按**它自己的**汇率快照（`rateData.ratesAt(t.rateSnapshotId)`）转换后求和，再除以月数。
  3. `yearlyAvg = monthlyDue * 12`。
- **用法：** `_FinancePageState.build` 和 `_SubscriptionsPageState.build` 中的 `summarizeSubscriptions(subscriptions: _subscriptions, transactions: _transactions, rateData: _rateData, defaultCurrency: _defaultCurrency)`。
- **备注：** 月应付是按今天汇率从计费参数得出的投影；月均是按每笔交易自己的汇率版本得出的实际花费。因此两张卡片在方法和汇率上都可能分歧，这是有意的——投影说的是订阅现在花多少，平均说的是它们已经花了多少。

### `List<Subscription> sortSubscriptions(List<Subscription> list, {required String mode, required List<String> customOrder})` <a id="sortsubscriptions"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/subscription_summary.dart`（第 100 行）
- **用途：** 返回 `list` 按某订阅排序模式排好序的副本。
- **输入：** `list`；`mode`——三个排序模式常量之一；`customOrder`——用户拖拽顺序中的 id，只在自定义模式下读取。
- **返回：** `List<Subscription>`——新列表；输入不被修改。
- **副作用：** 无。
- **算法：** `'name'` → 不区分大小写的字母序。`'custom'` → 按每个 id 在 `customOrder` 中的索引，缺失的 id 放最后（哨兵索引 `customOrder.length`）；空 `customOrder` 保持原顺序。其他 → `nextBillingDate` 升序，null 在最后。
- **用法：** 订阅页的 `_active` getter 和财务主页的 `activeSubs`，两者都传入存储的 `subscriptionSortMode` / `subscriptionCustomOrder`。
- **备注：** 空自定义顺序不动作这一点被 `_onSortModeChanged` 依赖，它只在切入自定义模式后才播种顺序。

### `List<(Subscription, DateTime)> upcomingSubscriptions(List<Subscription> subscriptions, {required int days, DateTime? now})` <a id="upcomingsubscriptions"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/subscription_summary.dart`（第 145 行）
- **用途：** 收集下次计费日落在今天起 `days` 天内的订阅，供两处"即将续费"chip 行。
- **输入：** `subscriptions`、`days`、`now`（可为测试注入）。
- **返回：** `List<(Subscription, DateTime)>`，每项与其下次计费日期配对，升序排序。
- **副作用：** 无。
- **算法：** `limit = today + days`；无论 `isActive` 都跳过 `cancelType == atExpiry`，也跳过 `!isActive && cancelType == immediate`；`nextBillingDate` 的日历日不晚于 `limit` 的订阅被计入；按日期排序。
- **用法：** 两个页面 `build` 中的 `upcomingSubscriptions(_subscriptions, days: 3)`。
- **备注：** 到期时取消继续出现在订阅列表中，但不能为一笔从用户角度看即将停止的扣费发出续费提醒——因此这个过滤器比列表使用的 `isActive` 划分更严格。在 v1.4.3 之前两个页面各带一份完全相同的私有副本。

## 相关页面

- [`finance_page.md`](../views/finance_page.md) — 主页的订阅概览，促成本模块的第二个使用者。
- [`subscriptions_page.md`](../views/subscriptions_page.md) — 原始使用者。
- [`balance_util.md`](balance_util.md) — `convertCurrency`。
- [`exchange_rate_storage.md`](exchange_rate_storage.md) — `currentRates` / `ratesAt`。
