# lib/features/finance/widgets/add_subscription_dialog.dart

财务 [`Subscription`](../../../../features/finance.md#model) 记录的增/改/恢复对话框，与交易和任务对话框一样包在 `UnsavedChangesGuard`（`lib/shared/widgets/unsaved_changes_guard.dart`）中。一个组件由构造函数参数选择三种模式：普通**添加**（无 `subscription`）、**编辑**（`subscription` 已设置，`restoreAsCopy: false`）和**复制恢复**（`subscription` 作为模板设置，`restoreAsCopy: true`，用于把过期/取消订阅作为今天开始的全新订阅重新激活）。提交时它还基于 [`Subscription.firstBillingDate`](../../../../features/finance.md#model) 和 [订阅计费](../../../../algorithms/subscription-billing.md) 描述的月末钳制游标决定是否提示调用方导入历史计费交易。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AddSubscriptionDialog`（构造函数） | 构造函数（`AddSubscriptionDialog`） | B | 创建增/改/恢复订阅对话框实例。 |
| `createState` | 方法（`AddSubscriptionDialog`） | B | 创建可变 `_AddSubscriptionDialogState`。 |
| `_isEditing` | getter（`_AddSubscriptionDialogState`） | B | 返回此对话框是否原地编辑既有订阅。 |
| `_isRestoringCopy` | getter（`_AddSubscriptionDialogState`） | B | 返回此对话框是否从旧订阅创建新订阅。 |
| `initState` | 方法（`_AddSubscriptionDialogState`） | B | 从 `widget.subscription` 预填控制器/字段（或空白开始）并捕获初始表单签名。 |
| `dispose` | 方法（`_AddSubscriptionDialogState`） | B | 释放名称/金额/备注/试用天数文本控制器。 |
| `build` | 方法（`_AddSubscriptionDialogState`） | B | 渲染预设行、名称/emoji/图像选择器、金额/币种、账户/分类选择器、开始日期、试用天数、计费周期/间隔、备注和操作。 |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | 方法（`_AddSubscriptionDialogState`） | A | 报告表单是否与其初始状态不同。 |
| [`_signature`](#signature) | 方法（`_AddSubscriptionDialogState`） | A | 构建每个可编辑字段的可比较字符串快照。 |
| [`_submit`](#submit) | 方法（`_AddSubscriptionDialogState`） | A | 校验表单、构造 `Subscription`，并决定是否提示历史导入。 |
| [`_firstBillingDayBeforeToday`](#firstbillingdaybeforetoday) | 方法（`_AddSubscriptionDialogState`） | A | 返回订阅的第一个计费日是否严格早于今天。 |
| `_buildImagePreview` | 方法（组件辅助，`_AddSubscriptionDialogState`） | B | 渲染所选自定义图像（带移除按钮）或图像选择按钮。 |
| `_askImportHistory` | 方法（`_AddSubscriptionDialogState`） | B | 显示是/否对话框询问是否导入历史计费交易，然后带选择弹出。 |

`grep -c 'Purpose:' lib/features/finance/widgets/add_subscription_dialog.dart` 报告 13，与本文件全部十三个真实声明匹配。未发现错附或未文档化声明。

## 文档

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **种类：** `_AddSubscriptionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_subscription_dialog.dart`（第 506 行）
- **用途：** 告诉 `UnsavedChangesGuard` 表单是否已偏离其初始状态，使它知道对话框被关闭前是否要提示确认。
- **输入：** 无（只读实例状态）。
- **返回：** `bool` — 当前表单签名与 `_initialSignature` 不同时为 `true`。
- **副作用：** 无。
- **算法：**
  1. 经 [`_signature()`](#signature) 重新计算当前签名。
  2. 把它与 `_initialSignature` 比较，后者在 `initState` 末尾捕获一次（从 `widget.subscription` 预填之后，或空白新订阅表单立即）。
  3. 返回它们是否不同。
- **用法：**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **备注：** 作为撕离函数传入，因此每次弹出尝试都重新评估而不是缓存。

### `String _signature()` <a id="signature"></a>
- **种类：** `_AddSubscriptionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_subscription_dialog.dart`（第 513-526 行）
- **用途：** 产生一个当且仅当任何可编辑字段值变化时变化的单字符串，用作脏检查基线/比较。
- **输入：** 无（只读实例状态）。
- **返回：** `String` — `formSignature`（`lib/shared/widgets/unsaved_changes_guard.dart`）的连接签名。
- **副作用：** 无。
- **算法：**
  1. 把修剪后的名称/金额/备注/试用天数文本、`_startDate`、`_cycleType.name`、`_billingInterval`、`_currency`、`_selectedEmoji`、`_imagePath` 和所选分类/账户 id 收集进一个有序列表。
  2. 委托给 `formSignature(Iterable<Object?>)`，它把每个值映射为规范字符串并用不能出现在任何单个字段中的分隔符连接。
- **用法：**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **备注：** 无。

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **种类：** `_AddSubscriptionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_subscription_dialog.dart`（第 533-571 行）
- **用途：** 校验表单，有效时构造 `Subscription` 并直接弹出对话框或先询问是否导入历史计费交易。
- **输入：** `guard` — `UnsavedChangesGuard.builder` 提供的 `UnsavedChangesController`，用于带结果弹出路由。
- **返回：** 无。
- **副作用：** 带 `({sub: Subscription, importHistory: bool})` 记录弹出对话框路由（直接，或 `_askImportHistory` 解析后）；否则保持对话框打开。
- **算法：**
  1. 解析金额；不是有效正数时返回不弹出。
  2. 修剪名称；为空时返回不弹出——这是表单仅有的硬校验规则。
  3. 解析试用天数（解析失败默认 `0`）。
  4. 构造 `Subscription`。其 `id` 复制恢复时为 `null`（因此生成新 id），否则是既有 `widget.subscription?.id`；`isActive`/`cancelledAt`/`cancelType` 复制恢复时重置为"新激活"，否则从既有订阅带过。
  5. 计算 `shouldAskImport`：只在*添加*（不编辑、不恢复）**且** [`_firstBillingDayBeforeToday(sub)`](#firstbillingdaybeforetoday) 为 true 时——即新订阅的第一个计费日（开始日期 + 试用天数）已落在过去。
  6. `shouldAskImport` 时委托给 `_askImportHistory(sub, guard)`（用户回答后异步弹出）；否则带 `importHistory: false` 立即弹出。
- **用法：**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(
      _isRestoringCopy
          ? l10n.financeRestoreSubscription
          : (_isEditing ? l10n.commonSave : l10n.commonAdd),
    ),
  ),
  ```
  调用方消费弹出的记录，如：
  ```dart
  final result = await showDialog<({Subscription sub, bool importHistory})>(
    context: context,
    builder: (_) => AddSubscriptionDialog(
      categories: widget.categories,
      accounts: widget.accounts,
    ),
  );
  if (result != null) _insertNewSubscription(result);
  ```
  （`lib/features/finance/views/subscriptions_page.dart`，`_addSubscription`；`_editSubscription`/`_copyRestoreSubscription` 在同一文件中也用 `subscription: sub` 打开编辑、用 `subscription: sub, restoreAsCopy: true` 打开复制恢复。）
- **备注：** 所有持久化（插入订阅、`importHistory` 为 true 时生成追赶计费交易）发生在调用方，不在这里——此方法只产生结果记录并弹出。

### `bool _firstBillingDayBeforeToday(Subscription sub)` <a id="firstbillingdaybeforetoday"></a>
- **种类：** `_AddSubscriptionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_subscription_dialog.dart`（第 578-584 行）
- **用途：** 决定候选订阅的第一个计费日是否已落在过去，这门控 [`_submit`](#submit) 是否提供导入历史计费交易。
- **输入：** `sub` — `_submit` 刚构造的 `Subscription` 草稿（尚未持久化）。
- **返回：** `bool` — `sub.firstBillingDate` 的日历日早于今天的日历日为 `true`。
- **副作用：** 无。
- **算法：**
  1. 计算时间分量清零的今天（`DateTime(now.year, now.month, now.day)`）。
  2. 读取 `sub.firstBillingDate`（`Subscription.firstBillingDate => startDate.add(Duration(days: trialDays))`，定义在 `lib/features/finance/models/finance.dart`）并同样清零其时间分量。
  3. 返回清零的首计费日期 `isBefore` 清零的今天——**仅日期**比较，因此今天早些开始（或试用今天结束）的订阅不被认为"早于今天"。
- **用法：**
  ```dart
  final shouldAskImport = !_isEditing && _firstBillingDayBeforeToday(sub);
  ```
  （`_submit`，同一文件/类。）
- **备注：** 按日期粒度比较（而不是原始 `DateTime.isBefore`）是刻意的——它防止同日新订阅（在其 `startDate` 后几秒/几分钟创建）虚假触发"导入历史？"提示，因为 `startDate` 和"现在"否则几乎绝不会逐位相等。
