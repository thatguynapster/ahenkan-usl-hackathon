import 'dart:io';
import '../../core/error/app_error.dart';
import '../../core/utils/enums.dart';

/// Repository interface for storage operations
/// Handles language preference persistence and video file management
abstract class StorageRepository {
  /// Saves the user's language preference
  /// Returns an [AppError] if the operation fails
  Future<AppError?> saveLanguagePreference(Language language);

  /// Retrieves the user's saved language preference
  /// Returns the saved [Language] or null if no preference is saved
  /// Returns an [AppError] if the operation fails
  Future<(Language?, AppError?)> getLanguagePreference();

  /// Saves a video file with the given filename
  /// Returns the path to the saved file or an [AppError] if the operation fails
  Future<(String?, AppError?)> saveVideoFile(File video, String filename);

  /// Retrieves a video file by filename
  /// Returns the [File] or an [AppError] if the operation fails
  Future<(File?, AppError?)> getVideoFile(String filename);

  /// Deletes a video file by filename
  /// Returns an [AppError] if the operation fails
  Future<AppError?> deleteVideoFile(String filename);

  /// Gets the directory path where videos are stored
  /// Returns the directory path or an [AppError] if the operation fails
  Future<(String?, AppError?)> getVideosDirectory();
}
