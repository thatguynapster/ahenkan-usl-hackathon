import 'dart:async';
import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/error/app_error.dart';
import 'package:ahenkan/core/utils/app_configuration.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/domain/entities/interpretation_result.dart';
import 'package:ahenkan/domain/services/sign_language_interpretation_service.dart';
import 'package:ahenkan/domain/services/video_recording_service.dart';
import 'package:ahenkan/presentation/bloc/sign_language_interpreter/sign_language_interpreter_bloc.dart';
import 'package:ahenkan/presentation/bloc/sign_language_interpreter/sign_language_interpreter_event.dart';
import 'package:ahenkan/presentation/bloc/sign_language_interpreter/sign_language_interpreter_state.dart';

// Mock VideoRecordingService
class MockVideoRecordingService implements VideoRecordingService {
  bool _isInitialized = false;
  bool _isRecording = false;
  AppError? initializeError;
  AppError? startRecordingError;
  AppError? stopRecordingError;
  File? recordedFile;
  bool shouldReturnNullFile = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<AppError?> initialize() async {
    if (initializeError != null) {
      return initializeError;
    }
    _isInitialized = true;
    return null;
  }

  @override
  Future<AppError?> startRecording() async {
    if (startRecordingError != null) {
      return startRecordingError;
    }
    _isRecording = true;
    return null;
  }

  @override
  Future<(File?, AppError?)> stopRecording() async {
    _isRecording = false;
    if (stopRecordingError != null) {
      return (null, stopRecordingError);
    }
    if (shouldReturnNullFile) {
      return (null, null);
    }
    return (recordedFile ?? File('test_video.mp4'), null);
  }

  @override
  void dispose() {
    _isInitialized = false;
    _isRecording = false;
  }
}

// Mock SignLanguageInterpretationService
class MockSignLanguageInterpretationService
    implements SignLanguageInterpretationService {
  InterpretationResult? mockResult;
  Exception? mockException;
  Duration? mockDelay;

  @override
  Future<InterpretationResult> interpretVideo(
    File videoFile,
    Language language,
  ) async {
    if (mockDelay != null) {
      await Future.delayed(mockDelay!);
    }

    if (mockException != null) {
      throw mockException!;
    }

    return mockResult ??
        InterpretationResult(
          text: 'Hello',
          confidence: 0.85,
          language: language,
        );
  }
}

