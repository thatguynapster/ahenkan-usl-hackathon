import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_configuration.dart';
import '../../../core/utils/enums.dart';
import '../../../domain/services/sign_language_interpretation_service.dart';
import '../../../domain/services/video_recording_service.dart';
import 'sign_language_interpreter_event.dart';
import 'sign_language_interpreter_state.dart';

/// BLoC for managing sign language interpretation workflow
/// Handles video recording, processing, and interpretation
class SignLanguageInterpreterBloc
    extends Bloc<SignLanguageInterpreterEvent, SignLanguageInterpreterState> {
  final VideoRecordingService _videoRecordingService;
  final SignLanguageInterpretationService _interpretationService;
  final Language _currentLanguage;

  SignLanguageInterpreterBloc({
    required VideoRecordingService videoRecordingService,
    required SignLanguageInterpretationService interpretationService,
    required Language currentLanguage,
  }) : _videoRecordingService = videoRecordingService,
       _interpretationService = interpretationService,
       _currentLanguage = currentLanguage,
       super(const InterpreterInitial()) {
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<ProcessVideo>(_onProcessVideo);
    on<ResetInterpreter>(_onResetInterpreter);
  }

  /// Handles the StartRecording event
  Future<void> _onStartRecording(
    StartRecording event,
    Emitter<SignLanguageInterpreterState> emit,
  ) async {
    // Initialize camera if not already initialized
    if (!_videoRecordingService.isInitialized) {
      final initError = await _videoRecordingService.initialize();
      if (initError != null) {
        emit(InterpreterError(initError.userFriendlyMessage));
        return;
      }
    }

    // Start recording
    final recordError = await _videoRecordingService.startRecording();
    if (recordError != null) {
      emit(InterpreterError(recordError.userFriendlyMessage));
      return;
    }

    // Emit recording state
    emit(const InterpreterRecording());
  }

  /// Handles the StopRecording event
  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<SignLanguageInterpreterState> emit,
  ) async {
    // Stop recording and get the video file
    final (videoFile, stopError) = await _videoRecordingService.stopRecording();

    if (stopError != null) {
      emit(InterpreterError(stopError.userFriendlyMessage));
      return;
    }

    if (videoFile == null) {
      emit(
        const InterpreterError(
          'Failed to save the recorded video. Please try again.',
        ),
      );
      return;
    }

    // Automatically process the video
    add(ProcessVideo(videoFile));
  }

  /// Handles the ProcessVideo event
  Future<void> _onProcessVideo(
    ProcessVideo event,
    Emitter<SignLanguageInterpreterState> emit,
  ) async {
    // Emit processing state
    emit(const InterpreterProcessing());

    try {
      // Interpret the video with timeout
      final result = await _interpretationService
          .interpretVideo(event.videoFile, _currentLanguage)
          .timeout(
            AppConfiguration.interpretationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Interpretation took too long. Please try again.',
              );
            },
          );

      // Convert confidence to percentage (0.0-1.0 to 0-100)
      final confidencePercentage = result.confidence * 100;

      // Check confidence threshold
      if (confidencePercentage < AppConfiguration.minConfidenceThreshold) {
        emit(
          InterpreterError(
            'Could not interpret the sign language clearly (confidence: ${confidencePercentage.toStringAsFixed(1)}%). Please record again with better lighting and clearer gestures.',
          ),
        );
        return;
      }

      // Emit success state
      emit(
        InterpreterSuccess(text: result.text, confidence: result.confidence),
      );
    } on TimeoutException catch (e) {
      emit(InterpreterError(e.message ?? 'Interpretation timed out'));
    } catch (e) {
      emit(
        InterpreterError(
          'Failed to interpret the sign language. Please try again.',
        ),
      );
    }
  }

  /// Handles the ResetInterpreter event
  Future<void> _onResetInterpreter(
    ResetInterpreter event,
    Emitter<SignLanguageInterpreterState> emit,
  ) async {
    emit(const InterpreterInitial());
  }

  @override
  Future<void> close() {
    _videoRecordingService.dispose();
    return super.close();
  }
}
