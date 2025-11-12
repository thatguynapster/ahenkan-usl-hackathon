import 'package:video_player/video_player.dart';

/// Manages video player instances for proper lifecycle cleanup
/// Tracks all active video players and provides centralized disposal
class VideoPlayerManager {
  final Set<VideoPlayerController> _activeControllers = {};

  /// Register a video player controller for lifecycle management
  void registerController(VideoPlayerController controller) {
    _activeControllers.add(controller);
  }

  /// Unregister a video player controller (when manually disposed)
  void unregisterController(VideoPlayerController controller) {
    _activeControllers.remove(controller);
  }

  /// Pause all active video players
  void pauseAll() {
    for (final controller in _activeControllers) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  /// Dispose all active video players
  void disposeAll() {
    for (final controller in _activeControllers) {
      try {
        controller.dispose();
      } catch (e) {
        // Ignore errors during disposal
      }
    }
    _activeControllers.clear();
  }

  /// Get count of active controllers
  int get activeCount => _activeControllers.length;
}
