# lib/features/todo/widgets/task_section.dart

Renders one of the three Todo list sections (daily / routine-once / work-once) described in
[Todo](../../../../features/todo.md#ui): a header row with a completion counter, sort-mode menu,
and reorder toggle, followed by either the plain task list or a drag-reorderable list when the
section's sort mode is `custom`. Each task renders as a `_TaskTile` (checkbox, title, due-date/note
subtitle, expandable subtasks, and swipe-to-edit/swipe-to-delete via `Dismissible`). The widget is
purely presentational: all persistence and sort-mode state live in the parent (`todo_page.dart`),
which is wired in through the `onToggle`/`onDelete`/`onEdit`/`onSubtaskToggle`/`onReorder`/
`onSortModeChanged` callbacks.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TaskSectionWidget` (constructor) | constructor (`TaskSectionWidget`) | B | Create a task section widget instance. |
| `createState` | method (`TaskSectionWidget`) | B | Create the mutable `_TaskSectionWidgetState`. |
| `build` | method (`_TaskSectionWidgetState`) | B | Render the section header, sort menu, and task list (or reorder list). |
| `_sortItem` | method (widget helper, `_TaskSectionWidgetState`) | B | Build one `PopupMenuItem` row for the sort-mode menu. |
| `_TaskReorderList` (constructor) | constructor (`_TaskReorderList`) | B | Create a task reorder list instance. |
| `build` | method (`_TaskReorderList`) | B | Render the drag-reorderable list used when sort mode is `custom`. |
| `_TaskTile` (constructor) | constructor (`_TaskTile`) | B | Create a task tile instance. |
| `createState` | method (`_TaskTile`) | B | Create the mutable `_TaskTileState`. |
| `build` | method (`_TaskTileState`) | B | Render one task's checkbox/title/subtitle/subtasks and its swipe-to-edit/delete behavior. |

## Documentation

No Tier A declarations in this file — every declaration is widget construction or lifecycle
boilerplate with no branching/computation beyond building the UI tree from already-computed task
fields.

