import '../utils/enums.dart';

/// Class representing application errors with user-friendly messages
class AppError {
  /// Type of error that occurred
  final ErrorType type;

  /// Technical error message for debugging
  final String message;

  /// User-friendly error message to display
  final String userFriendlyMessage;

  /// Whether the error can be recovered from (e.g., retry is possible)
  final bool isRecoverable;

  const AppError({
    required this.type,
    required this.message,
    required this.userFriendlyMessage,
    required this.isRecoverable,
  });

  /// Creates a copy of this error with the given fields replaced
  AppError copyWith({
    ErrorType? type,
    String? message,
    String? userFriendlyMessage,
    bool? isRecoverable,
  }) {
    return AppError(
      type: type ?? this.type,
      message: message ?? this.message,
      userFriendlyMessage: userFriendlyMessage ?? this.userFriendlyMessage,
      isRecoverable: isRecoverable ?? this.isRecoverable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppError &&
        other.type == type &&
        other.message == message &&
        other.userFriendlyMessage == userFriendlyMessage &&
        other.isRecoverable == isRecoverable;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        message.hashCode ^
        userFriendlyMessage.hashCode ^
        isRecoverable.hashCode;
  }

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, userFriendlyMessage: $userFriendlyMessage, isRecoverable: $isRecoverable)';
  }
}
