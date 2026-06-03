import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_day/app/app.dart';
import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/shared/services/reminder_service.dart';
import 'package:my_day/features/weight/models/weight_record.dart';

/// Purpose: Initialize startup services and launch the app entry point.
/// Inputs: None.
/// Returns: None.
/// Side effects: May update UI state or trigger user-facing flows.
/// Notes: None.
void main() {
  test('Task note serializes and deserializes', () {
    final task = Task(
      title: 'Plan release',
      note: 'Double-check installer version',
      type: TaskType.workOnce,
    );

    final restored = Task.fromJson(task.toJson());

    expect(restored.note, 'Double-check installer version');
  });

  test('WeightRecord serializes optional body measurements', () {
    final record = WeightRecord(
      id: 'weight-1',
      weight: 65.4,
      bustCm: 88.0,
      waistCm: 70.5,
      hipCm: 92.0,
      datetime: DateTime.parse('2026-05-28T08:00:00Z'),
      modifiedAt: DateTime.parse('2026-05-28T08:30:00Z'),
    );

    final restored = WeightRecord.fromJson(record.toJson());

    expect(restored.bustCm, 88.0);
    expect(restored.waistCm, 70.5);
    expect(restored.hipCm, 92.0);
  });

  test('WeightRecord omits absent body measurements', () {
    final record = WeightRecord(
      id: 'weight-2',
      weight: 66,
      datetime: DateTime.parse('2026-05-28T08:00:00Z'),
      modifiedAt: DateTime.parse('2026-05-28T08:30:00Z'),
    );

    final json = record.toJson();
    final restored = WeightRecord.fromJson(json);

    expect(json.containsKey('bustCm'), isFalse);
    expect(json.containsKey('waistCm'), isFalse);
    expect(json.containsKey('hipCm'), isFalse);
    expect(restored.bustCm, isNull);
    expect(restored.waistCm, isNull);
    expect(restored.hipCm, isNull);
  });

  test('WeightData calculates waist-hip ratio from positive measurements', () {
    expect(WeightData.calculateWaistHipRatio(70, 92), closeTo(0.7609, 0.0001));
    expect(WeightData.calculateWaistHipRatio(null, 92), isNull);
    expect(WeightData.calculateWaistHipRatio(70, null), isNull);
    expect(WeightData.calculateWaistHipRatio(0, 92), isNull);
    expect(WeightData.calculateWaistHipRatio(70, 0), isNull);
  });

  test('One-time todo reminders start on scheduled date and repeat daily', () {
    final task = Task(
      title: 'Prepare report',
      type: TaskType.workOnce,
      scheduledDate: DateTime(2026, 6, 10),
      reminderTime: DateTime(2026, 6, 1, 9),
    );

    expect(
      ReminderService.shouldNotifyOneTimeTask(task, DateTime(2026, 6, 9, 9)),
      isFalse,
    );
    expect(
      ReminderService.shouldNotifyOneTimeTask(task, DateTime(2026, 6, 10, 9)),
      isTrue,
    );
    expect(
      ReminderService.shouldNotifyOneTimeTask(task, DateTime(2026, 6, 11, 9)),
      isTrue,
    );
    expect(
      ReminderService.nextOneTimeReminderDateTime(
        task,
        DateTime(2026, 6, 9, 12),
      ),
      DateTime(2026, 6, 10, 9),
    );
    expect(
      ReminderService.nextOneTimeReminderDateTime(
        task,
        DateTime(2026, 6, 10, 10),
      ),
      DateTime(2026, 6, 11, 9),
    );
  });

  testWidgets('App launches and shows Todo tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyDayApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Todo'), findsWidgets);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Intimacy'), findsNothing); // Hidden by default
    expect(find.text('Settings'), findsOneWidget);
  });
}
