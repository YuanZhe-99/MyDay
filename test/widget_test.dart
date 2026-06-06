import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_day/app/app.dart';
import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/shared/services/reminder_service.dart';
import 'package:my_day/shared/services/sync_merge.dart';
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

  test('DailyScoreLog defaults, clamps, and preserves explicit zero', () {
    final date = DateTime(2026, 6, 3);
    final log = DailyScoreLog();

    expect(log.scoreFor(date), 0);

    log.setScore(date, 9, modifiedAt: DateTime.parse('2026-06-03T08:00:00Z'));
    expect(log.scoreFor(date), 5);

    log.setScore(date, 0, modifiedAt: DateTime.parse('2026-06-03T09:00:00Z'));
    final json = log.toJson();
    final entry = json['2026-06-03'] as Map<String, dynamic>;
    final restored = DailyScoreLog.fromJson(json);

    expect(entry['score'], 0);
    expect(restored.scoreFor(date), 0);
  });

  test('DailyScoreLog merge keeps the latest score per date', () {
    final date = DateTime(2026, 6, 3);
    final local = DailyScoreLog()
      ..setScore(date, 1, modifiedAt: DateTime.parse('2026-06-03T08:00:00Z'));
    final remote = DailyScoreLog()
      ..setScore(date, -2, modifiedAt: DateTime.parse('2026-06-03T09:00:00Z'));

    final merged = DailyScoreLog.merge(local, remote);

    expect(merged.scoreFor(date), -2);
  });

  test('TodoData serializes daily scores', () {
    final date = DateTime(2026, 6, 3);
    final scores = DailyScoreLog()
      ..setScore(date, 4, modifiedAt: DateTime.parse('2026-06-03T08:00:00Z'));
    final data = TodoData(
      dailyTemplates: [],
      oneTimeTasks: [],
      dailyLog: DailyCompletionLog(),
      dailyScores: scores,
    );

    final restored = TodoData.fromJson(data.toJson());

    expect(restored.dailyScores.scoreFor(date), 4);
  });

  test('Todo sync merge keeps the newest daily score', () {
    final date = DateTime(2026, 6, 3);
    final localScores = DailyScoreLog()
      ..setScore(date, 2, modifiedAt: DateTime.parse('2026-06-03T08:00:00Z'));
    final remoteScores = DailyScoreLog()
      ..setScore(date, -3, modifiedAt: DateTime.parse('2026-06-03T09:00:00Z'));
    final local = TodoData(
      dailyTemplates: [],
      oneTimeTasks: [],
      dailyLog: DailyCompletionLog(),
      dailyScores: localScores,
    );
    final remote = TodoData(
      dailyTemplates: [],
      oneTimeTasks: [],
      dailyLog: DailyCompletionLog(),
      dailyScores: remoteScores,
    );

    final mergedJson = mergeTodoJson(
      jsonEncode(local.toJson()),
      jsonEncode(remote.toJson()),
      null,
    );
    final merged = TodoData.fromJson(
      jsonDecode(mergedJson!) as Map<String, dynamic>,
    );

    expect(merged.dailyScores.scoreFor(date), -3);
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

  test('WeightData inherits latest positive body measurements by field', () {
    final records = [
      WeightRecord(
        id: 'weight-measurement-1',
        weight: 65,
        bustCm: 88,
        waistCm: 70,
        hipCm: 92,
        datetime: DateTime.parse('2026-05-01T08:00:00Z'),
        modifiedAt: DateTime.parse('2026-05-01T08:30:00Z'),
      ),
      WeightRecord(
        id: 'weight-measurement-2',
        weight: 64.5,
        waistCm: 69,
        datetime: DateTime.parse('2026-05-05T08:00:00Z'),
        modifiedAt: DateTime.parse('2026-05-05T08:30:00Z'),
      ),
      WeightRecord(
        id: 'weight-measurement-3',
        weight: 64,
        bustCm: 87,
        datetime: DateTime.parse('2026-05-10T08:00:00Z'),
        modifiedAt: DateTime.parse('2026-05-10T08:30:00Z'),
      ),
    ];

    final afterWaistOnly = WeightData.effectiveMeasurementsUpTo(
      records,
      DateTime.parse('2026-05-05T08:00:00Z'),
    );
    final afterLaterBust = WeightData.effectiveMeasurementsUpTo(
      records,
      DateTime.parse('2026-05-10T08:00:00Z'),
    );

    expect(afterWaistOnly.bustCm, 88);
    expect(afterWaistOnly.waistCm, 69);
    expect(afterWaistOnly.hipCm, 92);
    expect(afterLaterBust.bustCm, 87);
    expect(afterLaterBust.waistCm, 69);
    expect(afterLaterBust.hipCm, 92);
    expect(records[1].bustCm, isNull);
    expect(records[1].hipCm, isNull);
  });

  test('WeightData builds inherited body measurement timeline', () {
    final records = [
      WeightRecord(
        id: 'weight-timeline-2',
        weight: 64.5,
        waistCm: 69,
        datetime: DateTime.parse('2026-05-05T08:00:00Z'),
        modifiedAt: DateTime.parse('2026-05-05T08:30:00Z'),
      ),
      WeightRecord(
        id: 'weight-timeline-1',
        weight: 65,
        bustCm: 88,
        waistCm: 70,
        hipCm: 92,
        datetime: DateTime.parse('2026-05-01T08:00:00Z'),
        modifiedAt: DateTime.parse('2026-05-01T08:30:00Z'),
      ),
      WeightRecord(
        id: 'weight-timeline-3',
        weight: 64,
        bustCm: 87,
        datetime: DateTime.parse('2026-05-10T08:00:00Z'),
        modifiedAt: DateTime.parse('2026-05-10T08:30:00Z'),
      ),
    ];

    final timeline = WeightData.effectiveMeasurementTimeline(records);

    expect(timeline.map((point) => point.datetime.day), [1, 5, 10]);
    expect(timeline[0].bustCm, 88);
    expect(timeline[0].waistCm, 70);
    expect(timeline[0].hipCm, 92);
    expect(timeline[1].bustCm, 88);
    expect(timeline[1].waistCm, 69);
    expect(timeline[1].hipCm, 92);
    expect(timeline[2].bustCm, 87);
    expect(timeline[2].waistCm, 69);
    expect(timeline[2].hipCm, 92);
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
    expect(
      ReminderService.firstOneTimeReminderDateTime(task),
      DateTime(2026, 6, 10, 9),
    );
    expect(
      ReminderService.shouldUseDailyMobileOneTimeReminder(
        task,
        DateTime(2026, 6, 9, 12),
      ),
      isFalse,
    );
    expect(
      ReminderService.shouldUseDailyMobileOneTimeReminder(
        task,
        DateTime(2026, 6, 10, 8),
      ),
      isTrue,
    );
    expect(
      ReminderService.shouldUseDailyMobileOneTimeReminder(
        task,
        DateTime(2026, 6, 11, 8),
      ),
      isTrue,
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
