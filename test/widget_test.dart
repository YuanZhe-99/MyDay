import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_day/app/app.dart';

void main() {
  testWidgets('App launches and shows Todo tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyDayApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('MyDay!!!!!'), findsOneWidget);
    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Intimacy'), findsNothing); // Hidden by default
    expect(find.text('Settings'), findsOneWidget);
  });
}
