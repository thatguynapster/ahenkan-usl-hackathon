import '../../core/error/app_error.dart';
import '../../core/utils/enums.dart';

/// Service interface for speech-to-text functionality
/// Handles speech recognition with language support and microphone permissions
abstract class SpeechToTextService {
  /// Initializes the speech recognition service
  /// Returns an [AppError] if initialization fails (e.g., permission denied)
  Future<AppError?> initialize();

  /// Starts listening for speech input in the specified [language]
  /// Returns the transcribed text when speech is detected and processed
  /// Returns an [AppError] if listening fails or no speech is detected
  Future<(String?, AppError?)> startListening(Language language);

  /// Stops listening for speech input
  /// Should be called to clean up resources when speech input is no longer needed
  void stopListening();

  /// Returns true if the service is currently initialized
  bool get isInitialized;

  /// Returns true if the service is currently listening for speech
  bool get isListening;
}
