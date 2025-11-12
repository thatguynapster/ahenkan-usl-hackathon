import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/main.dart';
import 'package:ahenkan/core/di/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end integration tests for the sign language communication app
/// Tests complete user flows including sign-to-text, text-to-sign, language switching, and history management
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize SharedPreferences with mock values for testing
    SharedPreferences.setMockInitialValues({});
    await di.initializeDependencies();
  });

  tearDownAll(() async {
    await di.resetDependencies();
  });

  group('End-to-End Integration Tests', () {
    testWidgets(
      'Complete sign-to-text flow with history - Requirements 2.1, 2.2, 3.1, 7.1',
      (WidgetTester tester) async {
        // Build the app
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // Verify we're on the Sign-to-Text screen (first tab)
        expect(find.text('Sign to Text'), findsAtLeastNWidgets(1));

        // Verify initial state shows placeholder text
        expect(find.text('Tap the button to start recording'), findsOneWidget);

        // Find and tap the recording button using semantics
        final recordButton = find.bySemanticsLabel(
          'Start recording sign language',
        );
        expect(recordButton, findsOneWidget);
        await tester.tap(recordButton);
        await tester.pumpAndSettle();

        // Verify recording state
        expect(find.text('Recording'), findsOneWidget);

        // Wait a moment to simulate recording
        await tester.pump(const Duration(seconds: 1));

        // Stop recording
        final stopButton = find.bySemanticsLabel(
          'Stop recording sign language',
        );
        expect(stopButton, findsOneWidget);
        await tester.tap(stopButton);
        await tester.pumpAndSettle(const Duration(seconds: 6));

        // Verify interpretation result is displayed
        expect(find.text('Interpreted Text'), findsOneWidget);
        expect(find.textContaining('Confidence:'), findsOneWidget);

        // Navigate to History screen using bottom navigation bar
        final historyNavItem = find.text('History');
        await tester.tap(historyNavItem);
        await tester.pumpAndSettle();

        // Verify history screen shows messages
        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'Complete text-to-sign flow with history - Requirements 4.1, 5.1, 7.1',
      (WidgetTester tester) async {
        // Build the app
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // Navigate to Text-to-Sign screen
        final textToSignNavItem = find.text('Text to Sign');
        await tester.tap(textToSignNavItem);
        await tester.pumpAndSettle();

        // Verify we're on the Text-to-Sign screen
        expect(find.text('Text to Sign'), findsAtLeastNWidgets(1));

        // Find and enter text in the input field
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.enterText(textField, 'Hello, how are you?');
        await tester.pumpAndSettle();

        // Verify character counter updates
        expect(find.textContaining('19/500'), findsOneWidget);

        // Tap the generate button
        final generateButton = find.text('Generate Sign Language');
        expect(generateButton, findsOneWidget);
        await tester.tap(generateButton);
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // Navigate to History screen
        final historyNavItem = find.text('History');
        await tester.tap(historyNavItem);
        await tester.pumpAndSettle();

        // Verify the text-to-sign message appears in history
        expect(find.textContaining('Hello, how are you?'), findsOneWidget);
      },
    );

    testWidgets('Language switching across all features - Requirements 6.3', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify initial language (English)
      expect(find.text('English'), findsAtLeastNWidgets(1));

      // Open language selector dropdown
      final languageDropdown = find.byType(DropdownButton<dynamic>).first;
      await tester.tap(languageDropdown);
      await tester.pumpAndSettle();

      // Select Akan language from dropdown menu
      final akanOption = find.text('Akan').last;
      await tester.tap(akanOption);
      await tester.pumpAndSettle();

      // Verify language changed to Akan
      expect(find.text('Akan'), findsAtLeastNWidgets(1));

      // Navigate to Text-to-Sign screen
      final textToSignNavItem = find.text('Text to Sign');
      await tester.tap(textToSignNavItem);
      await tester.pumpAndSettle();

      // Verify language persists on Text-to-Sign screen
      expect(find.text('Akan'), findsAtLeastNWidgets(1));

      // Navigate to History screen
      final historyNavItem = find.text('History');
      await tester.tap(historyNavItem);
      await tester.pumpAndSettle();

      // Navigate back to Sign-to-Text screen
      final signToTextNavItem = find.text('Sign to Text');
      await tester.tap(signToTextNavItem);
      await tester.pumpAndSettle();

      // Verify language still persists
      expect(find.text('Akan'), findsAtLeastNWidgets(1));
    });

    testWidgets('Session history management - Requirements 7.1, 7.2, 7.4', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Perform sign-to-text operation
      final recordButton = find.bySemanticsLabel(
        'Start recording sign language',
      );
      await tester.tap(recordButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      final stopButton = find.bySemanticsLabel('Stop recording sign language');
      await tester.tap(stopButton);
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Navigate to Text-to-Sign screen
      final textToSignNavItem = find.text('Text to Sign');
      await tester.tap(textToSignNavItem);
      await tester.pumpAndSettle();

      // Perform text-to-sign operation
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message for history');
      await tester.pumpAndSettle();

      final generateButton = find.text('Generate Sign Language');
      await tester.tap(generateButton);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Navigate to History screen
      final historyNavItem = find.text('History');
      await tester.tap(historyNavItem);
      await tester.pumpAndSettle();

      // Verify both messages appear in history
      expect(find.text('History'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Test message for history'), findsOneWidget);

      // Verify messages are displayed in a ListView
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets(
      'Navigation transitions complete within 1 second - Requirement 6.2',
      (WidgetTester tester) async {
        // Build the app
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // Measure navigation time to Text-to-Sign
        final startTime1 = DateTime.now();
        final textToSignNavItem = find.text('Text to Sign');
        await tester.tap(textToSignNavItem);
        await tester.pumpAndSettle();
        final endTime1 = DateTime.now();
        final duration1 = endTime1.difference(startTime1);

        expect(duration1.inMilliseconds, lessThan(1000));

        // Measure navigation time to History
        final startTime2 = DateTime.now();
        final historyNavItem = find.text('History');
        await tester.tap(historyNavItem);
        await tester.pumpAndSettle();
        final endTime2 = DateTime.now();
        final duration2 = endTime2.difference(startTime2);

        expect(duration2.inMilliseconds, lessThan(1000));

        // Measure navigation time back to Sign-to-Text
        final startTime3 = DateTime.now();
        final signToTextNavItem = find.text('Sign to Text');
        await tester.tap(signToTextNavItem);
        await tester.pumpAndSettle();
        final endTime3 = DateTime.now();
        final duration3 = endTime3.difference(startTime3);

        expect(duration3.inMilliseconds, lessThan(1000));
      },
    );

    testWidgets('App stability across screen navigation - Requirement 3.4', (
      WidgetTester tester,
    ) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate through all screens to ensure no crashes
      final textToSignNavItem = find.text('Text to Sign');
      await tester.tap(textToSignNavItem);
      await tester.pumpAndSettle();

      final historyNavItem = find.text('History');
      await tester.tap(historyNavItem);
      await tester.pumpAndSettle();

      final signToTextNavItem = find.text('Sign to Text');
      await tester.tap(signToTextNavItem);
      await tester.pumpAndSettle();

      // Verify app remains stable
      expect(find.text('Sign to Text'), findsAtLeastNWidgets(1));
    });
  });
}
