# lib/features/todo/widgets/task_section.dart

渲染 [Todo](../../../../features/todo.md#ui) 描述的三个 Todo 列表小节之一（每日/日常一次/工作一次）：带完成计数器、排序模式菜单和重排切换的页头行，随后是小节排序模式为 `custom` 时的普通任务列表或拖拽重排列表。每个任务渲染为 `_TaskTile`（复选框、标题、截止日期/备注副标题、可展开子任务、经 `Dismissible` 的滑动编辑/滑动删除）。组件纯粹展示：所有持久化和排序模式状态都住在父级（`todo_page.dart`），经 `onToggle`/`onDelete`/`onEdit`/`onSubtaskToggle`/`onReorder`/`onSortModeChanged` 回调接入。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `TaskSectionWidget`（构造函数） | 构造函数（`TaskSectionWidget`） | B | 创建任务小节组件实例。 |
| `createState` | 方法（`TaskSectionWidget`） | B | 创建可变 `_TaskSectionWidgetState`。 |
| `build` | 方法（`_TaskSectionWidgetState`） | B | 渲染小节页头、排序菜单和任务列表（或重排列表）。 |
| `_sortItem` | 方法（组件辅助，`_TaskSectionWidgetState`） | B | 为排序模式菜单构建一个 `PopupMenuItem` 行。 |
| `_TaskReorderList`（构造函数） | 构造函数（`_TaskReorderList`） | B | 创建任务重排列表实例。 |
| `build` | 方法（`_TaskReorderList`） | B | 渲染排序模式为 `custom` 时使用的拖拽重排列表。 |
| `_TaskTile`（构造函数） | 构造函数（`_TaskTile`） | B | 创建任务块实例。 |
| `createState` | 方法（`_TaskTile`） | B | 创建可变 `_TaskTileState`。 |
| `build` | 方法（`_TaskTileState`） | B | 渲染一个任务的复选框/标题/副标题/子任务及其滑动编辑/删除行为。 |

## 文档

本文件无 Tier A 声明——每个声明都是组件构造或生命周期样板，除从已计算任务字段构建 UI 树外无分支/计算。

