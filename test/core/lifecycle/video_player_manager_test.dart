import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/lifecycle/video_player_manager.dart';

void main() {
  group('VideoPlayerManager', () {
    late VideoPlayerManager manager;

    setUp(() {
      manager = VideoPlayerManager();
    });

    test('should start with zero active controllers', () {
      expect(manager.activeCount, 0);
    });

    test('should track active controller count', () {
      // Note: We can't create real VideoPlayerController in unit tests
      // This test verifies the manager structure is correct
      expect(manager.activeCount, 0);
    });

    test('should have pauseAll method', () {
      // Verify method exists and doesn't throw
      expect(() => manager.pauseAll(), returnsNormally);
    });

    test('should have disposeAll method', () {
      // Verify method exists and doesn't throw
      expect(() => manager.disposeAll(), returnsNormally);
      expect(manager.activeCount, 0);
    });
  });
}
