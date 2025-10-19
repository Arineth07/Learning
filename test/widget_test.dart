// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tutor_app/main.dart';

void main() {
  testWidgets('Placeholder home screen smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AITutorApp());

    // Verify that the app title is displayed
    expect(find.text('AI Tutor App'), findsOneWidget);
    expect(find.text('Under Development'), findsOneWidget);

    // Verify that the school icon is present
    expect(find.byIcon(Icons.school), findsOneWidget);

    // Verify that the loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify that the setup message is displayed
    expect(
      find.text('Setting up your personalized learning experience...'),
      findsOneWidget,
    );
  });
}
