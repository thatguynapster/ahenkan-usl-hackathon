import 'package:flutter/material.dart';
import '../../core/error/app_error.dart';
import '../../core/utils/app_configuration.dart';

/// A reusable widget for displaying error messages with retry options
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Creates an ErrorDisplay from an AppError object
  factory ErrorDisplay.fromAppError({
    required AppError error,
    VoidCallback? onRetry,
  }) {
    return ErrorDisplay(
      message: error.userFriendlyMessage,
      onRetry: error.isRecoverable ? onRetry : null,
      icon: _getIconForErrorType(error.type),
    );
  }

  static IconData _getIconForErrorType(dynamic type) {
    // This would map error types to appropriate icons
    return Icons.error_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64.0, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 24.0),
            Text(
              message,
              style: TextStyle(
                fontSize: 16.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  minimumSize: const Size(
                    AppConfiguration.minTouchTargetSize,
                    AppConfiguration.minTouchTargetSize,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact error banner for inline error display
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14.0,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8.0),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 20.0,
              color: Theme.of(context).colorScheme.onErrorContainer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
