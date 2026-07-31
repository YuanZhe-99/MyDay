# lib/features/intimacy/widgets/add_record_dialog.dart

`AddRecordDialog` 是单条 `IntimacyRecord` 的增/改表单——独自-vs-伴侣切换、伴侣/玩具/姿势选择器、5 星愉悦度、小时+分钟时长、x100/x1 抽插计数器、性高潮/色情/安全套开关、地点/备注文本和日期+时间选择器——从记录列表（增/改）和计时器流程（`widgets/timer_page.dart`，从完成的秒表会话预填）都打开它。它使用共享的 [`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md) 脏检查模式做取消确认，与 [`weight_page.dart` 的记录对话框](../../../../functions/features/weight/views/weight_page.md) 使用的模式相同。尽管是对话框组件，其 `initState`/`_submit` 对携带真实逻辑：这正是仓库对亲密记录的已删除伴侣容忍实际实现的地方——见 [亲密](../../../../features/intimacy.md#deleted-partner-handling)，它记录了"编辑伴侣已被删除的记录会构建并保留未触碰的伴侣 id"。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AddRecordDialog`（构造函数） | 构造函数（`AddRecordDialog`） | B | 从可选既有记录和初始选择参数创建增/改记录对话框实例。 |
| `AddRecordDialog.createState` | 方法（`AddRecordDialog`） | B | 创建可变 `_AddRecordDialogState`。 |
| `_isEditing` | getter（`_AddRecordDialogState`） | B | 返回 `widget.record` 是否非 null（编辑模式 vs 添加模式）。 |
| [`initState`](#initstate) | 方法（`_AddRecordDialogState`） | A | 从被编辑记录或初始选择参数播种每个字段，应用独自/抽插单位/时长默认规则。 |
| `dispose` | 方法（`_AddRecordDialogState`） | B | 释放全部五个 `TextEditingController`。 |
| `build` | 方法（`_AddRecordDialogState`） | B | 在 `UnsavedChangesGuard` 包装的 `Dialog` 内渲染完整增/改表单。 |
| `_hasUnsavedChanges` | 方法（`_AddRecordDialogState`） | B | 把当前表单签名与 `initState` 捕获的比较。 |
| `_signature` | 方法（`_AddRecordDialogState`） | B | 构建每个可编辑字段当前值的 `formSignature` 快照。 |
| [`_submit`](#submit) | 方法（`_AddRecordDialogState`） | A | 解析/规范化时长和抽插次数、构建结果 `IntimacyRecord` 并带它弹出对话框。 |

`grep -c 'Purpose:' lib/features/intimacy/widgets/add_record_dialog.dart` 报告 9，与上面计数的全部 9 个真实声明精确匹配（2 个 Tier A、7 个 Tier B）。每个 `/// Purpose:` 块都恰好位于其文档化的真实声明正上方——未发现错附块，也未发现未文档化的真实声明。类字段本身（`AddRecordDialog` 和 `_AddRecordDialogState` 上的所有 `final`/`late` 字段）是普通数据持有者，不计为声明。

## 文档

### `void initState()` <a id="initstate"></a>
- **种类：** `_AddRecordDialogState` 的方法（`State.initState` 的覆盖）
- **来源：** `lib/features/intimacy/widgets/add_record_dialog.dart`（第 78 行）
- **用途：** 从被编辑记录（`widget.record`）或对话框初始选择构造函数参数播种每个可编辑字段，应用独自/抽插单位/时长默认规则，并捕获初始脏检查签名。
- **输入：** 无直接——读取 `widget.record`、`widget.initialPartnerId`、`widget.initialToyIds`、`widget.initialThrustCount`、`widget.initialThrustCountUnit`、`widget.prefillDuration` 和 `widget.partners`。
- **返回：** 无。
- **副作用：** 构造全部五个 `TextEditingController`；设置其他每个可变状态字段；计算并存储 `_initialSignature`。
- **算法：**
  1. `_isSolo = r?.isSolo ?? (widget.initialPartnerId == null && widget.partners.isEmpty)` — 添加时（无记录），只有未预选伴侣且根本没有伴侣可选时才默认独自。
  2. `_selectedPartnerId = r?.partnerId ?? widget.initialPartnerId` — 编辑时，逐字取记录的存储 `partnerId`，无论该 id 是否仍在 `widget.partners` 中。
  3. `_selectedToyIds`/`_selectedPositionIds` 从记录的 id 或初始选择参数播种；`_locationController`/`_notesController` 从记录文本或空播种。
  4. `_pleasureLevel` 默认 `3`；`initMinutes` 默认 `r?.duration.inMinutes ?? 15`。
  5. `initialThrustCount = r?.thrustCount ?? widget.initialThrustCount`；抽插次数控制器文本只在值非 null 且 `> 0` 时是该值的字符串形式，否则空。`_thrustCountUnit` 级联 `r?.thrustCountUnit ?? widget.initialThrustCountUnit ?? 100`。
  6. `_datetime` 默认 `r?.datetime ?? DateTime.now()`；三个布尔标志（`_hadOrgasm`/`_watchedPorn`/`_usedCondom`）添加时默认 `false`。
  7. `widget.prefillDuration != null && r == null`（从完成的计时器预填的新记录，绝不是编辑）时，用 `widget.prefillDuration!.inMinutes.clamp(0, 5999)` 覆盖 `initMinutes`。
  8. 从 `initMinutes ~/ 60` 和 `initMinutes % 60` 构建小时/分钟控制器。
  9. 非独自、尚未选伴侣且 `widget.partners` 非空时，把 `_selectedPartnerId` 默认 `widget.partners.first.id`。
  10. `_initialSignature = _signature()` — 最后捕获，在上面每个字段都有最终初始值之后，使未保存变更守卫有准确基线。
- **用法：**
  ```dart
  // Editing an existing record (views/intimacy_page.dart, lines 505-511):
  final activePartners = _partners.where((p) => p.endDate == null).toList();
  final updated = await showDialog<IntimacyRecord>(
    context: context,
    builder: (_) => AddRecordDialog(
      record: record,
      partners: activePartners,
      toys: activeToys,
      positions: _positions,
    ),
  );
  ```
- **备注：** 这是 [亲密](../../../../features/intimacy.md#deleted-partner-handling) 的"编辑伴侣已被删除的记录会构建并保留未触碰的伴侣 id"行为实际开始的地方：第 2 步无条件把 `r.partnerId` 复制进 `_selectedPartnerId`，即使调用方的 `activePartners` 列表（用 `.where((p) => p.endDate == null)` 构建）可能已排除该伴侣，或伴侣已被直接删除、完全不在 `widget.partners` 中。`initState` 中没有东西把 `_selectedPartnerId` 与 `widget.partners` 交叉检查——那个检查只在 `build()` 的下拉 `initialValue`（`widget.partners.any((p) => p.id == _selectedPartnerId) ? _selectedPartnerId : null`）中表面性发生，它只影响下拉显示什么，不影响底层 `_selectedPartnerId` 字段本身。

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **种类：** `_AddRecordDialogState` 的方法
- **来源：** `lib/features/intimacy/widgets/add_record_dialog.dart`（第 512 行）
- **用途：** 解析时长和抽插次数文本字段、把空/零/不可解析输入规范化为缺席、构建结果 `IntimacyRecord`——编辑时保留原始 id 和任何未触碰（可能悬空）的伴侣 id——并带它弹出对话框。
- **输入：** `guard` — 用于带结果关闭对话框的 `UnsavedChangesController`。
- **返回：** 无。
- **副作用：** 调用 `guard.pop(record)`。
- **算法：**
  1. 对两个控制器经 `int.tryParse` 解析 `hours`/`minutes`，失败各默认 `0`。
  2. `totalMinutes = (hours * 60 + minutes).clamp(0, 5999)`——与 `initState` 中从 `prefillDuration` 播种时使用的相同 5999 分钟（约 99 小时 59 分）上限。
  3. 从控制器修剪文本解析 `thrustCount`；解析值 `> 0` 前规范化为 `null`（因此 `"0"`、空白或不可解析文本都表示"未记录"）。
  4. 构建 `IntimacyRecord`：`id: widget.record?.id`（编辑时保留 id，添加时让模型分配）；`type` 从 `_isSolo` 为 `'Solo'` 或 `'Regular'`；`partnerId: _isSolo ? null : _selectedPartnerId`——读取 `initState`/下拉 `onChanged` 设置的状态字段，不是从 `widget.partners` 重新派生的任何东西；`duration: Duration(minutes: totalMinutes)`；解析的 `thrustCount`/`_thrustCountUnit`；`_datetime`；`toyIds`/`positionIds` 来自所选集合；三个布尔标志；`location`/`notes` 为修剪控制器文本，修剪为空时为 `null`。
  5. `guard.pop(record)`——关闭对话框，把 `record` 作为 `showDialog` 结果返回。
- **用法：**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(l10n.commonSave),
  ),
  ```
  （`build`，第 464-467 行。）
- **备注：** `partnerId` 直接从 `_selectedPartnerId` 写入，不重新对照 `widget.partners` 校验——如果用户编辑期间从不打开伴侣下拉框（因此 `onChanged` 从不触发），`initState` 中从记录原始 `partnerId` 设置的值原样流过，即使那个伴侣已不在 `widget.partners` 中。这是已删除伴侣容忍行为背后的具体机制；没有单独的"恢复"步骤，因为 id 从一开始就根本未被清除。

## 相关页面

- [亲密](../../../../features/intimacy.md#deleted-partner-handling) — 此对话框 `initState`/`_submit` 对实现的已删除伴侣容忍，以及 `IntimacyRecord` 行为何保持悬空 `partnerId` 而非被重新分配或丢弃。
- [`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md) — `_hasUnsavedChanges`/`_signature` 背后以及包装此对话框 `Dialog` 内容的取消确认流程的共享脏检查模式。
- [`weight_page.dart`](../../../../functions/features/weight/views/weight_page.md) — 使用相同 `initState`/`_signature`/`_hasUnsavedChanges`/`_submit` 形态的另一个增/改对话框（`_WeightRecordDialog`）。
- [`timer_page.dart`](timer_page.md) — 完成的秒表会话后用 `prefillDuration`/`initialThrustCount`/`initialThrustCountUnit` 调用此对话框。
