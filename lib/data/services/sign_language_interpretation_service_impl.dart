import 'dart:async';
import 'dart:io';
import '../../core/utils/enums.dart';
import '../../domain/entities/interpretation_result.dart';
import '../../domain/services/sign_language_interpretation_service.dart';

/// Mock implementation of [SignLanguageInterpretationService] for testing
/// Returns sample interpretations based on the selected language
class SignLanguageInterpretationServiceImpl
    implements SignLanguageInterpretationService {
  // Sample interpretations for different languages
  static const Map<Language, List<String>> _sampleInterpretations = {
    Language.english: [
      'Hello, how are you?',
      'Thank you very much',
      'I need help',
      'Good morning',
      'See you later',
    ],
    Language.akan: ['Maakye', 'Medaase', 'Mehia mmoa', 'Ɛte sɛn?', 'Nante yie'],
    Language.ga: ['Ojekoo', 'Oyiwaladonɔ', 'Mi hiɛ kpakpa', 'Ɔjɔŋmɔ', 'Nɔŋmɛi'],
    Language.ewe: [
      'Ŋdi na mi',
      'Akpe na wò',
      'Mehiã kpekpeɖeŋu',
      'Ŋdi',
      'Miado go emegbe',
    ],
  };

  // Sample confidence scores (between 0.0 and 1.0)
  static const List<double> _sampleConfidences = [
    0.95,
    0.88,
    0.92,
    0.75,
    0.85,
    0.68, // Below threshold for testing
  ];

  int _interpretationIndex = 0;

  @override
  Future<InterpretationResult> interpretVideo(
    File videoFile,
    Language language,
  ) async {
    // Simulate processing time with timeout handling
    try {
      return await Future.delayed(const Duration(milliseconds: 1500), () {
        // Check if video file exists
        if (!videoFile.existsSync()) {
          throw Exception('Video file does not exist: ${videoFile.path}');
        }

        // Get sample interpretation for the language
        final interpretations = _sampleInterpretations[language]!;
        final text =
            interpretations[_interpretationIndex % interpretations.length];

        // Get sample confidence score
        final confidence =
            _sampleConfidences[_interpretationIndex %
                _sampleConfidences.length];

        // Increment index for next interpretation
        _interpretationIndex++;

        return InterpretationResult(
          text: text,
          confidence: confidence,
          language: language,
        );
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            'Sign language interpretation timed out after 5 seconds',
          );
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Failed to interpret video: $e');
    }
  }

  /// Resets the interpretation index for testing purposes
  void resetIndex() {
    _interpretationIndex = 0;
  }
}
