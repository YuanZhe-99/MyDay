# lib/features/finance/services/finance_analysis_insight_facts.dart

分析页面端侧 AI 洞察卡片背后的纯函数事实构建器，1.8.1 新增。`buildFinanceAnalysisInsightFacts` 把
[分析页面](../views/analysis_page.md)显示的时间段转成 `InsightModule.financeAnalysis` 的
[`InsightFacts`](../../ai/services/insight_prompts.md)：支出和收入合计、与上一个等长时间段相比的变化、
支出和收入最多的三个分类及占比、支出最高的一天和一周，以及支出变化最大的分类。卡片要求模型解释集中情况并建议
一项预算调整。参见[端侧 AI — 每张卡片获得的内容](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `financeAnalysisMaxCategories` | 顶层 `const int` | B | 一条占比行最多列出的分类数（3）。 |
| `financeAnalysisInsightSlots` | 顶层 `const List<InsightSlot>` | B | 卡片的两个槽位：`periodPattern`、`periodAdvice`。 |
| `_money` | 私有顶层函数 | B | 把金额格式化为带货币代码的整数单位。 |
| `_change` | 私有顶层函数 | B | 带符号的整数百分比变化；对比基数为零时为 null。 |
| [`buildFinanceAnalysisInsightFacts`](#buildfinanceanalysisinsightfacts) | 顶层函数 | A | 为所选时间段构建分析卡片的事实。 |

## 文档

### `InsightFacts? buildFinanceAnalysisInsightFacts({required DateTime now, required DateTime start, required DateTime end, required String kind, required List<Transaction> transactions, required List<Category> categories, required ExchangeRateData rateData, required String defaultCurrency})` <a id="buildfinanceanalysisinsightfacts"></a>
- **种类：** 顶层函数
- **源文件：** `lib/features/finance/services/finance_analysis_insight_facts.dart`
- **用途：** 为所选时间段构建分析卡片的事实。
- **输入：** `now` —— 本地时间；`start` —— 时间段的第一天；`end` —— 最后一天的次日；`kind` —— `year`、
  `month`、`day` 或 `custom`；页面的交易和分类；汇率表；默认货币。
- **返回：** `InsightFacts?` —— 该时间段内没有支出也没有收入时为 null。
- **副作用：** 无。
- **说明：**
  1. 包含今天的时间段只计算到今天（`so far`）；上一时间段是 `start` 之前紧邻的同样天数。
  2. 各行：`- Today:`、`- Period:`、`- Currency:`、`- Spending: … income: …`、`- Change vs the
     previous N days:`（上一时间段有记录时）、带整数百分比占比的 `- Top spending categories:` 和
     `- Top income categories:`、`- Peak spending day:`（两天及以上）、`- Peak spending week:`（十四天及
     以上，从 `start` 起每 7 天一周），以及 `- Largest category shift vs the previous period:`。
  3. 换算与财务页面一致：每笔交易按其汇率快照。只发送金额和分类名称（截断到 30 个字符，与货币代码一起列为
     引用词）。
