/// Class containing application-wide configuration constants
class AppConfiguration {
  // Private constructor to prevent instantiation
  AppConfiguration._();

  /// Maximum length of text input for text-to-sign conversion (in characters)
  static const int maxTextInputLength = 500;

  /// Minimum confidence threshold for sign language interpretation (percentage)
  static const int minConfidenceThreshold = 70;

  /// Maximum time to wait for sign language interpretation to complete
  static const Duration interpretationTimeout = Duration(seconds: 5);

  /// Maximum time to wait for sign language video generation to complete
  static const Duration generationTimeout = Duration(seconds: 3);

  /// Minimum frame rate for generated sign language videos (frames per second)
  static const int minFrameRate = 24;

  /// Minimum touch target size for interactive elements (in density-independent pixels)
  static const double minTouchTargetSize = 44.0;

  /// Maximum delay for visual feedback after user interaction
  static const Duration feedbackDelay = Duration(milliseconds: 100);

  /// Minimum contrast ratio for text and controls (WCAG AA standard)
  static const double minContrastRatio = 4.5;

  /// Maximum time for mode switching transitions
  static const Duration modeSwitchDuration = Duration(seconds: 1);

  /// Standard animation duration for UI transitions
  static const Duration animationDuration = Duration(milliseconds: 300);
}
