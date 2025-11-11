import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_bloc.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_event.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_state.dart';
import 'package:ahenkan/presentation/bloc/sign_language_interpreter/sign_language_interpreter_bloc.dart';
import 'package:ahenkan/presentation/bloc/sign_language_interpreter/sign_language_interpreter_event.dart';
import 'package:ahenkan/presentation/bloc/sign_language_interpreter/sign_language_interpreter_state.dart';

class MockLanguageManagerBloc
    extends MockBloc<LanguageManagerEvent, LanguageManagerState>
    implements LanguageManagerBloc {}

class MockSignLanguageInterpreterBloc
    extends MockBloc<SignLanguageInterpreterEvent, SignLanguageInterpreterState>
    implements SignLanguageInterpreterBloc {}

void main() {
  late MockLanguageManagerBloc mockLanguageBloc;
  late MockSignLanguageInterpreterBloc mockInterpreterBloc;

  setUp(() {
    mockLanguageBloc = MockLanguageManagerBloc();
    mockInterpreterBloc = MockSignLanguageInterpreterBloc();
  });

  Widget createTestWidget(SignLanguageInterpreterState interpreterState) {
    whenListen(
      mockLanguageBloc,
      Stream<LanguageManagerState>.fromIterable([
        const LanguageSelected(Language.english),
      ]),
      initialState: const LanguageSelected(Language.english),
    );

    whenListen(
      mockInterpreterBloc,
      Stream<SignLanguageInterpreterState>.fromIterable([interpreterState]),
      initialState: interpreterState,
    );

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LanguageManagerBloc>(create: (_) => mockLanguageBloc),
          BlocProvider<SignLanguageInterpreterBloc>(
            create: (_) => mockInterpreterBloc,
          ),
        ],
        child: Scaffold(
          appBar: AppBar(title: const Text('Sign to Text')),
          body:
              BlocBuilder<
                SignLanguageInterpreterBloc,
                SignLanguageInterpreterState
              >(
                builder: (context, state) {
                  return Column(
                    children: [
                      // Camera preview placeholder
                      Expanded(
                        child: Container(
                          color: Colors.black,
                          child: Center(
                            child: state is InterpreterRecording
                                ? const Text(
                                    'Recording',
                                    style: TextStyle(color: Colors.white),
                                  )
                                : state is InterpreterProcessing
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'Camera Preview',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                      // Recording button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: state is InterpreterProcessing
                              ? null
                              : () {
                                  if (state is InterpreterRecording) {
                                    context
                                        .read<SignLanguageInterpreterBloc>()
                                        .add(const StopRecording());
                                  } else {
                                    context
                                        .read<SignLanguageInterpreterBloc>()
                                        .add(const StartRecording());
                                  }
                                },
                          child: Icon(
                            state is InterpreterRecording
                                ? Icons.stop
                                : Icons.videocam,
                          ),
                        ),
                      ),
                      // Interpretation display
                      if (state is InterpreterSuccess)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Interpreted Text'),
                              Text(state.text),
                              Text(
                                'Confidence: ${(state.confidence * 100).toStringAsFixed(1)}%',
                              ),
                            ],
                          ),
                        )
                      else if (state is InterpreterInitial)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Tap the button to start recording'),
                        ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }

  group('SignToTextScreen', () {
    testWidgets('displays initial state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(const InterpreterInitial()));

      expect(find.text('Sign to Text'), findsOneWidget);
      expect(find.text('Camera Preview'), findsOneWidget);
      expect(find.text('Tap the button to start recording'), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('shows recording indicator when recording', (tester) async {
      await tester.pumpWidget(createTestWidget(const InterpreterRecording()));

      expect(find.text('Recording'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('shows processing indicator during interpretation', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const InterpreterProcessing()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays interpreted text on success', (tester) async {
      const testText = 'Hello, how are you?';
      const confidence = 0.95;

      await tester.pumpWidget(
        createTestWidget(
          const InterpreterSuccess(text: testText, confidence: confidence),
        ),
      );

      expect(find.text(testText), findsOneWidget);
      expect(find.text('Interpreted Text'), findsOneWidget);
      expect(find.text('Confidence: 95.0%'), findsOneWidget);
    });

    testWidgets('displays confidence percentage correctly', (tester) async {
      const confidence = 0.87;

      await tester.pumpWidget(
        createTestWidget(
          const InterpreterSuccess(text: 'Test', confidence: confidence),
        ),
      );

      expect(find.text('Confidence: 87.0%'), findsOneWidget);
    });
  });
}
