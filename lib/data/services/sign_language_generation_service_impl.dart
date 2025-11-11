import 'dart:async';
import '../../core/utils/enums.dart';
import '../../domain/services/sign_language_generation_service.dart';

/// Mock implementation of [SignLanguageGenerationService] for testing
/// Returns sample video paths based on the selected language
class SignLanguageGenerationServiceImpl
    implements SignLanguageGenerationService {
  // Sample video paths for different languages
  // In a real implementation, these would be actual generated video files
  static const Map<Language, List<String>> _sampleVideoPaths = {
    Language.english: [
      '/videos/en/hello.mp4',
      '/videos/en/thank_you.mp4',
      '/videos/en/help.mp4',
      '/videos/en/good_morning.mp4',
      '/videos/en/goodbye.mp4',
    ],
    Language.akan: [
      '/videos/ak/maakye.mp4',
      '/videos/ak/medaase.mp4',
      '/videos/ak/mmoa.mp4',
      '/videos/ak/ete_sen.mp4',
      '/videos/ak/nante_yie.mp4',
    ],
    Language.ga: [
      '/videos/gaa/ojekoo.mp4',
      '/videos/gaa/oyiwaladonɔ.mp4',
      '/videos/gaa/kpakpa.mp4',
      '/videos/gaa/ojongmo.mp4',
      '/videos/gaa/nongmei.mp4',
    ],
    Language.ewe: [
      '/videos/ee/ngdi_na_mi.mp4',
      '/videos/ee/akpe_na_wo.mp4',
      '/videos/ee/kpekpedengu.mp4',
      '/videos/ee/ngdi.mp4',
      '/videos/ee/emegbe.mp4',
    ],
  };

  int _videoIndex = 0;

  @override
  Future<String> generateSignVideo(String text, Language language) async {
    // Validate input
    if (text.isEmpty) {
      throw Exception('Text cannot be empty');
    }

    // Simulate video generation with timeout handling
    try {
      return await Future.delayed(const Duration(milliseconds: 1200), () {
        // Get sample video path for the language
        final videoPaths = _sampleVideoPaths[language]!;
        final videoPath = videoPaths[_videoIndex % videoPaths.length];

        // Increment index for next generation
        _videoIndex++;

        // Return the video path
        // In a real implementation, this would be the path to an actual
        // generated video file with minimum 24 fps
        return videoPath;
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException(
            'Sign language video generation timed out after 3 seconds',
          );
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Failed to generate sign language video: $e');
    }
  }

  /// Resets the video index for testing purposes
  void resetIndex() {
    _videoIndex = 0;
  }
}
