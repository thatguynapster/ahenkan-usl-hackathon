import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/di/injection_container.dart';

void main() {
  group('Dependency Injection', () {
    setUp(() async {
      // Reset dependencies before each test
      await resetDependencies();
    });

    tearDown(() async {
      // Clean up after each test
      await resetDependencies();
    });

    test('initializeDependencies should complete without errors', () async {
      // Act & Assert - should not throw any exceptions
      await expectLater(initializeDependencies(), completes);
    });

    test('resetDependencies should complete without errors', () async {
      // Arrange
      await initializeDependencies();

      // Act & Assert - should not throw any exceptions
      await expectLater(resetDependencies(), completes);
    });

    test('service locator instance should be accessible', () {
      // Assert
      expect(sl, isNotNull);
    });
  });
}
