import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/task.dart';

class AddTaskDialog extends StatefulWidget {
  final DateTime? defaultDate;
  const AddTaskDialog({super.key, this.defaultDate});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _subtaskController = TextEditingController();
  TaskType _selectedType = TaskType.routineOnce;
  TimeOfDay? _reminderTime;
  String? _selectedEmoji;
  final List<String> _subtaskTitles = [];

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
            Text(
              l10n.todoAddTask,
              style: theme.textTheme.titleLarge,
            ),
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
                      border: Border.all(
                        color: theme.colorScheme.outline,
                      ),
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

            // Reminder time (optional)
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

            // Subtasks
            if (_subtaskTitles.isNotEmpty) ...[
              Text(l10n.todoSubtasks, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              ..._subtaskTitles.asMap().entries.map((entry) => Row(
                    children: [
                      const Icon(Icons.check_box_outline_blank, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() => _subtaskTitles.removeAt(entry.key));
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
                  child: const Text('Add'),
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
      _subtaskTitles.add(text);
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

    final task = Task(
      title: title,
      emoji: _selectedEmoji,
      type: _selectedType,
      reminderTime: reminder,
      subtasks: _subtaskTitles.map((t) => SubTask(title: t)).toList(),
      scheduledDate: _selectedType != TaskType.daily
          ? widget.defaultDate ?? DateTime.now()
          : null,
      startDate: _selectedType == TaskType.daily
          ? widget.defaultDate ?? DateTime.now()
          : null,
    );
    Navigator.pop(context, task);
  }
}
