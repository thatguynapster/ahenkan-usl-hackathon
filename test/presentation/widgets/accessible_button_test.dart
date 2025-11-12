import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/presentation/widgets/accessible_button.dart';
import 'package:ahenkan/core/utils/app_configuration.dart';

void main() {
  group('AccessibleButton Widget Tests', () {
    testWidgets('meets minimum touch target size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(onPressed: () {}, child: const Text('Test')),
          ),
        ),
      );

      final button = tester.widget<Container>(
        find.descendant(
          of: find.byType(AccessibleButton),
          matching: find.byType(Container).first,
        ),
      );

      expect(button.constraints?.minWidth, AppConfiguration.minTouchTargetSize);
      expect(
        button.constraints?.minHeight,
        AppConfiguration.minTouchTargetSize,
      );
    });

    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(onPressed: () {}, child: const Text('Test')),
          ),
        ),
      );

      expect(find.byType(AccessibleButton), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('has proper constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              width: 100,
              height: 50,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AccessibleButton),
          matching: find.byType(Container).first,
        ),
      );

      expect(
        container.constraints?.minWidth,
        greaterThanOrEqualTo(AppConfiguration.minTouchTargetSize),
      );
      expect(
        container.constraints?.minHeight,
        greaterThanOrEqualTo(AppConfiguration.minTouchTargetSize),
      );
    });
  });
}
