import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_day/app/app.dart';
import 'package:my_day/features/todo/models/task.dart';

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
