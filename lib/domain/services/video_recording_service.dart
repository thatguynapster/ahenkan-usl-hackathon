import 'dart:io';
import '../../core/error/app_error.dart';

/// Service interface for video recording functionality
/// Handles camera initialization, recording, and resource management
abstract class VideoRecordingService {
  /// Initializes the camera controller with appropriate resolution
  /// Returns an [AppError] if initialization fails
  Future<AppError?> initialize();

  /// Starts recording video from the camera
  /// Returns an [AppError] if recording fails to start
  Future<AppError?> startRecording();

  /// Stops recording and returns the recorded video file
  /// Returns a tuple of (File?, AppError?) where File is the recorded video
  /// or AppError if the operation fails
  Future<(File?, AppError?)> stopRecording();

  /// Disposes of camera resources and cleans up
  void dispose();

  /// Returns true if the camera is currently initialized
  bool get isInitialized;

  /// Returns true if the camera is currently recording
  bool get isRecording;
}
