import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/task.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final VoidCallback? onPermanentDelete;

  const EditTaskDialog({super.key, required this.task, this.onPermanentDelete});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _titleController;
  final _subtaskController = TextEditingController();
  late TaskType _selectedType;
  late TimeOfDay? _reminderTime;
  late String? _selectedEmoji;
  late List<SubTask> _subtasks;
  late DateTime? _scheduledDate;
  late DateTime? _completedDate;
  late DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t.title);
    _selectedType = t.type;
    _selectedEmoji = t.emoji;
    _reminderTime = t.reminderTime != null
        ? TimeOfDay.fromDateTime(t.reminderTime!)
        : null;
    _subtasks = List.of(t.subtasks);
    _scheduledDate = t.scheduledDate;
    _completedDate = t.completedDate;
    _startDate = t.startDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.todoEditTask, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // Title + Emoji
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showEmojiPicker(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _selectedEmoji != null
                          ? Text(
                              _selectedEmoji!,
                              style: const TextStyle(fontSize: 22),
                            )
                          : Icon(
                              Icons.add_reaction_outlined,
                              color: theme.colorScheme.outline,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.todoTitle,
                      hintText: 'What needs to be done?',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type selector
            SegmentedButton<TaskType>(
              segments: [
                ButtonSegment(
                  value: TaskType.daily,
                  label: Text(l10n.todoDailyTask),
                  icon: const Icon(Icons.repeat, size: 16),
                ),
                ButtonSegment(
                  value: TaskType.routineOnce,
                  label: Text(l10n.todoRoutineTask),
                  icon: const Icon(Icons.today, size: 16),
                ),
                ButtonSegment(
                  value: TaskType.workOnce,
                  label: Text(l10n.todoWorkTask),
                  icon: const Icon(Icons.work_outline, size: 16),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() => _selectedType = set.first);
              },
            ),
            const SizedBox(height: 12),

            // Reminder time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _reminderTime != null
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: _reminderTime != null ? theme.colorScheme.primary : null,
              ),
              title: Text(
                _reminderTime != null
                    ? 'Reminder: ${_reminderTime!.format(context)}'
                    : 'Add reminder (optional)',
              ),
              trailing: _reminderTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setState(() => _reminderTime = null),
                    )
                  : null,
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _reminderTime = time);
                }
              },
            ),
            const SizedBox(height: 12),

            // Scheduled date (for one-time tasks)
            if (_selectedType != TaskType.daily)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                  _scheduledDate != null
                      ? 'Scheduled: ${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2, '0')}-${_scheduledDate!.day.toString().padLeft(2, '0')}'
                      : 'Set scheduled date',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _scheduledDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _scheduledDate = picked);
                  }
                },
              ),

            // Completed date
            if (_selectedType != TaskType.daily && widget.task.isCompleted)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle,
                    color: theme.colorScheme.primary),
                title: Text(
                  _completedDate != null
                      ? 'Completed: ${_completedDate!.year}-${_completedDate!.month.toString().padLeft(2, '0')}-${_completedDate!.day.toString().padLeft(2, '0')}'
                      : 'Set completed date',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _completedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _completedDate = picked);
                  }
                },
              ),

            // Start date (editable, for daily tasks) / Created date (read-only, for others)
            if (_selectedType == TaskType.daily) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.play_arrow, color: theme.colorScheme.primary),
                title: Text(l10n.todoStartDate(
                  _startDate != null
                      ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                      : '${widget.task.createdDate.year}-${widget.task.createdDate.month.toString().padLeft(2, '0')}-${widget.task.createdDate.day.toString().padLeft(2, '0')}',
                )),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? widget.task.createdDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time, color: theme.colorScheme.outline),
                title: Text(l10n.todoCreatedDate(
                  '${widget.task.createdDate.year}-${widget.task.createdDate.month.toString().padLeft(2, '0')}-${widget.task.createdDate.day.toString().padLeft(2, '0')}',
                )),
              ),
            ],

            // Deleted date (read-only, only if soft-deleted)
            if (widget.task.deletedDate != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text(l10n.todoDeletedDate(
                  '${widget.task.deletedDate!.year}-${widget.task.deletedDate!.month.toString().padLeft(2, '0')}-${widget.task.deletedDate!.day.toString().padLeft(2, '0')}',
                )),
              ),

            // Permanent delete button (only if soft-deleted)
            if (widget.task.deletedDate != null && widget.onPermanentDelete != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: Text(l10n.todoPermanentDelete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.todoPermanentDelete),
                        content: Text(l10n.todoPermanentDeleteConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.commonCancel),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      widget.onPermanentDelete!();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ),

            // Subtasks
            if (_subtasks.isNotEmpty) ...[
              Text(l10n.todoSubtasks, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              ..._subtasks.asMap().entries.map((entry) => Row(
                    children: [
                      Icon(
                        entry.value.isCompleted
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value.title)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() => _subtasks.removeAt(entry.key));
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: InputDecoration(
                      hintText: l10n.todoAddSubtask,
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    style: theme.textTheme.bodyMedium,
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: _addSubtask,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.commonSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask(title: text));
      _subtaskController.clear();
    });
  }

  static const _commonEmojis = [
    '📝', '🏃', '📖', '💪', '🧘', '🎯', '📧', '☎️',
    '🛒', '🧹', '👨‍💻', '✍️', '📅', '🔧', '🎓', '💼',
    '🍳', '🚗', '💊', '🐕', '🏠', '🎵', '🎨', '📸',
    '💡', '🔬', '📊', '🗂️', '✈️', '💤', '🏋️', '🧑‍🍳',
  ];

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pick an icon',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _commonEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _commonEmojis[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _selectedEmoji = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Remove icon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    DateTime? reminder;
    if (_reminderTime != null) {
      final now = DateTime.now();
      reminder = DateTime(
        now.year,
        now.month,
        now.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
    }

    final updated = Task(
      id: widget.task.id,
      title: title,
      emoji: _selectedEmoji,
      type: _selectedType,
      isCompleted: widget.task.isCompleted,
      reminderTime: reminder,
      subtasks: _subtasks,
      createdDate: widget.task.createdDate,
      completedDate: _completedDate,
      scheduledDate: _selectedType != TaskType.daily
          ? _scheduledDate ?? DateTime.now()
          : null,
      deletedDate: widget.task.deletedDate,
      startDate: _selectedType == TaskType.daily ? _startDate : null,
    );
    Navigator.pop(context, updated);
  }
}
