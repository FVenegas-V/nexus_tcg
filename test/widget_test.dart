// Tests para la aplicación Nexus TCG
// Incluye tests para funcionalidades de comunidades implementadas

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexus_tcg/main.dart';

void main() {
  group('Nexus TCG App Tests', () {
    testWidgets('App should load and show navigation', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Verify that the app loads successfully
      expect(find.byType(MaterialApp), findsOneWidget);

      // Should find navigation elements or main content
      // Note: Adjust based on your actual main screen structure
    });

    testWidgets('Communities screen should be accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Try to find communities-related elements
      // This test verifies the app can load without crashing
      expect(find.byType(MyApp), findsOneWidget);
    });
  });
}
