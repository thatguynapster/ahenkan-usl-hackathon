import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/error/app_error.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/data/services/video_recording_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoRecordingServiceImpl service;

  setUp(() {
    service = VideoRecordingServiceImpl();
  });

  tearDown(() {
    service.dispose();
  });

  group('Camera Initialization Tests', () {
    test('should have isInitialized false before initialization', () {
      // Assert
      expect(service.isInitialized, isFalse);
    });

    test('should have isRecording false before initialization', () {
      // Assert
      expect(service.isRecording, isFalse);
    });

    test('should attempt to initialize camera', () async {
      // Act
      final error = await service.initialize();

      // Assert - in test environment, camera initialization will fail
      // We verify the error is properly structured
      if (error != null) {
        expect(error.type, equals(ErrorType.camera));
        expect(error.message, isNotEmpty);
        expect(error.userFriendlyMessage, isNotEmpty);
        expect(error.userFriendlyMessage, isNot(equals(error.message)));
      } else {
        // If somehow succeeds (unlikely in test environment)
        expect(service.isInitialized, isTrue);
      }
    });

    test('should have controller null before initialization', () {
      // Assert
      expect(service.controller, isNull);
    });

    test('should handle initialization errors gracefully', () async {
      // Act
      final error = await service.initialize();

      // Assert - should return error or succeed
      if (error != null) {
        expect(error.type, equals(ErrorType.camera));
        expect(error.isRecoverable, isNotNull);
        expect(error.userFriendlyMessage, contains('camera'));
      }
    });
  });

  group('Recording Start Tests', () {
    test(
      'should return error when starting recording without initialization',
      () async {
        // Act
        final error = await service.startRecording();

        // Assert
        expect(error, isNotNull);
        expect(error!.type, equals(ErrorType.camera));
        expect(error.message, contains('not initialized'));
        expect(error.userFriendlyMessage, contains('not ready'));
        expect(error.isRecoverable, isTrue);
      },
    );

    test('should not set isRecording to true without initialization', () async {
      // Act
      await service.startRecording();

      // Assert
      expect(service.isRecording, isFalse);
    });

    test('should handle recording start with proper error structure', () async {
      // Arrange - try to initialize first
      await service.initialize();

      // Act
      final error = await service.startRecording();

      // Assert - should return error or succeed
      if (error != null) {
        expect(error.type, equals(ErrorType.camera));
        expect(error.message, isNotEmpty);
        expect(error.userFriendlyMessage, isNotEmpty);
      } else {
        expect(service.isRecording, isTrue);
      }
    });
  });

  group('Recording Stop Tests', () {
    test(
      'should return error when stopping recording without initialization',
      () async {
        // Act
        final (file, error) = await service.stopRecording();

        // Assert
        expect(file, isNull);
        expect(error, isNotNull);
        expect(error!.type, equals(ErrorType.camera));
        expect(error.message, contains('not initialized'));
        expect(error.userFriendlyMessage, contains('not ready'));
        expect(error.isRecoverable, isTrue);
      },
    );

    test(
      'should return error when stopping without active recording',
      () async {
        // Arrange - initialize but don't start recording
        final initError = await service.initialize();

        // Act
        final (file, error) = await service.stopRecording();

        // Assert
        expect(file, isNull);
        expect(error, isNotNull);
        expect(error!.type, equals(ErrorType.camera));

        // If initialization failed, we get "not initialized" error
        // If initialization succeeded, we get "No recording in progress" error
        if (initError != null) {
          expect(error.message, contains('not initialized'));
        } else {
          expect(error.message, contains('No recording in progress'));
          expect(error.isRecoverable, isFalse);
        }

        expect(error.userFriendlyMessage, isNotEmpty);
      },
    );

    test('should handle stop recording with proper error structure', () async {
      // Arrange - try to initialize and start recording
      await service.initialize();
      await service.startRecording();

      // Act
      final (file, error) = await service.stopRecording();

      // Assert - should return file or error
      if (error != null) {
        expect(error.type, equals(ErrorType.camera));
        expect(error.message, isNotEmpty);
        expect(error.userFriendlyMessage, isNotEmpty);
      } else {
        expect(file, isNotNull);
        expect(file, isA<File>());
      }
    });

    test('should set isRecording to false after stop attempt', () async {
      // Arrange
      await service.initialize();
      await service.startRecording();

      // Act
      await service.stopRecording();

      // Assert
      expect(service.isRecording, isFalse);
    });
  });

  group('Resource Disposal Tests', () {
    test('should reset isInitialized after dispose', () async {
      // Arrange
      await service.initialize();

      // Act
      service.dispose();

      // Assert
      expect(service.isInitialized, isFalse);
    });

    test('should reset isRecording after dispose', () async {
      // Arrange
      await service.initialize();
      await service.startRecording();

      // Act
      service.dispose();

      // Assert
      expect(service.isRecording, isFalse);
    });

    test('should set controller to null after dispose', () async {
      // Arrange
      await service.initialize();

      // Act
      service.dispose();

      // Assert
      expect(service.controller, isNull);
    });

    test('should handle dispose without initialization', () {
      // Act & Assert - should not throw
      expect(() => service.dispose(), returnsNormally);
    });

    test('should handle multiple dispose calls', () async {
      // Arrange
      await service.initialize();

      // Act & Assert - should not throw
      expect(() {
        service.dispose();
        service.dispose();
      }, returnsNormally);
    });
  });

  group('Error Handling Tests', () {
    test(
      'should return AppError with correct structure for camera errors',
      () async {
        // Act - try to start recording without initialization
        final error = await service.startRecording();

        // Assert
        expect(error, isNotNull);
        expect(error!.type, equals(ErrorType.camera));
        expect(error.message, isNotEmpty);
        expect(error.userFriendlyMessage, isNotEmpty);
        expect(error.userFriendlyMessage, isNot(equals(error.message)));
        expect(error.isRecoverable, isNotNull);
      },
    );

    test('should provide user-friendly messages for all errors', () async {
      // Test various error scenarios
      final errors = <AppError?>[];

      // Error 1: Start without init
      errors.add(await service.startRecording());

      // Error 2: Stop without init
      final (_, error2) = await service.stopRecording();
      errors.add(error2);

      // Assert all errors have user-friendly messages
      for (final error in errors) {
        if (error != null) {
          expect(error.userFriendlyMessage, isNotEmpty);
          expect(error.userFriendlyMessage.length, greaterThan(10));
          expect(error.userFriendlyMessage, isNot(contains('Exception')));
          expect(error.userFriendlyMessage, isNot(contains('null')));
        }
      }
    });

    test(
      'should handle sequential operations with proper state management',
      () async {
        // Arrange
        await service.initialize();

        // Act & Assert - multiple start attempts
        final error1 = await service.startRecording();
        if (error1 == null) {
          // If first start succeeded, second should fail
          final error2 = await service.startRecording();
          expect(error2, isNotNull);
          expect(error2!.message, contains('already in progress'));
        }
      },
    );
  });

  group('State Management Tests', () {
    test('should maintain correct state through lifecycle', () async {
      // Initial state
      expect(service.isInitialized, isFalse);
      expect(service.isRecording, isFalse);

      // After initialization attempt
      await service.initialize();
      // State depends on whether init succeeded

      // After dispose
      service.dispose();
      expect(service.isInitialized, isFalse);
      expect(service.isRecording, isFalse);
    });

    test('should not allow recording operations after dispose', () async {
      // Arrange
      await service.initialize();
      service.dispose();

      // Act
      final error = await service.startRecording();

      // Assert
      expect(error, isNotNull);
      expect(error!.type, equals(ErrorType.camera));
    });

    test('should handle rapid state changes gracefully', () async {
      // Act - rapid operations
      await service.initialize();
      await service.startRecording();
      await service.stopRecording();
      service.dispose();

      // Assert - should complete without throwing
      expect(service.isInitialized, isFalse);
      expect(service.isRecording, isFalse);
    });
  });
}
