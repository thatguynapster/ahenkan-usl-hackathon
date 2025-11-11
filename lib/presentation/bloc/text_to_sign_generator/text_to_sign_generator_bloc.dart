import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_configuration.dart';
import '../../../core/utils/enums.dart';
import '../../../domain/services/sign_language_generation_service.dart';
import '../../../domain/services/speech_to_text_service.dart';
import 'text_to_sign_generator_event.dart';
import 'text_to_sign_generator_state.dart';

/// BLoC for managing text-to-sign language generation workflow
/// Handles text input, speech input, and video generation
class TextToSignGeneratorBloc
    extends Bloc<TextToSignGeneratorEvent, TextToSignGeneratorState> {
  final SignLanguageGenerationService _generationService;
  final SpeechToTextService _speechToTextService;
  final Language _currentLanguage;

  TextToSignGeneratorBloc({
    required SignLanguageGenerationService generationService,
    required SpeechToTextService speechToTextService,
    required Language currentLanguage,
  }) : _generationService = generationService,
       _speechToTextService = speechToTextService,
       _currentLanguage = currentLanguage,
       super(const GeneratorInitial()) {
    on<GenerateFromText>(_onGenerateFromText);
    on<GenerateFromSpeech>(_onGenerateFromSpeech);
    on<ReplayVideo>(_onReplayVideo);
    on<ClearGeneration>(_onClearGeneration);
  }

  /// Handles the GenerateFromText event
  Future<void> _onGenerateFromText(
    GenerateFromText event,
    Emitter<TextToSignGeneratorState> emit,
  ) async {
    // Validate text input length
    if (event.text.isEmpty) {
      emit(const GeneratorError('Please enter some text to convert.'));
      return;
    }

    if (event.text.length > AppConfiguration.maxTextInputLength) {
      emit(
        GeneratorError(
          'Text is too long. Maximum ${AppConfiguration.maxTextInputLength} characters allowed.',
        ),
      );
      return;
    }

    // Emit processing state
    emit(const GeneratorProcessing());

    try {
      // Generate sign language video with timeout
      final videoPath = await _generationService
          .generateSignVideo(event.text, _currentLanguage)
          .timeout(
            AppConfiguration.generationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Video generation took too long. Please try again.',
              );
            },
          );

      // Emit success state
      emit(GeneratorSuccess(videoPath: videoPath));
    } on TimeoutException catch (e) {
      emit(GeneratorError(e.message ?? 'Video generation timed out'));
    } catch (e) {
      emit(
        const GeneratorError(
          'Failed to generate sign language video. Please try again.',
        ),
      );
    }
  }

  /// Handles the GenerateFromSpeech event
  Future<void> _onGenerateFromSpeech(
    GenerateFromSpeech event,
    Emitter<TextToSignGeneratorState> emit,
  ) async {
    // Initialize speech service if not already initialized
    if (!_speechToTextService.isInitialized) {
      final initError = await _speechToTextService.initialize();
      if (initError != null) {
        emit(GeneratorError(initError.userFriendlyMessage));
        return;
      }
    }

    // Emit processing state (listening for speech)
    emit(const GeneratorProcessing());

    // Start listening for speech
    final (transcribedText, speechError) = await _speechToTextService
        .startListening(_currentLanguage);

    if (speechError != null) {
      emit(GeneratorError(speechError.userFriendlyMessage));
      return;
    }

    if (transcribedText == null || transcribedText.isEmpty) {
      emit(
        const GeneratorError(
          'No speech detected. Please try again and speak clearly.',
        ),
      );
      return;
    }

    // Validate transcribed text length
    if (transcribedText.length > AppConfiguration.maxTextInputLength) {
      emit(
        GeneratorError(
          'Speech is too long. Maximum ${AppConfiguration.maxTextInputLength} characters allowed.',
        ),
      );
      return;
    }

    try {
      // Generate sign language video with timeout
      final videoPath = await _generationService
          .generateSignVideo(transcribedText, _currentLanguage)
          .timeout(
            AppConfiguration.generationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Video generation took too long. Please try again.',
              );
            },
          );

      // Emit success state
      emit(GeneratorSuccess(videoPath: videoPath));
    } on TimeoutException catch (e) {
      emit(GeneratorError(e.message ?? 'Video generation timed out'));
    } catch (e) {
      emit(
        const GeneratorError(
          'Failed to generate sign language video. Please try again.',
        ),
      );
    }
  }

  /// Handles the ReplayVideo event
  Future<void> _onReplayVideo(
    ReplayVideo event,
    Emitter<TextToSignGeneratorState> emit,
  ) async {
    // ReplayVideo doesn't change state - it's handled by the UI layer
    // The video player should restart playback when this event is received
    // No state emission needed here
  }

  /// Handles the ClearGeneration event
  Future<void> _onClearGeneration(
    ClearGeneration event,
    Emitter<TextToSignGeneratorState> emit,
  ) async {
    emit(const GeneratorInitial());
  }

  @override
  Future<void> close() {
    _speechToTextService.stopListening();
    return super.close();
  }
}
