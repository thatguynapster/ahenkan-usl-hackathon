import 'package:flutter/widgets.dart';
import '../../domain/services/video_recording_service.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../presentation/bloc/language_manager/language_manager_bloc.dart';
import '../../presentation/bloc/language_manager/language_manager_state.dart';
import '../../presentation/bloc/session_manager/session_manager_bloc.dart';
import '../../presentation/bloc/session_manager/session_manager_event.dart';
import 'video_player_manager.dart';

/// Manages app lifecycle events and coordinates resource cleanup
/// Handles camera disposal, video player cleanup, session clearing, and language preference saving
class AppLifecycleManager with WidgetsBindingObserver {
  final VideoRecordingService _videoRecordingService;
  final StorageRepository _storageRepository;
  final LanguageManagerBloc _languageManagerBloc;
  final SessionManagerBloc _sessionManagerBloc;
  final VideoPlayerManager _videoPlayerManager;

  bool _isInitialized = false;
  bool _isPaused = false;

  AppLifecycleManager({
    required VideoRecordingService videoRecordingService,
    required StorageRepository storageRepository,
    required LanguageManagerBloc languageManagerBloc,
    required SessionManagerBloc sessionManagerBloc,
    required VideoPlayerManager videoPlayerManager,
  }) : _videoRecordingService = videoRecordingService,
       _storageRepository = storageRepository,
       _languageManagerBloc = languageManagerBloc,
       _sessionManagerBloc = sessionManagerBloc,
       _videoPlayerManager = videoPlayerManager;

  /// Initialize the lifecycle manager and register as observer
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }
  }

  /// Dispose the lifecycle manager and unregister observer
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  /// Called when app is resumed from background
  void _onAppResumed() {
    _isPaused = false;
    // Camera will be reinitialized when needed by the recording service
  }

  /// Called when app becomes inactive (e.g., incoming call)
  void _onAppInactive() {
    // Pause camera if recording
    if (_videoRecordingService.isRecording) {
      // Stop recording to prevent issues
      _videoRecordingService.stopRecording();
    }

    // Pause all video players
    _videoPlayerManager.pauseAll();
  }

  /// Called when app is paused (moved to background)
  Future<void> _onAppPaused() async {
    _isPaused = true;

    // Stop recording if active
    if (_videoRecordingService.isRecording) {
      await _videoRecordingService.stopRecording();
    }

    // Pause all video players
    _videoPlayerManager.pauseAll();

    // Dispose camera resources to free up system resources
    _videoRecordingService.dispose();

    // Save language preference
    await _saveLanguagePreference();
  }

  /// Called when app is detached (about to be terminated)
  Future<void> _onAppDetached() async {
    // Perform final cleanup
    await _performFinalCleanup();
  }

  /// Save the current language preference
  Future<void> _saveLanguagePreference() async {
    try {
      final languageState = _languageManagerBloc.state;
      if (languageState is LanguageSelected) {
        await _storageRepository.saveLanguagePreference(languageState.language);
      }
    } catch (e) {
      // Log error but don't throw - we don't want to crash on cleanup
      debugPrint('Error saving language preference: $e');
    }
  }

  /// Clear session history
  Future<void> _clearSessionHistory() async {
    try {
      _sessionManagerBloc.add(const ClearSession());
    } catch (e) {
      debugPrint('Error clearing session history: $e');
    }
  }

  /// Perform final cleanup when app is closing
  Future<void> _performFinalCleanup() async {
    // Save language preference one final time
    await _saveLanguagePreference();

    // Clear session history as per requirement 7.4
    await _clearSessionHistory();

    // Dispose all video players
    _videoPlayerManager.disposeAll();

    // Dispose camera resources
    _videoRecordingService.dispose();
  }

  /// Check if app is currently paused
  bool get isPaused => _isPaused;
}
