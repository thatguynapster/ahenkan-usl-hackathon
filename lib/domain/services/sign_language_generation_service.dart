import '../../core/utils/enums.dart';

/// Service interface for sign language generation functionality
/// Handles conversion of text to animated sign language videos
abstract class SignLanguageGenerationService {
  /// Generates an animated sign language video from text input
  ///
  /// Takes [text] to be converted and the target [language] for sign language.
  /// Returns the file path to the generated video.
  ///
  /// The generated video will have a minimum frame rate of 24 fps.
  ///
  /// Throws [TimeoutException] if generation takes longer than 3 seconds
  /// Throws [Exception] if generation fails
  Future<String> generateSignVideo(String text, Language language);
}
