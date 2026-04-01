import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/task.dart';

class TaskSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Task> tasks;
  final void Function(Task task)? onToggle;
  final void Function(Task task)? onDelete;
  final void Function(Task task)? onEdit;
  final void Function(Task task, SubTask subtask)? onSubtaskToggle;

  const TaskSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
    this.onToggle,
    this.onDelete,
    this.onEdit,
    this.onSubtaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${tasks.where((t) => t.isCompleted).length}/${tasks.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(context)?.todoNoTasks ?? 'No tasks yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ...tasks.map((task) => _TaskTile(
                key: ValueKey(task.id),
                task: task,
                onToggle: onToggle != null ? () => onToggle!(task) : null,
                onDelete: onDelete != null ? () => onDelete!(task) : null,
                onEdit: onEdit != null ? () => onEdit!(task) : null,
                onSubtaskToggle: onSubtaskToggle != null
                    ? (sub) => onSubtaskToggle!(task, sub)
                    : null,
              )),
      ],
    );
  }
}

class _TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final void Function(SubTask subtask)? onSubtaskToggle;

  const _TaskTile({
    super.key,
    required this.task,
    this.onToggle,
    this.onDelete,
    this.onEdit,
    this.onSubtaskToggle,
  });

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    final hasSubtasks = task.subtasks.isNotEmpty;
    final completedSubs = task.subtasks.where((s) => s.isCompleted).length;

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
          subtitle: hasSubtasks
              ? Text(
                  'Subtasks: $completedSubs/${task.subtasks.length}',
                  style: theme.textTheme.bodySmall,
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
                  .map((sub) => Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: sub.isCompleted,
                              onChanged: (_) =>
                                  widget.onSubtaskToggle?.call(sub),
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
                      ))
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
        return confirmDelete(context, 'this task');
      },
      onDismissed: (_) => widget.onDelete?.call(),
      child: tile,
    );
  }
}
