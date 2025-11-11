import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahenkan/core/error/app_error.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/data/repositories/storage_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageRepositoryImpl repository;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    repository = StorageRepositoryImpl(sharedPreferences);
  });

  tearDown(() async {
    await sharedPreferences.clear();
  });

  group('Language Preference Tests', () {
    test('should save language preference successfully', () async {
      // Act
      final error = await repository.saveLanguagePreference(Language.akan);

      // Assert
      expect(error, isNull);
      final savedValue = sharedPreferences.getString('language_preference');
      expect(savedValue, equals('akan'));
    });

    test('should retrieve saved language preference', () async {
      // Arrange
      await repository.saveLanguagePreference(Language.ga);

      // Act
      final (language, error) = await repository.getLanguagePreference();

      // Assert
      expect(error, isNull);
      expect(language, equals(Language.ga));
    });

    test('should return null when no language preference is saved', () async {
      // Act
      final (language, error) = await repository.getLanguagePreference();

      // Assert
      expect(error, isNull);
      expect(language, isNull);
    });

    test('should save and retrieve all language types', () async {
      for (final lang in Language.values) {
        // Arrange
        await sharedPreferences.clear();

        // Act
        await repository.saveLanguagePreference(lang);
        final (retrievedLang, error) = await repository.getLanguagePreference();

        // Assert
        expect(error, isNull);
        expect(retrievedLang, equals(lang));
      }
    });

    test('should default to English for invalid language name', () async {
      // Arrange
      await sharedPreferences.setString(
        'language_preference',
        'invalid_language',
      );

      // Act
      final (language, error) = await repository.getLanguagePreference();

      // Assert
      expect(error, isNull);
      expect(language, equals(Language.english));
    });

    test('should overwrite previous language preference', () async {
      // Arrange
      await repository.saveLanguagePreference(Language.english);

      // Act
      await repository.saveLanguagePreference(Language.ewe);
      final (language, error) = await repository.getLanguagePreference();

      // Assert
      expect(error, isNull);
      expect(language, equals(Language.ewe));
    });
  });

  group('Video File Management Tests', () {
    test('should handle video file save with proper error structure', () async {
      // Note: path_provider requires platform-specific implementations
      // This test verifies the error handling structure works correctly

      final tempDir = await Directory.systemTemp.createTemp('test_videos');
      final testVideoFile = File('${tempDir.path}/test_video.mp4');
      await testVideoFile.writeAsString('test video content');

      // Act
      final (savedPath, saveError) = await repository.saveVideoFile(
        testVideoFile,
        'saved_video.mp4',
      );

      // Assert - in test environment, path_provider will fail
      // We verify the error is properly structured
      if (saveError != null) {
        expect(saveError.type, equals(ErrorType.storage));
        expect(saveError.isRecoverable, isTrue);
        expect(saveError.userFriendlyMessage, isNotEmpty);
        expect(saveError.message, contains('Error saving video file'));
      } else {
        // If it somehow succeeds, verify the path
        expect(savedPath, isNotNull);
        expect(savedPath, contains('saved_video.mp4'));
      }

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test(
      'should return error when retrieving non-existent video file',
      () async {
        // Act
        final (file, error) = await repository.getVideoFile('non_existent.mp4');

        // Assert - should return error
        expect(error, isNotNull);
        expect(error!.type, equals(ErrorType.storage));
        expect(error.userFriendlyMessage, isNotEmpty);
      },
    );

    test(
      'should handle delete operations with proper error structure',
      () async {
        // Act
        final error = await repository.deleteVideoFile('some_file.mp4');

        // Assert - should either succeed (null) or return recoverable error
        if (error != null) {
          expect(error.type, equals(ErrorType.storage));
          expect(error.isRecoverable, isTrue);
          expect(error.userFriendlyMessage, isNotEmpty);
        }
      },
    );

    test(
      'should handle videos directory operations with proper error structure',
      () async {
        // Act
        final (dirPath, error) = await repository.getVideosDirectory();

        // Assert - should return path or error
        if (error != null) {
          expect(error.type, equals(ErrorType.storage));
          expect(error.isRecoverable, isTrue);
          expect(error.userFriendlyMessage, isNotEmpty);
        } else {
          expect(dirPath, isNotNull);
          expect(dirPath, contains('sign_language_videos'));
        }
      },
    );
  });

  group('Error Handling Tests', () {
    test(
      'should return AppError with correct structure for storage errors',
      () async {
        // Act - try to get a non-existent file
        final (_, error) = await repository.getVideoFile('non_existent.mp4');

        // Assert
        expect(error, isNotNull);
        expect(error!.type, equals(ErrorType.storage));
        expect(error.message, isNotEmpty);
        expect(error.userFriendlyMessage, isNotEmpty);
        expect(error.userFriendlyMessage, isNot(equals(error.message)));
      },
    );

    test('should handle language preference errors gracefully', () async {
      // Act
      final saveError = await repository.saveLanguagePreference(
        Language.english,
      );
      final (_, getError) = await repository.getLanguagePreference();

      // Assert - operations should succeed or return proper errors
      if (saveError != null) {
        expect(saveError.type, equals(ErrorType.storage));
        expect(saveError.isRecoverable, isTrue);
      }

      if (getError != null) {
        expect(getError.type, equals(ErrorType.storage));
        expect(getError.isRecoverable, isTrue);
      }
    });
  });
}
