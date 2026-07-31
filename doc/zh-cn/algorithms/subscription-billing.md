# 订阅计费

来源：`lib/features/finance/services/subscription_processor.dart`（完整阅读）和 `lib/features/finance/models/finance.dart` 中 `Subscription` 上的 `nextBillingCursor`/`calculateNextBillingDate`/`billingDatesBefore` 辅助。它在模块中的位置见 [财务](../features/finance.md)，具体日期见 [订阅计费演练](../examples/subscription-billing-walkthrough.md)。

## 月末钳制：`Subscription.nextBillingCursor`

```dart
static DateTime nextBillingCursor({
  required DateTime cursor,
  required BillingCycleType cycleType,
  required int interval,
  required DateTime anchor,
}) {
  final int year;
  final int month;
  if (cycleType == BillingCycleType.monthly) {
    year = cursor.year;
    month = cursor.month + interval;
  } else {
    year = cursor.year + interval;
    month = anchor.month;
  }
  // Day 0 of the following month is the last day of the target month.
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = anchor.day < lastDay ? anchor.day : lastDay;
  return DateTime(year, month, day);
}
```

这是应用中**唯一**的计费日期推进函数——模型的 `calculateNextBillingDate`/`billingDatesBefore` 和 `SubscriptionProcessor` 的追赶循环都走它。关键技巧是 `DateTime(year, month + 1, 0)`：在 Dart 中给 `DateTime` 传第 `0` 天会得到相对 `month + 1` 的*上*月最后一天——即 `month` 本身的最后一天。该值 `lastDay` 随后用于钳制锚点的 day-of-month：

```dart
final day = anchor.day < lastDay ? anchor.day : lastDay;
```

因此**锚点日**（来自订阅 `firstBillingDate` 的 day-of-month，即 `startDate + trialDays`）每个周期都被保留，*除非*目标月太短装不下它，此时游标落在该月实际最后一天，而不是 Dart 的默认溢出行为（否则会把 `DateTime(2026, 2, 31)` 滚进三月）。注意 `month` 允许超过 `12`（如 `month = 13`）——Dart 的 `DateTime` 构造函数已把第 13 个"月"规范化为 `year + 1` 的一月，因此月周期函数不需要自己的年回卷分支；只有 day-of-month 需要显式钳制。

- **月周期**在同一 `year` 变量内把 `month` 推进 `interval`（让 `DateTime` 构造函数在 `month > 12` 时自然回卷年份）。
- **年周期**把 `year` 推进 `interval` 并把 `month` 固定为锚点的月份——因此锚定在 2 月 29 日的年订阅在非闰年钳制到 2 月 28（非闰年二月的 `lastDay` 是 28），目标年是闰年时回到 2 月 29。

具体月例子：**1 月 31 日**的锚点先计 **2 月 28 日**（闰年 29 日），然后 **3 月 31 日**、**4 月 30 日**、**5 月 31 日**……——锚点日（31）每个周期重新应用、只在必要时钳制，因此订阅绝不会像朴素的 `DateTime(year, month + 1, day)` 算术那样永久漂移到不同的 day-of-month（那种算法会让 1 月 31 日经过二月后变成 3 月 3 日）。

## 幂等的计费日生成

`SubscriptionProcessor.billingDateKey(subscriptionId, date)` 构建一个**业务键**——`'$subscriptionId|yyyy-MM-dd'`——与任何交易 id 无关。`_existingBillingKeys(...)` 扫描所有既有交易，为每个带 `subscriptionId` 的交易收集该键，无论那个交易自己的 `id` 是较旧的随机 UUID（历史、幂等之前的交易）还是较新的**稳定 id**：

```dart
static String transactionIdForBilling(String subscriptionId, DateTime date) =>
    'subscription_${subscriptionId}_yyyy-MM-dd';
```

因为稳定 id 对每个订阅+天是确定的，生成两次（如本地一次、同步合并从另一台设备看到同一订阅后再一次）两次都产生*相同*的交易 id——因此 `mergeRecords` 式按 id 键控的合并自然把它们当作同一条记录，而不是创建重复。`process()` 循环只在 `billingKey` **尚未**在 `billedKeys` 中时追加新交易，因此对已含当天费用的交易列表重新运行处理器（无论哪种 id 方案）对那天是空操作。

## 每小时续费追赶和多周期追赶

`SubscriptionProcessor.process(subscriptions, existingTransactions)`（按 `AGENTS.md`）经提醒循环按每小时节奏运行。对每个订阅：

1. **立即取消**的订阅原样通过。
2. **迁移情形：** `nextBillingDate` 从未持久化（早于该字段的旧订阅）时，经 `calculateNextBillingDate(after: yesterday)` 计算一次并持久化，那一趟不生成任何交易——这避免对只是还没被这段代码路径碰过的订阅追溯计费。
3. **追赶循环：** 从持久化的 `nextBillingDate` 开始，游标经 `nextBillingCursor` 一次推进一个周期（尊重 `atExpiry` 取消截止），对经过的每个逾期计费日生成一笔交易，**直到游标不再 `<= today`**。应用关闭错过三个月的月周期时，这个循环一趟生成全部三笔交易并把游标落在正确的下一个未来日期——这就是"多周期追赶"行为。
4. **到期时到期检查：** 订阅的 `cancelType` 是 `atExpiry`、`cancelledAt` 已设置、循环前的 `nextBillingDate` 尚未晚于今天、且循环后的游标晚于 `cancelledAt` 时，订阅在同一更新中被标记 `isActive = false`。

函数返回 `(subs, txs, changed)`——更新后的订阅、新生成的交易，以及是否有任何东西变化（使调用方在无需更新时跳过保存）。

## 相关页面

- [财务](../features/finance.md) — `SubscriptionProcessor` 在其他财务服务中的位置。
- [订阅计费演练](../examples/subscription-billing-walkthrough.md) — 1 月 31 日锚点推进 2 月/3 月/4 月，带具体日历日期。
- [数据格式](../data-formats.md) — 完整 `Subscription` 字段列表。
