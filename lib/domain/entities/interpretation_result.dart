import '../../core/utils/enums.dart';

/// Entity representing the result of sign language interpretation
class InterpretationResult {
  /// Interpreted text from the sign language video
  final String text;

  /// Confidence score of the interpretation (0.0 to 1.0)
  final double confidence;

  /// Language used for interpretation
  final Language language;

  const InterpretationResult({
    required this.text,
    required this.confidence,
    required this.language,
  });

  /// Creates a copy of this result with the given fields replaced
  InterpretationResult copyWith({
    String? text,
    double? confidence,
    Language? language,
  }) {
    return InterpretationResult(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InterpretationResult &&
        other.text == text &&
        other.confidence == confidence &&
        other.language == language;
  }

  @override
  int get hashCode {
    return text.hashCode ^ confidence.hashCode ^ language.hashCode;
  }

  @override
  String toString() {
    return 'InterpretationResult(text: $text, confidence: $confidence, language: $language)';
  }
}
