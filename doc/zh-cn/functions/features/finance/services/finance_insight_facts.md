# lib/features/finance/services/finance_insight_facts.dart

财务页端侧 AI 洞察卡片背后的纯事实构建器。`buildFinanceInsightFacts` 把 [财务页](../views/finance_page.md)已加载的账户、分类、交易、订阅和汇率数据转成 [`InsightFacts`](../../ai/services/insight_prompts.md)：本月及之前三个月的每月收入和支出、支出最多的分类、各账户合计，以及带最贵名称和即将续费的订阅摘要。一切都按财务页的方式（[`balance_util.dart`](balance_util.md)、[`subscription_summary.dart`](subscription_summary.md)）换算为默认货币并取整到整数单位。只发送聚合值、分类名称和订阅名称。卡片本身是 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，事实由 [`AiInsightStore`](../../ai/services/insight_service.md) 计算指纹。见 [端侧 AI — 每张卡片得到什么](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `financeInsightPastMonths` | 顶层 `const int` | B | 趋势在当月之外覆盖的过去月数（3）。 |
| `_money` | 顶层函数（私有） | B | 把金额格式化为 `<整数单位> <货币>`。 |
| [`buildFinanceInsightFacts`](#buildfinanceinsightfacts) | 顶层函数 | A | 构建财务卡片的事实。 |

`grep -c 'Purpose:' lib/features/finance/services/finance_insight_facts.dart` 报告 2，与 `_money` 和 `buildFinanceInsightFacts` 匹配。

**对账：** 3 行对 2 个 `Purpose:` 块。额外行是 `financeInsightPastMonths`，一个带普通 `///` 描述但无 `Purpose:` 块的真实顶层常量。

## 文档

### `InsightFacts? buildFinanceInsightFacts({required DateTime now, required List<Account> accounts, required List<Category> categories, required List<Transaction> transactions, required List<Subscription> subscriptions, required ExchangeRateData rateData, required String defaultCurrency, int maxNames = 5})` <a id="buildfinanceinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/finance_insight_facts.dart`（第 30 行）
- **用途：** 构建财务卡片的事实。
- **输入：** `now` — 本地时间；页面的 `accounts`、`categories`、`transactions`、`subscriptions`、`rateData`、`defaultCurrency`；`maxNames` — 订阅名称列表的上限。
- **返回：** `InsightFacts?`，含 `module: finance`、时段 `none`、四个槽位（`flowSummary`、`flowAdvice`、`subSummary`、`subAdvice`）和引用词——没有交易且没有活跃订阅时为 null。
- **副作用：** 无。
- **算法：**
  1. `- Today:`，带当月第几天和当月天数；`- Currency:`。
  2. 对本月及之前 `financeInsightPastMonths` 个月（从旧到新）：收入、支出和条目数，只计 `income` 和 `expense` 交易，每笔按其记录时的汇率快照（`rateData.ratesAt(t.rateSnapshotId)`）换算。当月标为 `(so far)`。
  3. 本月和上月支出最多的三个分类（未知分类记为 `uncategorised`），名称裁剪到 30 个 rune 并加入引用词。
  4. 有账户时：所有账户 `accountBalance` 的合计，按当前汇率换算。
  5. 活跃订阅数；非零时，来自 `summarizeSubscriptions` 的预计每月、实际每月和每年费用，按当前汇率下每月等值排序的 `maxNames` 个最贵订阅（按月：金额 ÷ 间隔；按年：金额 ÷（间隔 × 12）），以及来自 `upcomingSubscriptions` 的未来 7 天续费。这些名称也是引用词。
- **用法：**
  ```dart
  final facts = buildFinanceInsightFacts(
    now: now,
    accounts: _accounts,
    categories: _categories,
    transactions: _transactions,
    subscriptions: _subscriptions,
    rateData: _rateData,
    defaultCurrency: _defaultCurrency,
  );
  ```
  （`lib/features/finance/views/finance_page.dart`，第 631 行；由 `test/insight_facts_test.dart` 覆盖。）
- **备注：** 除账户的 id、货币和余额外不读取账户任何内容，也绝不读取备注，因此卡号、有效期、安全码、银行名称和备注无法到达模型。转账不计入收入和支出。即使没有活跃订阅也会请求订阅槽位（此时事实写 `0`）。取整到整数单位使指纹不随微小汇率变化而变。
