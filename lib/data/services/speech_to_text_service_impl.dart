import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/error/app_error.dart';
import '../../core/utils/enums.dart';
import '../../domain/services/speech_to_text_service.dart';

/// Implementation of [SpeechToTextService] using the speech_to_text package
/// Handles speech recognition with language support and microphone permissions
class SpeechToTextServiceImpl implements SpeechToTextService {
  final stt.SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastTranscription = '';
  Completer<(String?, AppError?)>? _listeningCompleter;

  SpeechToTextServiceImpl({stt.SpeechToText? speechToText})
    : _speechToText = speechToText ?? stt.SpeechToText();

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isListening => _isListening;

  @override
  Future<AppError?> initialize() async {
    try {
      // Initialize speech recognition
      final available = await _speechToText.initialize(
        onError: (error) {
          // Handle errors during initialization
          if (_listeningCompleter != null &&
              !_listeningCompleter!.isCompleted) {
            _listeningCompleter!.complete((
              null,
              AppError(
                type: ErrorType.speech,
                message: 'Speech recognition error: ${error.errorMsg}',
                userFriendlyMessage:
                    'Unable to recognize speech. Please try again.',
                isRecoverable: true,
              ),
            ));
          }
        },
        onStatus: (status) {
          // Update listening status
          _isListening = status == 'listening';
        },
      );

      if (!available) {
        return const AppError(
          type: ErrorType.speech,
          message: 'Speech recognition not available on this device',
          userFriendlyMessage:
              'Speech recognition is not available on your device.',
          isRecoverable: false,
        );
      }

      _isInitialized = true;
      return null;
    } catch (e) {
      return AppError(
        type: ErrorType.permission,
        message: 'Failed to initialize speech recognition: $e',
        userFriendlyMessage:
            'Unable to access microphone. Please check permissions.',
        isRecoverable: true,
      );
    }
  }

  @override
  Future<(String?, AppError?)> startListening(Language language) async {
    if (!_isInitialized) {
      return (
        null,
        const AppError(
          type: ErrorType.speech,
          message: 'Speech recognition not initialized',
          userFriendlyMessage:
              'Speech recognition is not ready. Please try again.',
          isRecoverable: true,
        ),
      );
    }

    if (_isListening) {
      return (
        null,
        const AppError(
          type: ErrorType.speech,
          message: 'Already listening for speech',
          userFriendlyMessage: 'Already listening. Please wait.',
          isRecoverable: false,
        ),
      );
    }

    _listeningCompleter = Completer<(String?, AppError?)>();
    _lastTranscription = '';

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastTranscription = result.recognizedWords;

          // Complete when final result is received
          if (result.finalResult) {
            if (_listeningCompleter != null &&
                !_listeningCompleter!.isCompleted) {
              if (_lastTranscription.isEmpty) {
                _listeningCompleter!.complete((
                  null,
                  const AppError(
                    type: ErrorType.speech,
                    message: 'No speech detected',
                    userFriendlyMessage:
                        'No speech detected. Please try speaking again.',
                    isRecoverable: true,
                  ),
                ));
              } else {
                _listeningCompleter!.complete((_lastTranscription, null));
              }
            }
            _isListening = false;
          }
        },
        localeId: language.code,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
      );

      _isListening = true;

      // Wait for the result with a timeout
      final result = await _listeningCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          stopListening();
          return (
            null,
            const AppError(
              type: ErrorType.speech,
              message: 'Speech recognition timed out',
              userFriendlyMessage: 'Listening timed out. Please try again.',
              isRecoverable: true,
            ),
          );
        },
      );

      return result;
    } catch (e) {
      _isListening = false;
      return (
        null,
        AppError(
          type: ErrorType.speech,
          message: 'Failed to start listening: $e',
          userFriendlyMessage:
              'Unable to start listening. Please check microphone permissions.',
          isRecoverable: true,
        ),
      );
    }
  }

  @override
  void stopListening() {
    if (_isListening) {
      _speechToText.stop();
      _isListening = false;

      // Complete the completer if it's still waiting
      if (_listeningCompleter != null && !_listeningCompleter!.isCompleted) {
        if (_lastTranscription.isEmpty) {
          _listeningCompleter!.complete((
            null,
            const AppError(
              type: ErrorType.speech,
              message: 'Listening stopped with no speech detected',
              userFriendlyMessage: 'No speech detected. Please try again.',
              isRecoverable: true,
            ),
          ));
        } else {
          _listeningCompleter!.complete((_lastTranscription, null));
        }
      }
    }
  }
}
