import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/app_error.dart';
import '../../core/utils/enums.dart';
import '../../domain/repositories/storage_repository.dart';

/// Implementation of [StorageRepository] using shared_preferences and path_provider
class StorageRepositoryImpl implements StorageRepository {
  static const String _languagePreferenceKey = 'language_preference';
  static const String _videosDirectoryName = 'sign_language_videos';

  final SharedPreferences _sharedPreferences;

  StorageRepositoryImpl(this._sharedPreferences);

  @override
  Future<AppError?> saveLanguagePreference(Language language) async {
    try {
      final success = await _sharedPreferences.setString(
        _languagePreferenceKey,
        language.name,
      );

      if (!success) {
        return AppError(
          type: ErrorType.storage,
          message: 'Failed to save language preference',
          userFriendlyMessage:
              'Could not save your language preference. Please try again.',
          isRecoverable: true,
        );
      }

      return null;
    } catch (e) {
      return AppError(
        type: ErrorType.storage,
        message: 'Error saving language preference: $e',
        userFriendlyMessage:
            'Could not save your language preference. Please try again.',
        isRecoverable: true,
      );
    }
  }

  @override
  Future<(Language?, AppError?)> getLanguagePreference() async {
    try {
      final languageName = _sharedPreferences.getString(_languagePreferenceKey);

      if (languageName == null) {
        return (null, null);
      }

      // Convert string back to Language enum
      final language = Language.values.firstWhere(
        (l) => l.name == languageName,
        orElse: () => Language.english, // Default to English if invalid
      );

      return (language, null);
    } catch (e) {
      return (
        null,
        AppError(
          type: ErrorType.storage,
          message: 'Error retrieving language preference: $e',
          userFriendlyMessage: 'Could not load your language preference.',
          isRecoverable: true,
        ),
      );
    }
  }

  @override
  Future<(String?, AppError?)> saveVideoFile(
    File video,
    String filename,
  ) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/$_videosDirectoryName');

      // Create videos directory if it doesn't exist
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      // Copy the video file to the videos directory
      final targetPath = '${videosDir.path}/$filename';
      await video.copy(targetPath);

      return (targetPath, null);
    } catch (e) {
      return (
        null,
        AppError(
          type: ErrorType.storage,
          message: 'Error saving video file: $e',
          userFriendlyMessage:
              'Could not save the video. Please check your storage space.',
          isRecoverable: true,
        ),
      );
    }
  }

  @override
  Future<(File?, AppError?)> getVideoFile(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = '${directory.path}/$_videosDirectoryName/$filename';
      final videoFile = File(videoPath);

      if (!await videoFile.exists()) {
        return (
          null,
          AppError(
            type: ErrorType.storage,
            message: 'Video file not found: $filename',
            userFriendlyMessage: 'The requested video could not be found.',
            isRecoverable: false,
          ),
        );
      }

      return (videoFile, null);
    } catch (e) {
      return (
        null,
        AppError(
          type: ErrorType.storage,
          message: 'Error retrieving video file: $e',
          userFriendlyMessage: 'Could not load the video.',
          isRecoverable: true,
        ),
      );
    }
  }

  @override
  Future<AppError?> deleteVideoFile(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = '${directory.path}/$_videosDirectoryName/$filename';
      final videoFile = File(videoPath);

      if (await videoFile.exists()) {
        await videoFile.delete();
      }

      return null;
    } catch (e) {
      return AppError(
        type: ErrorType.storage,
        message: 'Error deleting video file: $e',
        userFriendlyMessage: 'Could not delete the video.',
        isRecoverable: true,
      );
    }
  }

  @override
  Future<(String?, AppError?)> getVideosDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/$_videosDirectoryName');

      // Create videos directory if it doesn't exist
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      return (videosDir.path, null);
    } catch (e) {
      return (
        null,
        AppError(
          type: ErrorType.storage,
          message: 'Error getting videos directory: $e',
          userFriendlyMessage: 'Could not access video storage.',
          isRecoverable: true,
        ),
      );
    }
  }
}
