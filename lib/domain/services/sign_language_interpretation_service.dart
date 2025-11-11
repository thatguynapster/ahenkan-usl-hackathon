import 'dart:io';
import '../../core/utils/enums.dart';
import '../entities/interpretation_result.dart';

/// Service interface for sign language interpretation functionality
/// Handles video analysis and conversion of sign language gestures to text
abstract class SignLanguageInterpretationService {
  /// Interprets sign language gestures from a video file
  ///
  /// Takes a [videoFile] containing sign language gestures and the target [language]
  /// for interpretation. Returns an [InterpretationResult] with the interpreted text,
  /// confidence score, and language.
  ///
  /// Throws [TimeoutException] if interpretation takes longer than 5 seconds
  /// Throws [Exception] if interpretation fails
  Future<InterpretationResult> interpretVideo(
    File videoFile,
    Language language,
  );
}