void main() {
  late SignLanguageInterpreterBloc bloc;
  late MockVideoRecordingService mockVideoService;
  late MockSignLanguageInterpretationService mockInterpretationService;

  setUp(() {
    mockVideoService = MockVideoRecordingService();
    mockInterpretationService = MockSignLanguageInterpretationService();
    bloc = SignLanguageInterpreterBloc(
      videoRecordingService: mockVideoService,
      interpretationService: mockInterpretationService,
      currentLanguage: Language.english,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('SignLanguageInterpreterBloc', () {
    test('initial state should be InterpreterInitial', () {
      expect(bloc.state, equals(const InterpreterInitial()));
    });

    group('StartRecording Event', () {
      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterRecording when recording starts successfully',
        build: () => bloc,
        act: (bloc) => bloc.add(const StartRecording()),
        expect: () => [const InterpreterRecording()],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when camera initialization fails',
        build: () {
          mockVideoService.initializeError = const AppError(
            type: ErrorType.camera,
            message: 'Camera init failed',
            userFriendlyMessage: 'Could not access camera',
            isRecoverable: true,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const StartRecording()),
        expect: () => [const InterpreterError('Could not access camera')],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when recording fails to start',
        build: () {
          mockVideoService.startRecordingError = const AppError(
            type: ErrorType.camera,
            message: 'Recording failed',
            userFriendlyMessage: 'Failed to start recording',
            isRecoverable: true,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const StartRecording()),
        expect: () => [const InterpreterError('Failed to start recording')],
      );
    });

    group('StopRecording Event', () {
      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterProcessing and InterpreterSuccess when recording stops and interpretation succeeds',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Hello world',
            confidence: 0.85,
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const StopRecording()),
        expect: () => [
          const InterpreterProcessing(),
          const InterpreterSuccess(text: 'Hello world', confidence: 0.85),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when stop recording fails',
        build: () {
          mockVideoService.stopRecordingError = const AppError(
            type: ErrorType.camera,
            message: 'Stop failed',
            userFriendlyMessage: 'Failed to stop recording',
            isRecoverable: true,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const StopRecording()),
        expect: () => [const InterpreterError('Failed to stop recording')],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when video file is null',
        build: () {
          mockVideoService.shouldReturnNullFile = true;
          return bloc;
        },
        act: (bloc) => bloc.add(const StopRecording()),
        expect: () => [
          const InterpreterError(
            'Failed to save the recorded video. Please try again.',
          ),
        ],
      );
    });

    group('ProcessVideo Event', () {
      final testFile = File('test_video.mp4');

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterProcessing and InterpreterSuccess with high confidence',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Good morning',
            confidence: 0.95,
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(ProcessVideo(testFile)),
        expect: () => [
          const InterpreterProcessing(),
          const InterpreterSuccess(text: 'Good morning', confidence: 0.95),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when confidence is below threshold',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Unclear',
            confidence: 0.65, // 65% is below 70% threshold
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(ProcessVideo(testFile)),
        expect: () => [
          const InterpreterProcessing(),
          isA<InterpreterError>().having(
            (e) => e.message,
            'message',
            contains('confidence: 65.0%'),
          ),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when confidence is exactly at threshold',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Borderline',
            confidence: 0.70, // Exactly 70%
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(ProcessVideo(testFile)),
        expect: () => [
          const InterpreterProcessing(),
          const InterpreterSuccess(text: 'Borderline', confidence: 0.70),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when interpretation times out',
        build: () {
          mockInterpretationService.mockDelay =
              AppConfiguration.interpretationTimeout +
              const Duration(seconds: 1);
          return bloc;
        },
        act: (bloc) => bloc.add(ProcessVideo(testFile)),
        wait:
            AppConfiguration.interpretationTimeout + const Duration(seconds: 2),
        expect: () => [
          const InterpreterProcessing(),
          isA<InterpreterError>().having(
            (e) => e.message,
            'message',
            contains('took too long'),
          ),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterError when interpretation throws exception',
        build: () {
          mockInterpretationService.mockException = Exception(
            'Interpretation failed',
          );
          return bloc;
        },
        act: (bloc) => bloc.add(ProcessVideo(testFile)),
        expect: () => [
          const InterpreterProcessing(),
          const InterpreterError(
            'Failed to interpret the sign language. Please try again.',
          ),
        ],
      );
    });

    group('ResetInterpreter Event', () {
      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterInitial when reset from any state',
        build: () => bloc,
        seed: () => const InterpreterSuccess(text: 'Test', confidence: 0.9),
        act: (bloc) => bloc.add(const ResetInterpreter()),
        expect: () => [const InterpreterInitial()],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit InterpreterInitial when reset from error state',
        build: () => bloc,
        seed: () => const InterpreterError('Some error'),
        act: (bloc) => bloc.add(const ResetInterpreter()),
        expect: () => [const InterpreterInitial()],
      );
    });

    group('Complete Recording and Interpretation Flow', () {
      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should complete full flow: start recording -> stop recording -> process -> success',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Thank you',
            confidence: 0.88,
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const StartRecording());
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const StopRecording());
        },
        expect: () => [
          const InterpreterRecording(),
          const InterpreterProcessing(),
          const InterpreterSuccess(text: 'Thank you', confidence: 0.88),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should handle reset after successful interpretation',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Hello',
            confidence: 0.90,
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const StartRecording());
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(const StopRecording());
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const ResetInterpreter());
        },
        expect: () => [
          const InterpreterRecording(),
          const InterpreterProcessing(),
          const InterpreterSuccess(text: 'Hello', confidence: 0.90),
          const InterpreterInitial(),
        ],
      );
    });

    group('State Transitions', () {
      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should transition from Initial -> Recording -> Processing -> Success',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Test message',
            confidence: 0.92,
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) async {
          expect(bloc.state, const InterpreterInitial());
          bloc.add(const StartRecording());
          await Future.delayed(const Duration(milliseconds: 50));
          expect(bloc.state, const InterpreterRecording());
          bloc.add(const StopRecording());
        },
        expect: () => [
          const InterpreterRecording(),
          const InterpreterProcessing(),
          const InterpreterSuccess(text: 'Test message', confidence: 0.92),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should transition from Success -> Initial on reset',
        build: () => bloc,
        seed: () => const InterpreterSuccess(text: 'Previous', confidence: 0.8),
        act: (bloc) => bloc.add(const ResetInterpreter()),
        expect: () => [const InterpreterInitial()],
        verify: (_) {
          expect(bloc.state, const InterpreterInitial());
        },
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should transition from Error -> Initial on reset',
        build: () => bloc,
        seed: () => const InterpreterError('Error occurred'),
        act: (bloc) => bloc.add(const ResetInterpreter()),
        expect: () => [const InterpreterInitial()],
      );
    });

    group('Low Confidence Error Handling', () {
      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit error with helpful message for low confidence (50%)',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Unclear gesture',
            confidence: 0.50,
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(ProcessVideo(File('test.mp4'))),
        expect: () => [
          const InterpreterProcessing(),
          isA<InterpreterError>()
              .having(
                (e) => e.message,
                'message',
                contains('Could not interpret'),
              )
              .having((e) => e.message, 'message', contains('50.0%'))
              .having((e) => e.message, 'message', contains('record again')),
        ],
      );

      blocTest<SignLanguageInterpreterBloc, SignLanguageInterpreterState>(
        'should emit error for confidence just below threshold (69.9%)',
        build: () {
          mockInterpretationService.mockResult = const InterpretationResult(
            text: 'Almost clear',
            confidence: 0.699,
            language: Language.english,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(ProcessVideo(File('test.mp4'))),
        expect: () => [
          const InterpreterProcessing(),
          isA<InterpreterError>().having(
            (e) => e.message,
            'message',
            contains('69.9%'),
          ),
        ],
      );
    });
  });
}
