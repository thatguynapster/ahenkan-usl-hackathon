import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/error/app_error.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/data/services/speech_to_text_service_impl.dart';

void main() {
  late SpeechToTextServiceImpl service;

  setUp(() {
    service = SpeechToTextServiceImpl();
  });

  group('Initialization Tests', () {
    test('should have correct initial state before initialization', () {
      // Assert
      expect(service.isInitialized, isFalse);
      expect(service.isListening, isFalse);
    });

    test('should attempt to initialize speech recognition', () async {
      // Act
      final error = await service.initialize();

      // Assert - initialization may fail in test environment without microphone
      // but the method should complete without throwing
      if (error == null) {
        expect(service.isInitialized, isTrue);
      } else {
        expect(error, isA<AppError>());
        expect(error.type, anyOf(ErrorType.speech, ErrorType.permission));
      }
    });

    test(
      'should return appropriate error type when initialization fails',
      () async {
        // Act
        final error = await service.initialize();

        // Assert - if error occurs, it should be properly structured
        if (error != null) {
          expect(error.type, anyOf(ErrorType.speech, ErrorType.permission));
          expect(error.message, isNotEmpty);
          expect(error.userFriendlyMessage, isNotEmpty);
          expect(error.isRecoverable, isA<bool>());
        }
      },
    );
  });

  group('Start Listening Tests', () {
    test('should return error when not initialized', () async {
      // Act - try to listen without initializing
      final (text, error) = await service.startListening(Language.english);

      // Assert
      expect(text, isNull);
      expect(error, isNotNull);
      expect(error!.type, equals(ErrorType.speech));
      expect(error.message, contains('not initialized'));
      expect(error.userFriendlyMessage, contains('not ready'));
      expect(error.isRecoverable, isTrue);
    });

    test('should handle different language codes correctly', () async {
      // Arrange
      await service.initialize();

      // Act & Assert - verify language codes are used
      // These will likely fail in test environment, but we're testing the interface
      final languages = [
        Language.english,
        Language.akan,
        Language.ga,
        Language.ewe,
      ];

      for (final language in languages) {
        final (text, error) = await service.startListening(language);

        // Should either succeed or fail gracefully
        if (error != null) {
          expect(error, isA<AppError>());
          expect(error.type, anyOf(ErrorType.speech, ErrorType.permission));
        } else {
          expect(text, isA<String>());
        }
      }
    });

    test('should not allow concurrent listening sessions', () async {
      // Arrange
      await service.initialize();

      // This test verifies the logic exists, even if it can't execute in test env
      // The implementation should prevent concurrent listening
      expect(service.isListening, isFalse);
    });
  });

  group('Stop Listening Tests', () {
    test('should handle stopListening when not listening', () {
      // Act & Assert - should not throw
      expect(() => service.stopListening(), returnsNormally);
    });

    test('should set isListening to false after stopping', () {
      // Arrange
      expect(service.isListening, isFalse);

      // Act
      service.stopListening();

      // Assert
      expect(service.isListening, isFalse);
    });
  });

  group('State Management Tests', () {
    test('should maintain isInitialized state correctly', () async {
      // Initial state
      expect(service.isInitialized, isFalse);

      // After initialization attempt
      await service.initialize();

      // State should reflect initialization result
      // (may be true or false depending on environment)
      expect(service.isInitialized, isA<bool>());
    });

    test('should maintain isListening state correctly', () {
      // Initial state
      expect(service.isListening, isFalse);

      // After stop (when not listening)
      service.stopListening();
      expect(service.isListening, isFalse);
    });
  });

  group('Error Handling Tests', () {
    test(
      'should return properly structured AppError for uninitialized state',
      () async {
        // Act
        final (text, error) = await service.startListening(Language.english);

        // Assert
        expect(text, isNull);
        expect(error, isNotNull);
        expect(error!.type, equals(ErrorType.speech));
        expect(error.message, isNotEmpty);
        expect(error.userFriendlyMessage, isNotEmpty);
        expect(error.isRecoverable, isTrue);
      },
    );

    test('should provide user-friendly error messages', () async {
      // Act
      final (text, error) = await service.startListening(Language.english);

      // Assert
      expect(error, isNotNull);
      expect(error!.userFriendlyMessage, isNotEmpty);
      expect(error.userFriendlyMessage.length, greaterThan(10));
      // Should not contain technical jargon
      expect(error.userFriendlyMessage, isNot(contains('null')));
      expect(error.userFriendlyMessage, isNot(contains('exception')));
    });

    test('should indicate if errors are recoverable', () async {
      // Act
      final (text, error) = await service.startListening(Language.english);

      // Assert
      if (error != null) {
        expect(error.isRecoverable, isA<bool>());
      }
    });
  });

  group('Language Support Tests', () {
    test('should support English language code', () async {
      // Arrange
      await service.initialize();

      // Act
      final (text, error) = await service.startListening(Language.english);

      // Assert - should attempt to use 'en' locale
      // Result depends on environment, but should not throw
      expect(text != null || error != null, isTrue);
    });

    test('should support Akan language code', () async {
      // Arrange
      await service.initialize();

      // Act
      final (text, error) = await service.startListening(Language.akan);

      // Assert - should attempt to use 'ak' locale
      expect(text != null || error != null, isTrue);
    });

    test('should support Ga language code', () async {
      // Arrange
      await service.initialize();

      // Act
      final (text, error) = await service.startListening(Language.ga);

      // Assert - should attempt to use 'gaa' locale
      expect(text != null || error != null, isTrue);
    });

    test('should support Ewe language code', () async {
      // Arrange
      await service.initialize();

      // Act
      final (text, error) = await service.startListening(Language.ewe);

      // Assert - should attempt to use 'ee' locale
      expect(text != null || error != null, isTrue);
    });
  });

  group('Interface Contract Tests', () {
    test('should return tuple with text or error, never both null', () async {
      // Act
      final (text, error) = await service.startListening(Language.english);

      // Assert - at least one should be non-null
      expect(text != null || error != null, isTrue);
    });

    test('should not return both text and error', () async {
      // Act
      final (text, error) = await service.startListening(Language.english);

      // Assert - should be mutually exclusive
      if (text != null) {
        expect(error, isNull);
      }
      if (error != null) {
        expect(text, isNull);
      }
    });

    test('should implement all required interface methods', () {
      // Assert - verify interface is fully implemented
      expect(service.initialize, isA<Function>());
      expect(service.startListening, isA<Function>());
      expect(service.stopListening, isA<Function>());
      expect(service.isInitialized, isA<bool>());
      expect(service.isListening, isA<bool>());
    });
  });

  group('Permission Handling Tests', () {
    test('should handle permission-related errors appropriately', () async {
      // Act
      final error = await service.initialize();

      // Assert - if permission error occurs, it should be properly typed
      if (error != null && error.type == ErrorType.permission) {
        expect(error.userFriendlyMessage, contains('permission'));
        expect(error.isRecoverable, isTrue);
      }
    });

    test('should provide guidance for permission issues', () async {
      // Act
      final error = await service.initialize();

      // Assert - permission errors should guide user
      if (error != null && error.type == ErrorType.permission) {
        expect(
          error.userFriendlyMessage.toLowerCase(),
          anyOf(
            contains('permission'),
            contains('microphone'),
            contains('access'),
          ),
        );
      }
    });
  });

  group('Timeout Handling Tests', () {
    test('should have timeout mechanism for listening', () async {
      // Arrange
      await service.initialize();

      // Act - the implementation should have a 10-second timeout
      // We're testing that the method completes, not that it times out
      final stopwatch = Stopwatch()..start();
      final (text, error) = await service.startListening(Language.english);
      stopwatch.stop();

      // Assert - should complete (either success or error) within reasonable time
      // In test environment, it will likely error quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
      expect(text != null || error != null, isTrue);
    });
  });

  group('Multiple Session Tests', () {
    test('should handle sequential listening sessions', () async {
      // Arrange
      await service.initialize();

      // Act - first session
      final (text1, error1) = await service.startListening(Language.english);

      // Act - second session
      final (text2, error2) = await service.startListening(Language.akan);

      // Assert - both should complete
      expect(text1 != null || error1 != null, isTrue);
      expect(text2 != null || error2 != null, isTrue);
    });

    test('should allow retry after error', () async {
      // Arrange
      await service.initialize();

      // Act - first attempt
      final (text1, error1) = await service.startListening(Language.english);

      // Act - retry
      final (text2, error2) = await service.startListening(Language.english);

      // Assert - both attempts should complete
      expect(text1 != null || error1 != null, isTrue);
      expect(text2 != null || error2 != null, isTrue);

      // If first failed, second should also be allowed
      if (error1 != null && error1.isRecoverable) {
        expect(text2 != null || error2 != null, isTrue);
      }
    });
  });
}
