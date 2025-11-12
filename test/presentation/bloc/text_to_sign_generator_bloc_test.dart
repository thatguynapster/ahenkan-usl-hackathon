import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/error/app_error.dart';
import 'package:ahenkan/core/utils/app_configuration.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/domain/services/sign_language_generation_service.dart';
import 'package:ahenkan/domain/services/speech_to_text_service.dart';
import 'package:ahenkan/presentation/bloc/text_to_sign_generator/text_to_sign_generator_bloc.dart';
import 'package:ahenkan/presentation/bloc/text_to_sign_generator/text_to_sign_generator_event.dart';
import 'package:ahenkan/presentation/bloc/text_to_sign_generator/text_to_sign_generator_state.dart';

// Mock SignLanguageGenerationService
class MockSignLanguageGenerationService
    implements SignLanguageGenerationService {
  String? mockVideoPath;
  Exception? mockException;
  Duration? mockDelay;

  @override
  Future<String> generateSignVideo(String text, Language language) async {
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
    }

    if (mockException != null) {
      throw mockException!;
    }

    return mockVideoPath ?? '/path/to/generated_video.mp4';
  }
}

// Mock SpeechToTextService
class MockSpeechToTextService implements SpeechToTextService {
  bool _isInitialized = false;
  bool _isListening = false;
  AppError? initializeError;
  AppError? listeningError;
  String? transcribedText;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isListening => _isListening;

  @override
  Future<AppError?> initialize() async {
    if (initializeError != null) {
      return initializeError;
    }
    _isInitialized = true;
    return null;
  }

  @override
  Future<(String?, AppError?)> startListening(Language language) async {
    _isListening = true;
    if (listeningError != null) {
      _isListening = false;
      return (null, listeningError);
    }
    _isListening = false;
    return (transcribedText, null);
  }

  @override
  void stopListening() {
    _isListening = false;
  }
}

