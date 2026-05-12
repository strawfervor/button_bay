// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:button_bay/main.dart';

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ButtonBay'), findsOneWidget);
    expect(find.text('All apps'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Enter / A'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('B / Backspace'), findsOneWidget);
    expect(find.text('Back'), findsWidgets);
    expect(find.text('Tab / RT / RB'), findsOneWidget);
    expect(find.text('Change tab'), findsOneWidget);
  });
}
