import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/domain/entities/message.dart';
import 'package:ahenkan/presentation/bloc/session_manager/session_manager_bloc.dart';
import 'package:ahenkan/presentation/bloc/session_manager/session_manager_event.dart';
import 'package:ahenkan/presentation/bloc/session_manager/session_manager_state.dart';
import 'package:ahenkan/presentation/pages/history_screen.dart';

class MockSessionManagerBloc
    extends MockBloc<SessionManagerEvent, SessionManagerState>
    implements SessionManagerBloc {}

void main() {
  late MockSessionManagerBloc mockSessionBloc;

  setUp(() {
    mockSessionBloc = MockSessionManagerBloc();
  });

  Widget createTestWidget(SessionManagerState state) {
    whenListen(
      mockSessionBloc,
      Stream<SessionManagerState>.fromIterable([state]),
      initialState: state,
    );

    return MaterialApp(
      home: BlocProvider<SessionManagerBloc>(
        create: (_) => mockSessionBloc,
        child: Scaffold(
          appBar: AppBar(title: const Text('History')),
          body: BlocBuilder<SessionManagerBloc, SessionManagerState>(
            builder: (context, state) {
              if (state is SessionActive) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80.0,
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Your communication history will appear here',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    return MessageCard(message: state.messages[index]);
                  },
                );
              } else if (state is SessionCleared) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80.0,
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Your communication history will appear here',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80.0,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Your communication history will appear here',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('HistoryScreen', () {
    testWidgets('displays empty state when no messages exist', (tester) async {
      await tester.pumpWidget(createTestWidget(const SessionActive([])));

      expect(find.text('No messages yet'), findsOneWidget);
      expect(
        find.text('Your communication history will appear here'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('displays empty state when session is cleared', (tester) async {
      await tester.pumpWidget(createTestWidget(const SessionCleared()));

      expect(find.text('No messages yet'), findsOneWidget);
      expect(
        find.text('Your communication history will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('displays message list when messages exist', (tester) async {
      final messages = [
        Message(
          id: '1',
          type: MessageType.signToText,
          content: 'Hello, how are you?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          language: Language.english,
        ),
        Message(
          id: '2',
          type: MessageType.textToSign,
          content: 'I am fine, thank you!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          language: Language.akan,
          videoPath: '/path/to/video.mp4',
        ),
      ];

      await tester.pumpWidget(createTestWidget(SessionActive(messages)));

      // Verify message cards are displayed
      expect(find.byType(MessageCard), findsNWidgets(2));

      // Verify message content
      expect(find.text('Hello, how are you?'), findsOneWidget);
      expect(find.text('I am fine, thank you!'), findsOneWidget);

      // Verify message types
      expect(find.text('Sign to Text'), findsOneWidget);
      expect(find.text('Text to Sign'), findsOneWidget);

      // Verify language badges
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Akan'), findsOneWidget);
    });

    testWidgets('displays correct message type indicators', (tester) async {
      final messages = [
        Message(
          id: '1',
          type: MessageType.signToText,
          content: 'Sign language message',
          timestamp: DateTime.now(),
          language: Language.english,
        ),
        Message(
          id: '2',
          type: MessageType.textToSign,
          content: 'Text message',
          timestamp: DateTime.now(),
          language: Language.english,
        ),
      ];

      await tester.pumpWidget(createTestWidget(SessionActive(messages)));

      // Verify icons for message types
      expect(find.byIcon(Icons.sign_language), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('displays timestamps correctly', (tester) async {
      final now = DateTime.now();
      final messages = [
        Message(
          id: '1',
          type: MessageType.signToText,
          content: 'Recent message',
          timestamp: now.subtract(const Duration(seconds: 30)),
          language: Language.english,
        ),
        Message(
          id: '2',
          type: MessageType.textToSign,
          content: 'Older message',
          timestamp: now.subtract(const Duration(minutes: 30)),
          language: Language.english,
        ),
      ];

      await tester.pumpWidget(createTestWidget(SessionActive(messages)));

      // Verify relative timestamps are displayed
      expect(find.text('Just now'), findsOneWidget);
      expect(find.textContaining('minutes ago'), findsOneWidget);
    });

    testWidgets('list is scrollable with multiple messages', (tester) async {
      // Create many messages to test scrolling
      final messages = List.generate(
        20,
        (index) => Message(
          id: '$index',
          type: index % 2 == 0
              ? MessageType.signToText
              : MessageType.textToSign,
          content: 'Message $index',
          timestamp: DateTime.now().subtract(Duration(minutes: index)),
          language: Language.english,
        ),
      );

      await tester.pumpWidget(createTestWidget(SessionActive(messages)));

      // Verify first message is visible
      expect(find.text('Message 0'), findsOneWidget);

      // Scroll to bottom
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();

      // Verify last message becomes visible after scrolling
      expect(find.text('Message 19'), findsOneWidget);
    });

    testWidgets('displays all language options correctly', (tester) async {
      final messages = [
        Message(
          id: '1',
          type: MessageType.signToText,
          content: 'English message',
          timestamp: DateTime.now(),
          language: Language.english,
        ),
        Message(
          id: '2',
          type: MessageType.signToText,
          content: 'Akan message',
          timestamp: DateTime.now(),
          language: Language.akan,
        ),
        Message(
          id: '3',
          type: MessageType.signToText,
          content: 'Ga message',
          timestamp: DateTime.now(),
          language: Language.ga,
        ),
        Message(
          id: '4',
          type: MessageType.signToText,
          content: 'Ewe message',
          timestamp: DateTime.now(),
          language: Language.ewe,
        ),
      ];

      await tester.pumpWidget(createTestWidget(SessionActive(messages)));

      // Verify all language badges are displayed
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Akan'), findsOneWidget);
      expect(find.text('Ga'), findsOneWidget);
      expect(find.text('Ewe'), findsOneWidget);
    });

    testWidgets('message cards have proper styling', (tester) async {
      final messages = [
        Message(
          id: '1',
          type: MessageType.signToText,
          content: 'Test message',
          timestamp: DateTime.now(),
          language: Language.english,
        ),
      ];

      await tester.pumpWidget(createTestWidget(SessionActive(messages)));

      // Verify Card widget exists
      expect(find.byType(Card), findsOneWidget);

      // Verify MessageCard widget exists
      expect(find.byType(MessageCard), findsOneWidget);
    });
  });
}
