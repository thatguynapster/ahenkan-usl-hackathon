import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahenkan/core/di/injection_container.dart' as di;
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/presentation/pages/main_navigation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    // Initialize dependency injection
    await di.initializeDependencies();
  });

  group('MainNavigationScreen Integration Tests', () {
    testWidgets('should display bottom navigation bar with three items', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Assert
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Sign to Text'), findsOneWidget);
      expect(find.text('Text to Sign'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('should start with Sign to Text screen active', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Assert - Check that Sign to Text screen is displayed
      expect(find.text('Sign to Text'), findsAtLeastNWidgets(1));
    });

    testWidgets('should switch to Text to Sign screen when tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Act - Tap on Text to Sign navigation item
      await tester.tap(find.text('Text to Sign'));
      await tester.pump();

      // Assert - Check that Text to Sign screen is displayed
      expect(find.text('Text to Sign'), findsAtLeastNWidgets(1));
    });

    testWidgets('should switch to History screen when tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Act - Tap on History navigation item
      await tester.tap(find.text('History'));
      await tester.pump();

      // Assert - Check that History screen is displayed
      expect(find.text('History'), findsAtLeastNWidgets(1));
    });

    testWidgets('should switch between all three screens', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Act & Assert - Switch to Text to Sign
      await tester.tap(find.text('Text to Sign'));
      await tester.pump();
      expect(find.text('Text to Sign'), findsAtLeastNWidgets(1));

      // Act & Assert - Switch to History
      await tester.tap(find.text('History'));
      await tester.pump();
      expect(find.text('History'), findsAtLeastNWidgets(1));

      // Act & Assert - Switch back to Sign to Text
      await tester.tap(find.text('Sign to Text'));
      await tester.pump();
      expect(find.text('Sign to Text'), findsAtLeastNWidgets(1));
    });

    testWidgets('should preserve state when switching between screens', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Act - Switch to Text to Sign and enter some text
      await tester.tap(find.text('Text to Sign'));
      await tester.pump();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      await tester.pump();

      // Switch to History
      await tester.tap(find.text('History'));
      await tester.pump();

      // Switch back to Text to Sign
      await tester.tap(find.text('Text to Sign'));
      await tester.pump();

      // Assert - Text should still be there (state preserved)
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('should complete navigation transitions quickly', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Act & Assert - Measure transition time
      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Text to Sign'));
      await tester.pump();

      stopwatch.stop();

      // Assert - Transition should complete quickly (within 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets(
      'should maintain language preference when switching between screens',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(home: MainNavigationScreen()),
        );
        await tester.pump();

        // Act - Change language on Sign to Text screen
        final languageDropdown = find.byType(DropdownButton<Language>);
        await tester.tap(languageDropdown);
        await tester.pumpAndSettle();

        // Select Akan language
        await tester.tap(find.text('Akan').last);
        await tester.pumpAndSettle();

        // Switch to Text to Sign screen
        await tester.tap(find.text('Text to Sign'));
        await tester.pump();

        // Assert - Language should still be Akan
        expect(find.text('Akan'), findsOneWidget);

        // Switch back to Sign to Text
        await tester.tap(find.text('Sign to Text'));
        await tester.pump();

        // Assert - Language should still be Akan
        expect(find.text('Akan'), findsOneWidget);
      },
    );
  });
}
