import '../../core/utils/enums.dart';

/// Entity representing a communication message in the session
class Message {
  /// Unique identifier for the message
  final String id;

  /// Type of message (sign-to-text or text-to-sign)
  final MessageType type;

  /// Text content of the message
  final String content;

  /// Timestamp when the message was created
  final DateTime timestamp;

  /// Language used for the message
  final Language language;

  /// Optional path to video file (for text-to-sign messages)
  final String? videoPath;

  const Message({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.language,
    this.videoPath,
  });

  /// Creates a copy of this message with the given fields replaced
  Message copyWith({
    String? id,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    Language? language,
    String? videoPath,
  }) {
    return Message(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      language: language ?? this.language,
      videoPath: videoPath ?? this.videoPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.type == type &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.language == language &&
        other.videoPath == videoPath;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        content.hashCode ^
        timestamp.hashCode ^
        language.hashCode ^
        videoPath.hashCode;
  }

  @override
  String toString() {
    return 'Message(id: $id, type: $type, content: $content, timestamp: $timestamp, language: $language, videoPath: $videoPath)';
  }
}