void main() {
  late TextToSignGeneratorBloc bloc;
  late MockSignLanguageGenerationService mockGenerationService;
  late MockSpeechToTextService mockSpeechService;

  setUp(() {
    mockGenerationService = MockSignLanguageGenerationService();
    mockSpeechService = MockSpeechToTextService();
    bloc = TextToSignGeneratorBloc(
      generationService: mockGenerationService,
      speechToTextService: mockSpeechService,
      currentLanguage: Language.english,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('TextToSignGeneratorBloc', () {
    test('initial state should be GeneratorInitial', () {
      expect(bloc.state, equals(const GeneratorInitial()));
    });

    group('GenerateFromText Event', () {
      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorProcessing and GeneratorSuccess when text generation succeeds',
        build: () {
          mockGenerationService.mockVideoPath = '/path/to/video.mp4';
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromText('Hello world')),
        expect: () => [
          const GeneratorProcessing(),
          const GeneratorSuccess(
            videoPath: '/path/to/video.mp4',
            inputText: 'Hello world',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when text is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const GenerateFromText('')),
        expect: () => [
          const GeneratorError('Please enter some text to convert.'),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when text exceeds maximum length',
        build: () => bloc,
        act: (bloc) => bloc.add(
          GenerateFromText('a' * (AppConfiguration.maxTextInputLength + 1)),
        ),
        expect: () => [
          GeneratorError(
            'Text is too long. Maximum ${AppConfiguration.maxTextInputLength} characters allowed.',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorSuccess when text is exactly at maximum length',
        build: () {
          mockGenerationService.mockVideoPath = '/path/to/max_length_video.mp4';
          return bloc;
        },
        act: (bloc) => bloc.add(
          GenerateFromText('a' * AppConfiguration.maxTextInputLength),
        ),
        expect: () {
          final maxText = 'a' * AppConfiguration.maxTextInputLength;
          return [
            const GeneratorProcessing(),
            GeneratorSuccess(
              videoPath: '/path/to/max_length_video.mp4',
              inputText: maxText,
            ),
          ];
        },
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when generation times out',
        build: () {
          mockGenerationService.mockDelay =
              AppConfiguration.generationTimeout + const Duration(seconds: 1);
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromText('Test text')),
        wait: AppConfiguration.generationTimeout + const Duration(seconds: 2),
        expect: () => [
          const GeneratorProcessing(),
          isA<GeneratorError>().having(
            (e) => e.message,
            'message',
            contains('took too long'),
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when generation throws exception',
        build: () {
          mockGenerationService.mockException = Exception('Generation failed');
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromText('Test text')),
        expect: () => [
          const GeneratorProcessing(),
          const GeneratorError(
            'Failed to generate sign language video. Please try again.',
          ),
        ],
      );
    });

    group('GenerateFromSpeech Event', () {
      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorProcessing and GeneratorSuccess when speech generation succeeds',
        build: () {
          mockSpeechService.transcribedText = 'Hello from speech';
          mockGenerationService.mockVideoPath = '/path/to/speech_video.mp4';
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [
          const GeneratorListening(),
          const GeneratorProcessing(),
          const GeneratorSuccess(
            videoPath: '/path/to/speech_video.mp4',
            inputText: 'Hello from speech',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when speech service initialization fails',
        build: () {
          mockSpeechService.initializeError = const AppError(
            type: ErrorType.speech,
            message: 'Init failed',
            userFriendlyMessage: 'Could not access microphone',
            isRecoverable: true,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [const GeneratorError('Could not access microphone')],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when speech listening fails',
        build: () {
          mockSpeechService.listeningError = const AppError(
            type: ErrorType.speech,
            message: 'Listening failed',
            userFriendlyMessage: 'Speech recognition failed',
            isRecoverable: true,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [
          const GeneratorListening(),
          const GeneratorError('Speech recognition failed'),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when no speech is detected',
        build: () {
          mockSpeechService.transcribedText = null;
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [
          const GeneratorListening(),
          const GeneratorError(
            'No speech detected. Please try again and speak clearly.',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when transcribed text is empty',
        build: () {
          mockSpeechService.transcribedText = '';
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [
          const GeneratorListening(),
          const GeneratorError(
            'No speech detected. Please try again and speak clearly.',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when transcribed text exceeds maximum length',
        build: () {
          mockSpeechService.transcribedText =
              'a' * (AppConfiguration.maxTextInputLength + 1);
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [
          const GeneratorListening(),
          GeneratorError(
            'Speech is too long. Maximum ${AppConfiguration.maxTextInputLength} characters allowed.',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when video generation times out after speech',
        build: () {
          mockSpeechService.transcribedText = 'Test speech';
          mockGenerationService.mockDelay =
              AppConfiguration.generationTimeout + const Duration(seconds: 1);
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        wait: AppConfiguration.generationTimeout + const Duration(seconds: 2),
        expect: () => [
          const GeneratorListening(),
          const GeneratorProcessing(),
          isA<GeneratorError>().having(
            (e) => e.message,
            'message',
            contains('took too long'),
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorError when video generation fails after speech',
        build: () {
          mockSpeechService.transcribedText = 'Test speech';
          mockGenerationService.mockException = Exception('Generation failed');
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [
          const GeneratorListening(),
          const GeneratorProcessing(),
          const GeneratorError(
            'Failed to generate sign language video. Please try again.',
          ),
        ],
      );
    });

    group('ReplayVideo Event', () {
      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should not emit state change when replaying (handled by UI)',
        build: () => bloc,
        seed: () => const GeneratorSuccess(
          videoPath: '/path/to/video.mp4',
          inputText: 'Test text',
        ),
        act: (bloc) => bloc.add(const ReplayVideo()),
        expect: () => [],
        verify: (_) {
          // State should remain unchanged
          expect(
            bloc.state,
            const GeneratorSuccess(
              videoPath: '/path/to/video.mp4',
              inputText: 'Test text',
            ),
          );
        },
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should not emit any state when not in success state',
        build: () => bloc,
        seed: () => const GeneratorInitial(),
        act: (bloc) => bloc.add(const ReplayVideo()),
        expect: () => [],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should not emit any state when in error state',
        build: () => bloc,
        seed: () => const GeneratorError('Some error'),
        act: (bloc) => bloc.add(const ReplayVideo()),
        expect: () => [],
      );
    });

    group('ClearGeneration Event', () {
      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorInitial when clearing from success state',
        build: () => bloc,
        seed: () => const GeneratorSuccess(
          videoPath: '/path/to/video.mp4',
          inputText: 'Test text',
        ),
        act: (bloc) => bloc.add(const ClearGeneration()),
        expect: () => [const GeneratorInitial()],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorInitial when clearing from error state',
        build: () => bloc,
        seed: () => const GeneratorError('Some error'),
        act: (bloc) => bloc.add(const ClearGeneration()),
        expect: () => [const GeneratorInitial()],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should emit GeneratorInitial when clearing from processing state',
        build: () => bloc,
        seed: () => const GeneratorProcessing(),
        act: (bloc) => bloc.add(const ClearGeneration()),
        expect: () => [const GeneratorInitial()],
      );
    });

    group('Complete Text-to-Sign Flow', () {
      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should complete full text flow: generate -> success -> clear',
        build: () {
          mockGenerationService.mockVideoPath = '/path/to/complete_video.mp4';
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const GenerateFromText('Complete flow test'));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const ClearGeneration());
        },
        expect: () => [
          const GeneratorProcessing(),
          const GeneratorSuccess(
            videoPath: '/path/to/complete_video.mp4',
            inputText: 'Complete flow test',
          ),
          const GeneratorInitial(),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should complete full speech flow: generate from speech -> success -> clear',
        build: () {
          mockSpeechService.transcribedText = 'Speech flow test';
          mockGenerationService.mockVideoPath =
              '/path/to/speech_flow_video.mp4';
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const GenerateFromSpeech());
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const ClearGeneration());
        },
        expect: () => [
          const GeneratorListening(),
          const GeneratorProcessing(),
          const GeneratorSuccess(
            videoPath: '/path/to/speech_flow_video.mp4',
            inputText: 'Speech flow test',
          ),
          const GeneratorInitial(),
        ],
      );
    });

    group('State Transitions', () {
      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should transition from Initial -> Processing -> Success',
        build: () {
          mockGenerationService.mockVideoPath = '/path/to/transition_video.mp4';
          return bloc;
        },
        act: (bloc) {
          expect(bloc.state, const GeneratorInitial());
          bloc.add(const GenerateFromText('Transition test'));
        },
        expect: () => [
          const GeneratorProcessing(),
          const GeneratorSuccess(
            videoPath: '/path/to/transition_video.mp4',
            inputText: 'Transition test',
          ),
        ],
        verify: (_) {
          expect(
            bloc.state,
            const GeneratorSuccess(
              videoPath: '/path/to/transition_video.mp4',
              inputText: 'Transition test',
            ),
          );
        },
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should transition from Success -> Initial on clear',
        build: () => bloc,
        seed: () => const GeneratorSuccess(
          videoPath: '/path/to/video.mp4',
          inputText: 'Test text',
        ),
        act: (bloc) => bloc.add(const ClearGeneration()),
        expect: () => [const GeneratorInitial()],
        verify: (_) {
          expect(bloc.state, const GeneratorInitial());
        },
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should transition from Error -> Initial on clear',
        build: () => bloc,
        seed: () => const GeneratorError('Error occurred'),
        act: (bloc) => bloc.add(const ClearGeneration()),
        expect: () => [const GeneratorInitial()],
      );
    });

    group('Character Limit Validation', () {
      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should accept text with 1 character',
        build: () {
          mockGenerationService.mockVideoPath = '/path/to/short_video.mp4';
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromText('a')),
        expect: () => [
          const GeneratorProcessing(),
          const GeneratorSuccess(
            videoPath: '/path/to/short_video.mp4',
            inputText: 'a',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should accept text with exactly 500 characters',
        build: () {
          mockGenerationService.mockVideoPath = '/path/to/max_video.mp4';
          return bloc;
        },
        act: (bloc) => bloc.add(
          GenerateFromText('a' * AppConfiguration.maxTextInputLength),
        ),
        expect: () {
          final maxText = 'a' * AppConfiguration.maxTextInputLength;
          return [
            const GeneratorProcessing(),
            GeneratorSuccess(
              videoPath: '/path/to/max_video.mp4',
              inputText: maxText,
            ),
          ];
        },
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should reject text with 501 characters',
        build: () => bloc,
        act: (bloc) => bloc.add(
          GenerateFromText('a' * (AppConfiguration.maxTextInputLength + 1)),
        ),
        expect: () => [
          GeneratorError(
            'Text is too long. Maximum ${AppConfiguration.maxTextInputLength} characters allowed.',
          ),
        ],
      );

      blocTest<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        'should reject transcribed speech with 501 characters',
        build: () {
          mockSpeechService.transcribedText =
              'a' * (AppConfiguration.maxTextInputLength + 1);
          return bloc;
        },
        act: (bloc) => bloc.add(const GenerateFromSpeech()),
        expect: () => [
          const GeneratorListening(),
          GeneratorError(
            'Speech is too long. Maximum ${AppConfiguration.maxTextInputLength} characters allowed.',
          ),
        ],
      );
    });
  });
}
