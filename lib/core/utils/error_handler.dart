import '../error/app_error.dart';
import 'enums.dart';

/// Utility class for handling and displaying errors throughout the application
class ErrorHandler {
  /// Converts an ErrorType to a user-friendly error message
  static String getUserFriendlyMessage(ErrorType type, {String? details}) {
    switch (type) {
      case ErrorType.camera:
        return details ??
            'Unable to access the camera. Please check your camera permissions and try again.';
      case ErrorType.interpretation:
        return details ??
            'Could not interpret the sign language. Please try recording again with better lighting.';
      case ErrorType.generation:
        return details ??
            'Failed to generate sign language video. Please try again.';
      case ErrorType.speech:
        return details ??
            'Could not recognize speech. Please speak clearly and try again.';
      case ErrorType.storage:
        return details ??
            'Storage error occurred. Please check available space and try again.';
      case ErrorType.network:
        return details ??
            'Network connection error. Please check your internet connection.';
      case ErrorType.permission:
        return details ??
            'Permission required. Please grant the necessary permissions to continue.';
    }
  }

  /// Creates an AppError from an ErrorType with appropriate messages
  static AppError createError(
    ErrorType type, {
    String? technicalMessage,
    String? userMessage,
    bool isRecoverable = true,
  }) {
    return AppError(
      type: type,
      message: technicalMessage ?? 'Error of type: $type',
      userFriendlyMessage: userMessage ?? getUserFriendlyMessage(type),
      isRecoverable: isRecoverable,
    );
  }

  /// Determines if an error is recoverable based on its type
  static bool isRecoverable(ErrorType type) {
    switch (type) {
      case ErrorType.camera:
      case ErrorType.interpretation:
      case ErrorType.generation:
      case ErrorType.speech:
      case ErrorType.network:
        return true;
      case ErrorType.storage:
      case ErrorType.permission:
        return false; // Requires user action outside the app
    }
  }
}
