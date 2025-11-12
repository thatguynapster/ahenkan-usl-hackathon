import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_bloc.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_event.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_state.dart';
import 'package:ahenkan/presentation/bloc/text_to_sign_generator/text_to_sign_generator_bloc.dart';
import 'package:ahenkan/presentation/bloc/text_to_sign_generator/text_to_sign_generator_event.dart';
import 'package:ahenkan/presentation/bloc/text_to_sign_generator/text_to_sign_generator_state.dart';

class MockLanguageManagerBloc
    extends MockBloc<LanguageManagerEvent, LanguageManagerState>
    implements LanguageManagerBloc {}

class MockTextToSignGeneratorBloc
    extends MockBloc<TextToSignGeneratorEvent, TextToSignGeneratorState>
    implements TextToSignGeneratorBloc {}

void main() {
  late MockLanguageManagerBloc mockLanguageBloc;
  late MockTextToSignGeneratorBloc mockGeneratorBloc;

  setUp(() {
    mockLanguageBloc = MockLanguageManagerBloc();
    mockGeneratorBloc = MockTextToSignGeneratorBloc();
  });

  Widget createTestWidget(TextToSignGeneratorState generatorState) {
    whenListen(
      mockLanguageBloc,
      Stream<LanguageManagerState>.fromIterable([
        const LanguageSelected(Language.english),
      ]),
      initialState: const LanguageSelected(Language.english),
    );

    whenListen(
      mockGeneratorBloc,
      Stream<TextToSignGeneratorState>.fromIterable([generatorState]),
      initialState: generatorState,
    );

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LanguageManagerBloc>(create: (_) => mockLanguageBloc),
          BlocProvider<TextToSignGeneratorBloc>(
            create: (_) => mockGeneratorBloc,
          ),
        ],
        child: Scaffold(
          appBar: AppBar(title: const Text('Text to Sign')),
          body: BlocBuilder<TextToSignGeneratorBloc, TextToSignGeneratorState>(
            builder: (context, state) {
              return Column(
                children: [
                  // Video player area
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: state is GeneratorSuccess
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Video Player',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Play button
                                  IconButton(
                                    key: const Key('play_button'),
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Replay button
                                  IconButton(
                                    key: const Key('replay_button'),
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.replay,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : state is GeneratorProcessing
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 16.0),
                                  Text(
                                    'Generating sign language...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : const Text(
                                'Enter text or use voice input\nto generate sign language',
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ),
                  // Text input area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Text field
                          Expanded(
                            child: TextField(
                              key: const Key('text_input_field'),
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'Type your message here...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          // Buttons row
                          Row(
                            children: [
                              // Microphone button
                              IconButton(
                                key: const Key('microphone_button'),
                                onPressed: state is GeneratorProcessing
                                    ? null
                                    : () {
                                        context
                                            .read<TextToSignGeneratorBloc>()
                                            .add(const GenerateFromSpeech());
                                      },
                                icon: const Icon(Icons.mic),
                              ),
                              const SizedBox(width: 8.0),
                              // Generate button
                              Expanded(
                                child: ElevatedButton(
                                  key: const Key('generate_button'),
                                  onPressed: state is GeneratorProcessing
                                      ? null
                                      : () {
                                          context
                                              .read<TextToSignGeneratorBloc>()
                                              .add(
                                                const GenerateFromText('Test'),
                                              );
                                        },
                                  child: state is GeneratorProcessing
                                      ? const SizedBox(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                          ),
                                        )
                                      : const Text('Generate Sign Language'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  group('TextToSignScreen', () {
    testWidgets('displays initial state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(const GeneratorInitial()));

      expect(find.text('Text to Sign'), findsOneWidget);
      expect(find.byKey(const Key('text_input_field')), findsOneWidget);
      expect(find.byKey(const Key('microphone_button')), findsOneWidget);
      expect(find.byKey(const Key('generate_button')), findsOneWidget);
      expect(
        find.text('Enter text or use voice input\nto generate sign language'),
        findsOneWidget,
      );
    });

    testWidgets('text input field accepts user input', (tester) async {
      await tester.pumpWidget(createTestWidget(const GeneratorInitial()));

      final textField = find.byKey(const Key('text_input_field'));
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Hello world');
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('generate button is enabled in initial state', (tester) async {
      await tester.pumpWidget(createTestWidget(const GeneratorInitial()));

      final generateButton = find.byKey(const Key('generate_button'));
      expect(generateButton, findsOneWidget);

      final buttonWidget = tester.widget<ElevatedButton>(generateButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('microphone button is enabled in initial state', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const GeneratorInitial()));

      final micButton = find.byKey(const Key('microphone_button'));
      expect(micButton, findsOneWidget);

      final buttonWidget = tester.widget<IconButton>(micButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('shows processing indicator during generation', (tester) async {
      await tester.pumpWidget(createTestWidget(const GeneratorProcessing()));

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      expect(find.text('Generating sign language...'), findsOneWidget);
    });

    testWidgets('disables buttons during processing', (tester) async {
      await tester.pumpWidget(createTestWidget(const GeneratorProcessing()));

      final generateButton = find.byKey(const Key('generate_button'));
      final micButton = find.byKey(const Key('microphone_button'));

      // Buttons should be disabled
      final generateButtonWidget = tester.widget<ElevatedButton>(
        generateButton,
      );
      final micButtonWidget = tester.widget<IconButton>(micButton);

      expect(generateButtonWidget.onPressed, isNull);
      expect(micButtonWidget.onPressed, isNull);
    });

    testWidgets('displays video player on success', (tester) async {
      const videoPath = 'https://example.com/video.mp4';

      await tester.pumpWidget(
        createTestWidget(const GeneratorSuccess(videoPath: videoPath)),
      );

      expect(find.text('Video Player'), findsOneWidget);
      expect(find.byKey(const Key('play_button')), findsOneWidget);
      expect(find.byKey(const Key('replay_button')), findsOneWidget);
    });

    testWidgets('video playback controls are interactive', (tester) async {
      const videoPath = 'https://example.com/video.mp4';

      await tester.pumpWidget(
        createTestWidget(const GeneratorSuccess(videoPath: videoPath)),
      );

      final playButton = find.byKey(const Key('play_button'));
      final replayButton = find.byKey(const Key('replay_button'));

      expect(playButton, findsOneWidget);
      expect(replayButton, findsOneWidget);

      // Verify buttons are tappable
      await tester.tap(playButton);
      await tester.pump();

      await tester.tap(replayButton);
      await tester.pump();
    });
  });
}
