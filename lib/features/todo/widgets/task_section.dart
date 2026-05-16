import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/task.dart';

class TaskSectionWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Task> tasks;
  final TaskType taskType;
  final String sortMode;
  final ValueChanged<String>? onSortModeChanged;
  final void Function(List<Task> tasks, int oldIndex, int newIndex)? onReorder;
  final void Function(Task task)? onToggle;
  final void Function(Task task)? onDelete;
  final void Function(Task task)? onEdit;
  final void Function(Task task, SubTask subtask)? onSubtaskToggle;

  /// Purpose: Create a task section widget instance.
  /// Inputs: None.
  /// Returns: A new `TaskSectionWidget` instance.
  /// Side effects: None.
  /// Notes: None.
  const TaskSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.taskType,
    required this.sortMode,
    this.onSortModeChanged,
    this.onReorder,
    this.onToggle,
    this.onDelete,
    this.onEdit,
    this.onSubtaskToggle,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<TaskSectionWidget> createState() => _TaskSectionWidgetState();
}

class _TaskSectionWidgetState extends State<TaskSectionWidget> {
  bool _reordering = false;

  static const _sortCreated = 'createdDate';
  static const _sortDue = 'dueDate';
  static const _sortName = 'name';
  static const _sortCustom = 'custom';

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCustom = widget.sortMode == _sortCustom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: widget.color),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.tasks.where((t) => t.isCompleted).length}/${widget.tasks.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isCustom && widget.tasks.length > 1)
                IconButton(
                  icon: Icon(_reordering ? Icons.check : Icons.reorder),
                  tooltip: _reordering
                      ? l10n.financeSortDone
                      : l10n.financeSortReorder,
                  onPressed: () => setState(() => _reordering = !_reordering),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: l10n.todoSortBy,
                onSelected: (mode) {
                  if (mode != _sortCustom) {
                    setState(() => _reordering = false);
                  }
                  widget.onSortModeChanged?.call(mode);
                },
                itemBuilder: (_) => [
                  _sortItem(value: _sortCreated, label: l10n.todoSortByAdded),
                  _sortItem(value: _sortDue, label: l10n.todoSortByDueDate),
                  _sortItem(value: _sortName, label: l10n.todoSortByName),
                  _sortItem(value: _sortCustom, label: l10n.todoSortCustom),
                ],
              ),
            ],
          ),
        ),
        if (widget.tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.todoNoTasks,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          )
        else if (_reordering && isCustom)
          _TaskReorderList(tasks: widget.tasks, onReorder: widget.onReorder)
        else
          ...widget.tasks.map(
            (task) => _TaskTile(
              key: ValueKey(task.id),
              task: task,
              onToggle: widget.onToggle != null
                  ? () => widget.onToggle!(task)
                  : null,
              onDelete: widget.onDelete != null
                  ? () => widget.onDelete!(task)
                  : null,
              onEdit: widget.onEdit != null ? () => widget.onEdit!(task) : null,
              onSubtaskToggle: widget.onSubtaskToggle != null
                  ? (sub) => widget.onSubtaskToggle!(task, sub)
                  : null,
            ),
          ),
      ],
    );
  }

  /// Purpose: Provide the internal sort item helper for this file.
  /// Inputs: None.
  /// Returns: `PopupMenuEntry<String>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  PopupMenuEntry<String> _sortItem({
    required String value,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            widget.sortMode == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _TaskReorderList extends StatelessWidget {
  final List<Task> tasks;
  final void Function(List<Task> tasks, int oldIndex, int newIndex)? onReorder;

  /// Purpose: Create a task reorder list instance.
  /// Inputs: `onReorder`.
  /// Returns: A new `_TaskReorderList` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _TaskReorderList({required this.tasks, required this.onReorder});

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) =>
          onReorder?.call(tasks, oldIndex, newIndex),
      proxyDecorator: (child, index, animation) {
        return Material(elevation: 4, child: child);
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          key: ValueKey('task-reorder-${task.id}'),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          title: Text(
            task.emoji != null ? '${task.emoji} ${task.title}' : task.title,
          ),
          subtitle: task.dueDate != null
              ? Text(
                  '${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}',
                )
              : null,
        );
      },
    );
  }
}

class _TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final void Function(SubTask subtask)? onSubtaskToggle;

  /// Purpose: Create a task tile instance.
  /// Inputs: None.
  /// Returns: A new `_TaskTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _TaskTile({
    super.key,
    required this.task,
    this.onToggle,
    this.onDelete,
    this.onEdit,
    this.onSubtaskToggle,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _expanded = false;

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    final l10n = AppLocalizations.of(context)!;
    final hasSubtasks = task.subtasks.isNotEmpty;
    final completedSubs = task.subtasks.where((s) => s.isCompleted).length;
    final hasDueDate = task.dueDate != null && task.type != TaskType.daily;
    final note = task.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final isOverdue =
        hasDueDate &&
        !task.isCompleted &&
        DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        ).isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        );

    // Build subtitle parts
    final subtitleParts = <String>[];
    if (hasSubtasks) {
      subtitleParts.add(
        l10n.todoSubtasksProgress(completedSubs, task.subtasks.length),
      );
    }
    if (hasDueDate) {
      final dd = task.dueDate!;
      final dateStr =
          '${dd.year}-${dd.month.toString().padLeft(2, '0')}-${dd.day.toString().padLeft(2, '0')}';
      subtitleParts.add(l10n.todoTaskDue(dateStr));
    }
    if (hasNote) subtitleParts.add(l10n.todoTaskNote(note));

    final tile = Column(
      children: [
        ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => widget.onToggle?.call(),
            shape: const CircleBorder(),
          ),
          title: Text(
            task.emoji != null ? '${task.emoji} ${task.title}' : task.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: subtitleParts.isNotEmpty
              ? Text(
                  subtitleParts.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue ? theme.colorScheme.error : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.reminderTime != null)
                Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
              if (hasSubtasks)
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: hasSubtasks
              ? () => setState(() => _expanded = !_expanded)
              : null,
        ),
        if (_expanded && hasSubtasks)
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 16, bottom: 4),
            child: Column(
              children: task.subtasks
                  .map(
                    (sub) => Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: sub.isCompleted,
                            onChanged: (_) => widget.onSubtaskToggle?.call(sub),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: sub.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: sub.isCompleted
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );

    if (widget.onDelete == null && widget.onEdit == null) return tile;

    return Dismissible(
      key: ValueKey(task.id),
      direction: widget.onDelete != null && widget.onEdit != null
          ? DismissDirection.horizontal
          : widget.onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: theme.colorScheme.primary,
        child: Icon(Icons.edit_outlined, color: theme.colorScheme.onPrimary),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onEdit?.call();
          return false; // don't dismiss, just trigger edit
        }
        return confirmDelete(
          context,
          AppLocalizations.of(context)!.todoThisTask,
        );
      },
      onDismissed: (_) => widget.onDelete?.call(),
      child: tile,
    );
  }
}
