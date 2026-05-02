// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_log_app/main.dart';

void main() {
  testWidgets('Quick Log app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickLogRoot());
    await tester.pumpAndSettle();

    // Verify that the app starts
    expect(find.text('Quick Log'), findsOneWidget);
  });

  testWidgets(
    'shows a sticky save action when the inline save button is off screen',
    (WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(390, 640)
        ..devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const QuickLogRoot());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.ensureVisible(find.text('Save Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Save Entry'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );
}
