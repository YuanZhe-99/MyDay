# 订阅计费演练：一月 31 日的月订阅

对 [`Subscription.nextBillingCursor` 的月末钳制](../algorithms/subscription-billing.md)和 `SubscriptionProcessor` 的追赶计费做具体日期实例演练，通过手工追踪 `lib/features/finance/models/finance.dart` 和 `lib/features/finance/services/subscription_processor.dart` 中的真实算法计算。2026 年不是闰年，因此那年二月有 28 天。

## 设置

```dart
final sub = Subscription(
  id: 'sub-abc',
  name: 'Streaming Plan',
  startDate: DateTime(2026, 1, 31),
  trialDays: 0,
  billingCycleType: BillingCycleType.monthly,
  billingInterval: 1,
  amount: 9.99,
  currency: 'USD',
  accountId: 'acc-1',
);
```

`firstBillingDate = startDate + trialDays = 2026-01-31`。这个日期是每个未来游标推进的**锚点**——它的 day-of-month `31` 是之后每次 `nextBillingCursor` 调用试图保留的东西。

## 第 1 步 — 2026 年 1 月 31 日首次运行：迁移分支

订阅刚创建，因此 `nextBillingDate` 仍未设置。`SubscriptionProcessor.process()` 命中迁移分支：

```dart
nbd = sub.calculateNextBillingDate(after: today.subtract(const Duration(days: 1)));
```

`after = 2026-01-30` 时，`calculateNextBillingDate` 把 `cursor` 从锚点（`2026-01-31`）开始，`while (!cursor.isAfter(after))` 循环一次都不运行，因为 `2026-01-31` 已在 `2026-01-30` 之后。因此 `nbd = 2026-01-31`——这次首次运行**只持久化**订阅上的 `nextBillingDate = 2026-01-31`。还不生成交易；这避免对处理器尚未真正走过的订阅追溯计费。

## 第 2 步 — 同一天稍后（或任何 `today >= Jan 31` 的运行）：首次计费

现在 `nbd = 2026-01-31` 已设置。`nbdDay = 2026-01-31`。`cursor` 从那里开始。

- `cursor (Jan 31).isAfter(today)` 为 false → 进入循环。
- `billingDateKey('sub-abc', Jan 31) = 'sub-abc|2026-01-31'` 尚未在 `billedKeys` 中 → 生成一笔交易：`id: 'subscription_sub-abc_2026-01-31'`、`date: 2026-01-31`、`amount: 9.99`。
- 推进：`nextBillingCursor(cursor: Jan 31, cycleType: monthly, interval: 1, anchor: Jan 31)`：
  - `year = 2026`、`month = 1 + 1 = 2`（二月）。
  - `lastDay = DateTime(2026, 3, 0).day = 28`（2026 年二月有 28 天——三月的第 0 天是二月的最后一天）。
  - `day = anchor.day (31) < lastDay (28) ? 31 : 28` → **28**（31 不小于 28）。
  - 结果：**`2026-02-28`**。
- `cursor (Feb 28).isAfter(today = Jan 31)` 为 true → 循环停止。

生成一笔交易（1 月 31 日，$9.99）；`nextBillingDate` 持久化为 **`2026-02-28`**。

## 第 3 步 — 2026 年 4 月 5 日应用重开：多周期追赶

用户直到**4 月 5 日**才再次打开应用。现在一次 `process()` 调用需要一趟追赶**两次**错过的周期（二月和三月）。

`nbd = 2026-02-28`、`today = 2026-04-05`。循环运行两次后 `cursor` 终于超过 `today`：

| 迭代 | 起始 `cursor` | 计费？ | `nextBillingCursor` 推进 | 新 `cursor` |
| --- | --- | --- | --- | --- |
| 1 | `2026-02-28` | 尚未计费 → 为 **2 月 28 日**生成交易，$9.99 | `month = 2+1=3`（三月）；`lastDay = DateTime(2026,4,0).day = 31`；`day = 31 < 31 ? 31 : 31 = 31` | `2026-03-31` |
| 2 | `2026-03-31` | 尚未计费 → 为 **3 月 31 日**生成交易，$9.99 | `month = 3+1=4`（四月）；`lastDay = DateTime(2026,5,0).day = 30`；`day = 31 < 30 ? 31 : 30 = 30` | `2026-04-30` |
| — | `2026-04-30` | `cursor.isAfter(today = Apr 5)` 为 true → 循环停止 | — | — |

这一趟生成两笔交易——2 月 28 日和 3 月 31 日——`nextBillingDate` 持久化为 **`2026-04-30`**。注意锚点日（31）经二月的 28 钳制后没有被永久丢失：三月正确地在 31 日再次计费，只有四月（30 天）把它钳到 30 日。这正是"绝不跳过或漂移月份"保证：朴素的 `DateTime(year, month + 1, day)` 算术会把 `Feb 31` 溢出成 `Mar 3`，之后每个周期都会永远锚定在第 3 天而不是第 31 天。

## 第 4 步 — 继续模式

如果没有其他变化，接下来几个游标（仍锚定在第 31 天）是：

- `2026-04-30` → `2026-05-31`（五月有 31 天，无需钳制）
- `2026-05-31` → `2026-06-30`（六月钳到 30）
- `2026-06-30` → `2026-07-31`（七月有 31，锚点再次完全恢复）

## 跨设备幂等

如果同一订阅也存在于第二台设备上，它独立运行了自己的追赶并在本设备同步前为（比如说）3 月 31 日生成了一笔交易，两笔交易都携带相同的稳定 id `subscription_sub-abc_2026-03-31`（见 [订阅计费](../algorithms/subscription-billing.md#idempotent-billing-day-generation)）。当 [三方合并](../algorithms/three-way-merge.md) 在 `finance_data.json` 上运行时，那个 id 的两条 `Transaction` 记录被当作同一条记录而不是重复——甚至在同步之前，任一台设备上的 `_existingBillingKeys` 都会按 `subscriptionId|date` 业务键识别另一台的交易，无论它最初由哪台设备（或哪种交易 id 方案）创建，因此第二次本地追赶运行也绝不会给 3 月 31 日计两次费。

## 相关页面

- [订阅计费](../algorithms/subscription-billing.md) — 本演练追踪的算法。
- [财务](../features/finance.md) — `SubscriptionProcessor` 在模块中的位置。
- [三方合并](../algorithms/three-way-merge.md) — 生成的交易如何跨设备合并。
