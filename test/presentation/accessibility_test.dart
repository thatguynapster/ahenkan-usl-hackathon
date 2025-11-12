import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/utils/accessibility_utils.dart';
import 'package:ahenkan/core/utils/app_configuration.dart';

void main() {
  group('Accessibility Utils Tests', () {
    test('meetsMinimumTouchTarget returns true for 44dp or larger', () {
      expect(AccessibilityUtils.meetsMinimumTouchTarget(44.0), true);
      expect(AccessibilityUtils.meetsMinimumTouchTarget(48.0), true);
      expect(AccessibilityUtils.meetsMinimumTouchTarget(43.9), false);
    });

    test('calculateContrastRatio returns correct values', () {
      // Black on white should have high contrast (21:1)
      final blackWhiteRatio = AccessibilityUtils.calculateContrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(blackWhiteRatio, closeTo(21.0, 0.1));

      // White on white should have low contrast (1:1)
      final whiteWhiteRatio = AccessibilityUtils.calculateContrastRatio(
        Colors.white,
        Colors.white,
      );
      expect(whiteWhiteRatio, closeTo(1.0, 0.1));
    });

    test('meetsContrastRequirement validates WCAG AA standard', () {
      // Black on white meets requirement
      expect(
        AccessibilityUtils.meetsContrastRequirement(Colors.black, Colors.white),
        true,
      );

      // Light gray on white may not meet requirement
      expect(
        AccessibilityUtils.meetsContrastRequirement(
          Colors.grey.shade300,
          Colors.white,
        ),
        false,
      );
    });

    test('createSemanticLabel combines label, value, and hint', () {
      final label = AccessibilityUtils.createSemanticLabel(
        label: 'Button',
        value: 'Pressed',
        hint: 'Tap to activate',
      );
      expect(label, 'Button, Pressed, Tap to activate');
    });
  });

  group('App Configuration Tests', () {
    test('minTouchTargetSize meets accessibility standards', () {
      expect(AppConfiguration.minTouchTargetSize, greaterThanOrEqualTo(44.0));
    });

    test('animationDuration is smooth (300ms)', () {
      expect(
        AppConfiguration.animationDuration,
        equals(const Duration(milliseconds: 300)),
      );
    });

    test('feedbackDelay is within 100ms', () {
      expect(
        AppConfiguration.feedbackDelay,
        equals(const Duration(milliseconds: 100)),
      );
    });

    test('minContrastRatio meets WCAG AA standard', () {
      expect(AppConfiguration.minContrastRatio, greaterThanOrEqualTo(4.5));
    });
  });
}
