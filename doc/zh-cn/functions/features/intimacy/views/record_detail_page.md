# lib/features/intimacy/views/record_detail_page.dart

`RecordDetailPage`（v1.5.5）是一条 `IntimacyRecord` 的只读视图，见 [亲密 — 记录详情页](../../../../features/intimacy.md#record-detail-page)。在亲密主页或伴侣/玩具详情页上点击记录条目会推入它（见 [`_openRecordDetail`](intimacy_page.md#openrecorddetail-main)）。它显示一张头部卡片（伴侣或独自、日期和时间、愉悦星级）、三个主要数字（`HH:MM:SS` 形式的时长、抽插次数、抽插速率）、记录至少有两次计时器按下时的 [抽插时间线图表](../widgets/thrust_timeline_chart.md)、玩具、姿势、高潮/色情/安全套标记、地点和备注。编辑和删除位于应用栏，并通过两个回调**委托给调用方**，因此本页不拥有持久化，复用每个调用方自己的编辑器、保存路径和过滤行为。主体以 `readingMaxContentWidth` 限宽且没有分栏闸门（[自适应布局](../../../../adaptive-layout.md#rule-d--what-a-page-does-with-width-it-cannot-split)）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `RecordEditCallback` | typedef | B | `Future<IntimacyRecord?> Function(IntimacyRecord)`：打开调用方的编辑器并保存；返回保存后的记录，取消时为 null。 |
| `RecordDeleteCallback` | typedef | B | `Future<void> Function(IntimacyRecord)`：移除记录并保存。 |
| `RecordDetailPage({record, partners, toys, positions, onEdit, onDelete})` | 构造函数（`RecordDetailPage`） | B | 创建记录详情页。 |
| `RecordDetailPage.createState` | 方法（`RecordDetailPage`） | B | 创建可变 `_RecordDetailPageState`。 |
| `initState` | 方法（`_RecordDetailPageState`） | B | 把 `widget.record` 复制到 `_record`，使编辑能就地重新渲染。 |
| [`_edit`](#edit) | 方法（`_RecordDetailPageState`） | A | 经调用方编辑记录并显示结果。 |
| [`_delete`](#delete) | 方法（`_RecordDetailPageState`） | A | 确认、经调用方删除记录并关闭页面。 |
| `_formatDuration` | 静态方法（`_RecordDetailPageState`） | B | 把时长格式化为 `HH:MM:SS`，与计时器页一致。 |
| [`build`](#build) | 方法（`_RecordDetailPageState`） | A | 为当前记录构建页面。 |
| `_HeaderCard({record, partner})` | 构造函数（`_HeaderCard`） | B | 创建头部卡片。 |
| [`_HeaderCard.build`](#headercard-build) | 方法（`_HeaderCard`） | A | 显示谁、何时以及愉悦评分。 |
| `_StatTile({icon, label, value})` | 构造函数（`_StatTile`） | B | 创建一个主要数字。 |
| `_StatTile.build` | 方法（`_StatTile`） | B | 构建固定宽度（150）的卡片，含图标、标签和等宽数字的值。 |
| `_Section({title, child})` | 构造函数（`_Section`） | B | 创建带标题的卡片分区。 |
| `_Section.build` | 方法（`_Section`） | B | 构建一张小标题在内容上方的卡片。 |
| `_FlagTile({icon, label, value})` | 构造函数（`_FlagTile`） | B | 创建一个是/否行。 |
| `_FlagTile.build` | 方法（`_FlagTile`） | B | 构建带勾选或空心圆标记的紧凑 `ListTile`。 |
| `_ToyChip({toy})` | 构造函数（`_ToyChip`） | B | 创建玩具 chip。 |
| `_ToyChip.build` | 方法（`_ToyChip`） | B | 构建 chip：玩具图片能解析时用图片头像，否则用 emoji 标签。 |

**对账：** `grep -c 'Purpose:' lib/features/intimacy/views/record_detail_page.dart` 报告 17，对应 19 行。两个 typedef 带普通 `///` 注释而不是 `Purpose:` 块；它们属于文件的公开表面，所以占行。每个 `/// Purpose:` 块都紧贴在它所记录的声明上方。Tier 划分：4 个 Tier A、15 个 Tier B。

## 文档

### `Future<void> _edit()` <a id="edit"></a>
- **种类：** `_RecordDetailPageState` 的方法
- **来源：** `lib/features/intimacy/views/record_detail_page.dart`（第 76 行）
- **用途：** 对所显示的记录运行调用方的编辑流程，并用结果刷新页面。
- **输入：** 无（读取 `_record`、`widget.onEdit`）。
- **返回：** `Future<void>`。
- **副作用：** `onEdit` 所做的一切（打开 `AddRecordDialog`、保存）；返回了记录且页面仍 mounted 时，`setState` 替换 `_record`。
- **算法：** `updated = await widget.onEdit(_record)`；非 null 且 mounted 时 `_record = updated`。
- **用法：** 应用栏的编辑 `IconButton`（`onPressed: _edit`，第 138 行）。
- **备注：** 页面保留自己的 `_record` 副本正是为此：调用方的列表经它自己的保存路径更新，而详情页无需重新推入就显示编辑结果。取消的编辑返回 `null`，页面不变。两个调用方都传入自己的 `_editRecord`，自 v1.5.5 起它为此返回 `Future<IntimacyRecord?>`。

### `Future<void> _delete()` <a id="delete"></a>
- **种类：** `_RecordDetailPageState` 的方法
- **来源：** `lib/features/intimacy/views/record_detail_page.dart`（第 86 行）
- **用途：** 确认后删除所显示的记录并离开页面。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 显示共享的 `confirmDelete` 对话框；调用 `widget.onDelete`；弹出页面。
- **算法：** `confirmDelete(context, l10n.commonThisRecord)`；未确认或不再 mounted 时返回；`await widget.onDelete(_record)`；仍 mounted 时弹出。
- **用法：** 应用栏的删除 `IconButton`（`onPressed: _delete`，第 143 行）。
- **备注：** 确认在这里、在回调之前进行，因为调用方的 `_deleteRecord` 方法自己不做任何确认——在列表上那是滑动的 `confirmDismiss`。两个调用方都把同步的 `_deleteRecord` 包装为 `(r) async => _deleteRecord(r)`。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `_RecordDetailPageState` 的方法（`State.build` 的覆盖）
- **来源：** `lib/features/intimacy/views/record_detail_page.dart`（第 113 行）
- **用途：** 排布关于一次会话所记录的全部内容。
- **输入：** `context`；读取 `_record` 以及组件的 `partners`、`toys`、`positions`。
- **返回：** 一个 `Scaffold`。
- **副作用：** 无。
- **算法：**
  1. 按 id 从组件的列表中解析伴侣（按 `partnerId` 取 `firstOrNull`）、玩具和姿势；匹配不到的 id 被跳过。
  2. 应用栏：标题 `intimacyRecordDetail`，编辑和删除操作（提示为 `commonEdit`/`commonDelete`）。
  3. 主体：`SingleChildScrollView(padding: 16)` › `Center` › `ConstrainedBox(maxWidth: readingMaxContentWidth)` › 一个拉伸的 `Column`，包含：
     - `_HeaderCard`；
     - 三个 `_StatTile` 组成的 `Wrap`：时长（`_formatDuration`）、抽插次数（`'<thrustCount> x<thrustCountUnit>'`，缺失或为零时为 `intimacyNotRecorded`）和抽插速率（来自 `IntimacyRecord.thrustsPerMinute` 的 `'<四舍五入的速率>/min'`，或 `intimacyNotRecorded`）；
     - `record.hasThrustTimeline` 时，一张标题为 `intimacyThrustTimeline`、内含 `ThrustTimelineChart(timeline, duration)` 的卡片；
     - `_Section` 中的玩具（`_ToyChip`）和姿势（带 emoji 的 `Chip`），各自仅在非空时显示；
     - 三个 `_FlagTile` 组成的卡片：`intimacyOrgasmStatus`、`intimacyWatchedPornStatus`、`intimacyUsedCondomStatus`；
     - 地点（`intimacyDetailLocation`）和备注（`intimacyDetailNotes`，以 `SelectableText` 显示）分区，各自仅在已设置时显示。
- **用法：** `_openRecordDetail` 推入页面后由 Flutter 构建。
- **备注：** 限宽、无闸门：单列卡片从分栏中得不到任何好处，低于 840 逻辑像素时页面不受影响。限宽是滚动视图内部的普通 `Center` › `ConstrainedBox`，而不是共享的 `AdaptiveContentWidth` 组件；效果相同，滚动手势仍覆盖整个窗口。调用方传入**所有**伴侣和玩具，包括已结束和已退役的，使旧记录仍显示其名称；已删除的伴侣在头部回退为通用的 `intimacyPartner` 标题。

### `Widget build(BuildContext context)`（`_HeaderCard`） <a id="headercard-build"></a>
- **种类：** `_HeaderCard` 的方法
- **来源：** `lib/features/intimacy/views/record_detail_page.dart`（第 296 行）
- **用途：** 在页面顶部显示会话的谁、何时和愉悦评分。
- **输入：** `context`；`record`、解析出的 `partner`。
- **返回：** 一张 `Card`，含前置头像、标题和日期列，以及尾随星级。
- **副作用：** 经 `ImageService.resolve`（一个 `FutureBuilder`）从 blob 存储解析伴侣图片。
- **算法：** 独自记录的标题为 `intimacySolo`，伴侣未知时为 `intimacyPartner`，否则为伴侣的 emoji 和名称。头像在伴侣图片解析为存在的文件时是半径 20 的 `CircleAvatar`，否则是人形（独自）或心形图标。日期行为 `DateFormat.yMMMd(localeName).add_Hm()`。星级为 `★` × `pleasureLevel` 再补 `☆` 到五个，带 `intimacyPleasure` 提示。
- **用法：** `build` 顶部的 `_HeaderCard(record: record, partner: partner)`。
- **备注：** 与记录列表条目的头像回退方式一致，使同一条记录在两处看起来相同。

## 相关页面

- [亲密 — 记录详情页](../../../../features/intimacy.md#record-detail-page)。
- [`intimacy_page.dart`](intimacy_page.md) — 两个 `_openRecordDetail` 调用方，以及它们作为 `onEdit` / `onDelete` 传入的 `_editRecord` / `_deleteRecord` 方法。
- [`thrust_timeline_chart.dart`](../widgets/thrust_timeline_chart.md) — 图表卡片。
- [`intimacy_record.dart`](../models/intimacy_record.md) — `hasThrustTimeline`、`thrustsPerMinute`。
- [`delete_confirm.dart`](../../../shared/widgets/delete_confirm.md) — `_delete` 使用的共享确认。
