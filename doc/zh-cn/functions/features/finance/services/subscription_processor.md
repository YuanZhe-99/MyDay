# lib/features/finance/services/subscription_processor.dart

`SubscriptionProcessor` 是订阅的每小时续费引擎：给定每个 [`Subscription`](../models/finance.md#subscription-new) 上持久化的 `nextBillingDate`，它为每个逾期计费日生成一笔交易（应用关闭一段时间时单趟追赶多个错过的周期），经 [`Subscription.nextBillingCursor`](../models/finance.md#nextbillingcursor) 推进游标，并在 `atExpiry` 取消的截止已过时把订阅翻转为非激活。完整阅读——本文件除下方所示外没有逻辑。完整算法说明（幂等计费日生成、每小时/多周期追赶、到期时过期）见 [订阅计费](../../../../algorithms/subscription-billing.md)，它如何融入功能见 [财务](../../../../features/finance.md#subscription-processing)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `debugNowOverride`（静态字段） | 字段 | B | `DateTime.now()` 的测试/调试覆盖——无 Purpose 块（见对账）。 |
| [`billingDateKey`](#billingdatekey) | 静态方法（`SubscriptionProcessor`） | A | 为订阅计费日构建幂等业务键。 |
| [`transactionIdForBilling`](#transactionidforbilling) | 静态方法（`SubscriptionProcessor`） | A | 为订阅计费日构建确定性交易 id。 |
| `_now` | 静态 getter（`SubscriptionProcessor`） | B | 返回 `debugNowOverride ?? DateTime.now()`。 |
| [`process`](#process) | 静态方法（`SubscriptionProcessor`） | A | 生成逾期订阅交易并推进持久化计费日期。 |
| [`_existingBillingKeys`](#existingbillingkeys) | 静态方法（`SubscriptionProcessor`） | A | 收集已被交易表示的订阅计费日。 |
| [`_withNextBillingDate`](#withnextbillingdate) | 静态方法（`SubscriptionProcessor`） | A | 复制带替换 `nextBillingDate`/`isActive` 的订阅。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/subscription_processor.dart` 返回 6，与上面 6 个文档化行精确匹配——每个块都恰好位于其真实静态方法或 getter 声明正上方；未发现错附在调用点语句上方。表格在那 6 行之外还有一行：普通 `static DateTime? debugNowOverride;` 字段，不带 `/// Purpose:` 块，与本代码库记录可调用成员而非普通数据字段的约定一致。对照此列表交叉核对文件中的每个 `static`/`get` 声明，没有发现未文档化的可调用声明。`billingDateKey`、`transactionIdForBilling`、`process`、`_existingBillingKeys` 和 `_withNextBillingDate` 分类为 Tier A——前两个构建整个计费算法依赖的幂等键（在 `subscription-billing.md` 中详细记录），后三个含核心循环/分支逻辑；`_now` 分类为 Tier B，作为平凡单行 null 合并 getter。

## 文档

### `static String billingDateKey(String subscriptionId, DateTime date)` <a id="billingdatekey"></a>
- **种类：** `SubscriptionProcessor` 的静态方法
- **来源：** `lib/features/finance/services/subscription_processor.dart`（第 17 行）
- **用途：** 构建用于检测订阅是否已在给定日历日计费的业务键 `'<subscriptionId>|yyyy-MM-dd'`，与任何交易 id 无关。
- **输入：** `subscriptionId`；`date` — 只用年/月/日。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 把 `date` 截断到午夜，年/月/日零填充，并插值为 `'$subscriptionId|$dateKey'`。
- **用法：**
  ```dart
  final billingKey = billingDateKey(sub.id, cursor);
  if (!billedKeys.contains(billingKey)) { ... }
  ```
  （`lib/features/finance/services/subscription_processor.dart:97-98`，[`process`](#process) 内；[`_existingBillingKeys`](#existingbillingkeys) 中构建 `billedKeys` 集合也用它。）
- **备注：** 为什么是这个业务键——而不是交易自己的 `id`——让对已计费日重新运行 `process` 成为空操作、同样识别较旧随机 id 和较新稳定 id 交易，见 [订阅计费](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation)。

### `static String transactionIdForBilling(String subscriptionId, DateTime date)` <a id="transactionidforbilling"></a>
- **种类：** `SubscriptionProcessor` 的静态方法
- **来源：** `lib/features/finance/services/subscription_processor.dart`（第 29 行）
- **用途：** 构建分配给新生成计费交易的确定性交易 id `'subscription_<subscriptionId>_yyyy-MM-dd'`，使同一订阅+天总是产生相同 id。
- **输入：** `subscriptionId`；`date` — 只用年/月/日。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 把 `date` 截断到午夜，年/月/日零填充，并插值为 `'subscription_${subscriptionId}_$dateKey'`。
- **用法：**
  ```dart
  newTxs.add(
    Transaction(
      id: transactionIdForBilling(sub.id, cursor),
      type: TransactionType.expense,
      amount: sub.amount,
      ...
    ),
  );
  ```
  （`lib/features/finance/services/subscription_processor.dart:100-101`，[`process`](#process) 内。）
- **备注：** 因为此 id 对每个订阅+天是确定的，在两台设备上独立生成（如本地一次、同步合并看到同一订阅后再一次）两次都产生*相同* id，因此按 id 键控的合并把它们当作一条记录而不是重复——详见 [订阅计费](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation)。

### `static ({List<Subscription> subs, List<Transaction> txs, bool changed}) process(List<Subscription> subscriptions, List<Transaction> existingTransactions)` <a id="process"></a>
- **种类：** `SubscriptionProcessor` 的静态方法
- **来源：** `lib/features/finance/services/subscription_processor.dart`（第 48 行）
- **用途：** 对每个订阅运行一次每小时（或按需）续费趟：为每个逾期计费日生成一笔交易，一次调用追赶多个错过的周期，并在 `atExpiry` 取消的订阅截止已过时把它们标记为非激活。
- **输入：** `subscriptions` — 完整当前列表；`existingTransactions` — 用于经 [`_existingBillingKeys`](#existingbillingkeys) 检测已计费日。
- **返回：** `({subs, txs, changed})` — `subs` 是完整更新订阅列表（同长度、保序），`txs` 只是新生成的交易，`changed` 在任何订阅的持久化状态变化时为 `true`（使调用方无事可做时跳过保存）。
- **副作用：** 无（对其输入的纯函数——唯一隐式输入是 `_now`，即 `debugNowOverride ?? DateTime.now()`）。
- **算法：** 完整走查见 [订阅计费](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up)。简言之，逐订阅：
  1. 立即取消的原样通过。
  2. **迁移情形：** `nextBillingDate` 从未持久化时，经 `calculateNextBillingDate(after: yesterday)` 计算一次并持久化，这一趟不生成交易。
  3. **追赶循环：** 从持久化的 `nextBillingDate` 开始，经 [`Subscription.nextBillingCursor`](../models/finance.md#nextbillingcursor) 一次推进一个周期（在 `atExpiry` 截止提前停止），经 [`billingDateKey`](#billingdatekey)/[`transactionIdForBilling`](#transactionidforbilling) 为每个逾期日生成一笔交易，直到游标不再 `<= today`。
  4. **到期时检查：** 订阅被 `atExpiry` 取消、循环前 `nextBillingDate` 尚未过今天、且循环后游标过 `cancelledAt` 时，在同一更新中标记 `isActive = false`。
- **用法：**
  ```dart
  final result = SubscriptionProcessor.process(_subscriptions, _transactions);
  if (result.changed) {
    setState(() {
      _subscriptions = result.subs;
      _transactions = [..._transactions, ...result.txs];
    });
  }
  ```
  （`lib/features/finance/views/finance_page.dart:145-150`，`_processSubscriptions`；相同形态从 `lib/shared/services/reminder_service.dart:964-968` 在 `AGENTS.md` 引用的每小时提醒循环运行。）
- **备注：** 应用关闭错过三个月的月周期时，这一次调用生成全部三笔交易并把游标落在正确的下一个未来日期——`subscription-billing.md` 文档化的"多周期追赶"行为。

### `static Set<String> _existingBillingKeys(List<Transaction> transactions)` <a id="existingbillingkeys"></a>
- **种类：** `SubscriptionProcessor` 的静态方法
- **来源：** `lib/features/finance/services/subscription_processor.dart`（第 154 行）
- **用途：** 收集既有交易中已表示的订阅计费日键集合，无论每笔交易自己的 `id` 是较旧随机 UUID 还是较新稳定 id。
- **输入：** `transactions` — 完整既有交易列表。
- **返回：** [`billingDateKey`](#billingdatekey) 值的 `Set<String>`。
- **副作用：** 无。
- **算法：** 对 `transactions` 的集合推导式，为每个 `subscriptionId` 非 null 的交易包含 `billingDateKey(tx.subscriptionId!, tx.date)`。
- **用法：** 在 [`process`](#process) 顶部调用一次：`final billedKeys = _existingBillingKeys(existingTransactions);`。
- **备注：** 按订阅 id + 日历日（不是交易 id）键控正是让它把历史随机 id 交易识别为已计费的东西，按 [订阅计费](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation)。

### `static Subscription _withNextBillingDate(Subscription sub, DateTime date, {bool? isActive})` <a id="withnextbillingdate"></a>
- **种类：** `SubscriptionProcessor` 的静态方法
- **来源：** `lib/features/finance/services/subscription_processor.dart`（第 167 行）
- **用途：** 返回 `nextBillingDate` 被替换、`isActive` 可选覆盖、其他每个字段原样带过的订阅副本。
- **输入：** `sub`；`date` — 新 `nextBillingDate`；`isActive` — 可选覆盖（用于把过期的 `atExpiry` 订阅翻转为非激活）。
- **返回：** 新的 `Subscription`。
- **副作用：** 无。
- **算法：** 逐字复制 `sub` 的每个字段、唯独 `nextBillingDate: date` 和 `isActive: isActive ?? sub.isActive` 不同的新 `Subscription`。
- **用法：** 从 [`process`](#process) 需要持久化新游标的两个分支调用——迁移情形分支（`_withNextBillingDate(sub, nbd)`）和追赶循环分支（`_withNextBillingDate(sub, cursor, isActive: expired ? false : sub.isActive)`）。
- **备注：** 这是名实相副的 `Subscription` copy-with 风格辅助——`Subscription` 本身没有 `copyWith` 方法，因此 `SubscriptionProcessor` 逐字段重建对象。
