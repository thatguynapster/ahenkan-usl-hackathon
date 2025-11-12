// This file contains examples of how to use the error handling and UI feedback utilities
// throughout the application. These examples demonstrate best practices for providing
// user feedback that meets the requirements (8.2, 8.4, 3.4).

import 'package:flutter/material.dart';
import '../error/app_error.dart';
import 'enums.dart';
import 'error_handler.dart';
import 'ui_feedback.dart';
import '../../presentation/widgets/error_display.dart';
import '../../presentation/widgets/loading_indicator.dart';

/// Example 1: Showing an error with retry option
/// Use this when an operation fails but can be retried
void showErrorWithRetryExample(BuildContext context, VoidCallback onRetry) {
  UIFeedback.showError(
    context,
    message: 'Failed to process video. Please try again.',
    onRetry: onRetry,
  );
}

/// Example 2: Showing an AppError
/// Use this when you have an AppError object from a service
void showAppErrorExample(
  BuildContext context,
  AppError error,
  VoidCallback onRetry,
) {
  UIFeedback.showAppError(context, error: error, onRetry: onRetry);
}

/// Example 3: Showing a success message
/// Use this to confirm successful operations
void showSuccessExample(BuildContext context) {
  UIFeedback.showSuccess(
    context,
    message: 'Sign language interpreted successfully!',
  );
}

/// Example 4: Showing an info message
/// Use this for informational feedback
void showInfoExample(BuildContext context) {
  UIFeedback.showInfo(context, message: 'Recording will start in 3 seconds...');
}

/// Example 5: Showing a loading dialog
/// Use this for operations that take more than 100ms
void showLoadingExample(BuildContext context) {
  UIFeedback.showLoadingDialog(context, message: 'Processing video...');

  // When done, dismiss it:
  // UIFeedback.dismissLoadingDialog(context);
}

/// Example 6: Requesting camera permission
/// Use this before accessing the camera
Future<void> requestCameraPermissionExample(BuildContext context) async {
  final granted = await UIFeedback.showCameraPermissionDialog(context);
  if (granted) {
    // Proceed with camera access
  } else {
    // Handle permission denial
    UIFeedback.showError(
      context,
      message: 'Camera permission is required to record sign language.',
    );
  }
}

/// Example 7: Requesting microphone permission
/// Use this before accessing the microphone
Future<void> requestMicrophonePermissionExample(BuildContext context) async {
  final granted = await UIFeedback.showMicrophonePermissionDialog(context);
  if (granted) {
    // Proceed with microphone access
  } else {
    // Handle permission denial
    UIFeedback.showError(
      context,
      message: 'Microphone permission is required for voice input.',
    );
  }
}

/// Example 8: Using ErrorDisplay widget
/// Use this to show errors in a dedicated area of the screen
Widget errorDisplayExample(String errorMessage, VoidCallback onRetry) {
  return ErrorDisplay(
    message: errorMessage,
    onRetry: onRetry,
    icon: Icons.videocam_off,
  );
}

/// Example 9: Using ErrorDisplay with AppError
/// Use this when you have an AppError object
Widget errorDisplayFromAppErrorExample(AppError error, VoidCallback onRetry) {
  return ErrorDisplay.fromAppError(error: error, onRetry: onRetry);
}

/// Example 10: Using LoadingIndicator widget
/// Use this to show loading state in a specific area
Widget loadingIndicatorExample() {
  return const LoadingIndicator(
    message: 'Interpreting sign language...',
    size: 48.0,
  );
}

/// Example 11: Using LoadingOverlay
/// Use this to show a loading overlay over existing content
Widget loadingOverlayExample(bool isLoading, Widget content) {
  return LoadingOverlay(
    isLoading: isLoading,
    message: 'Processing...',
    child: content,
  );
}

/// Example 12: Creating an AppError
/// Use this when you need to create an error in your service layer
AppError createErrorExample() {
  return ErrorHandler.createError(
    ErrorType.camera,
    technicalMessage: 'Camera initialization failed: device not found',
    userMessage:
        'Unable to access the camera. Please check your camera permissions.',
    isRecoverable: true,
  );
}

/// Example 13: Getting user-friendly error messages
/// Use this to convert error types to user-friendly messages
String getUserFriendlyMessageExample(ErrorType errorType) {
  return ErrorHandler.getUserFriendlyMessage(
    errorType,
    details: 'Custom error details here',
  );
}

/// Example 14: Checking if an error is recoverable
/// Use this to determine if a retry option should be shown
bool isRecoverableExample(ErrorType errorType) {
  return ErrorHandler.isRecoverable(errorType);
}

/// Example 15: Complete error handling flow in a BLoC
/// This shows how to handle errors in a BLoC and emit appropriate states
class ErrorHandlingFlowExample {
  Future<void> handleOperation(BuildContext context) async {
    try {
      // Show loading feedback immediately (within 100ms requirement)
      UIFeedback.showLoadingDialog(context, message: 'Processing...');

      // Perform operation
      await Future.delayed(const Duration(seconds: 2));

      // Dismiss loading
      UIFeedback.dismissLoadingDialog(context);

      // Show success
      UIFeedback.showSuccess(context, message: 'Operation completed!');
    } catch (e) {
      // Dismiss loading
      UIFeedback.dismissLoadingDialog(context);

      // Create and show error
      final error = ErrorHandler.createError(
        ErrorType.network,
        technicalMessage: e.toString(),
        isRecoverable: true,
      );

      UIFeedback.showAppError(
        context,
        error: error,
        onRetry: () => handleOperation(context),
      );
    }
  }
}

/// Example 16: Using ErrorBanner for inline errors
/// Use this to show errors inline without blocking the UI
Widget errorBannerExample(String errorMessage, VoidCallback onDismiss) {
  return ErrorBanner(message: errorMessage, onDismiss: onDismiss);
}

/// Example 17: Showing confirmation dialog
/// Use this when you need user confirmation
Future<void> showConfirmationExample(BuildContext context) async {
  final confirmed = await UIFeedback.showConfirmationDialog(
    context,
    title: 'Clear History',
    message: 'Are you sure you want to clear the session history?',
    confirmText: 'Clear',
    cancelText: 'Cancel',
  );

  if (confirmed) {
    // Proceed with action
    UIFeedback.showSuccess(context, message: 'History cleared');
  }
}
