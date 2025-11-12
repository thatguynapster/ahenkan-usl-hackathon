import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for accessibility and UI polish features
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Provides haptic feedback for important actions
  static Future<void> provideHapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.medium,
  }) async {
    switch (type) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// Validates that a widget meets minimum touch target size
  static bool meetsMinimumTouchTarget(double size) {
    return size >= 44.0;
  }

  /// Calculates contrast ratio between two colors
  /// Returns a value between 1 and 21
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Checks if contrast ratio meets WCAG AA standard (4.5:1)
  static bool meetsContrastRequirement(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 4.5;
  }

  /// Creates a semantic label for screen readers
  static String createSemanticLabel({
    required String label,
    String? hint,
    String? value,
  }) {
    final parts = <String>[label];
    if (value != null) parts.add(value);
    if (hint != null) parts.add(hint);
    return parts.join(', ');
  }
}

/// Enum for different types of haptic feedback
enum HapticFeedbackType { light, medium, heavy, selection }
