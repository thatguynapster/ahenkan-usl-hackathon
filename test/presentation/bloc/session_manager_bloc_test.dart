import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/domain/entities/message.dart';
import 'package:ahenkan/presentation/bloc/session_manager/session_manager_bloc.dart';
import 'package:ahenkan/presentation/bloc/session_manager/session_manager_event.dart';
import 'package:ahenkan/presentation/bloc/session_manager/session_manager_state.dart';

void main() {
  late SessionManagerBloc bloc;

  setUp(() {
    bloc = SessionManagerBloc();
  });

  tearDown(() async {
    await bloc.close();
  });

  group('SessionManagerBloc', () {
    test('initial state should be SessionActive with empty list', () {
      // Assert
      expect(bloc.state, equals(const SessionActive([])));
    });

    group('AddMessage Event', () {
      final message1 = Message(
        id: '1',
        type: MessageType.signToText,
        content: 'Hello',
        timestamp: DateTime(2024, 1, 1, 10, 0, 0),
        language: Language.english,
      );

      final message2 = Message(
        id: '2',
        type: MessageType.textToSign,
        content: 'How are you?',
        timestamp: DateTime(2024, 1, 1, 10, 1, 0),
        language: Language.english,
        videoPath: '/path/to/video.mp4',
      );

      final message3 = Message(
        id: '3',
        type: MessageType.signToText,
        content: 'I am fine',
        timestamp: DateTime(2024, 1, 1, 10, 2, 0),
        language: Language.akan,
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should emit SessionActive with one message when AddMessage is added',
        build: () => bloc,
        act: (bloc) => bloc.add(AddMessage(message1)),
        expect: () => [
          SessionActive([message1]),
        ],
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should emit SessionActive with multiple messages when AddMessage is added multiple times',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(message1));
          bloc.add(AddMessage(message2));
          bloc.add(AddMessage(message3));
        },
        expect: () => [
          SessionActive([message1]),
          SessionActive([message1, message2]),
          SessionActive([message1, message2, message3]),
        ],
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should maintain chronological order when messages are added',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(message1));
          bloc.add(AddMessage(message2));
          bloc.add(AddMessage(message3));
        },
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages.length, equals(3));
          expect(
            state.messages[0].timestamp.isBefore(state.messages[1].timestamp),
            isTrue,
          );
          expect(
            state.messages[1].timestamp.isBefore(state.messages[2].timestamp),
            isTrue,
          );
        },
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should sort messages chronologically even when added out of order',
        build: () => bloc,
        act: (bloc) {
          // Add messages out of chronological order
          bloc.add(AddMessage(message3)); // 10:02
          bloc.add(AddMessage(message1)); // 10:00
          bloc.add(AddMessage(message2)); // 10:01
        },
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages.length, equals(3));
          // Verify they are sorted by timestamp
          expect(state.messages[0].id, equals('1')); // 10:00
          expect(state.messages[1].id, equals('2')); // 10:01
          expect(state.messages[2].id, equals('3')); // 10:02
        },
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should add message with video path for text-to-sign messages',
        build: () => bloc,
        act: (bloc) => bloc.add(AddMessage(message2)),
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages.length, equals(1));
          expect(state.messages[0].videoPath, equals('/path/to/video.mp4'));
          expect(state.messages[0].type, equals(MessageType.textToSign));
        },
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should add message with different languages',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(message1)); // English
          bloc.add(AddMessage(message3)); // Akan
        },
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages.length, equals(2));
          expect(state.messages[0].language, equals(Language.english));
          expect(state.messages[1].language, equals(Language.akan));
        },
      );
    });

    group('ClearSession Event', () {
      final message1 = Message(
        id: '1',
        type: MessageType.signToText,
        content: 'Hello',
        timestamp: DateTime(2024, 1, 1, 10, 0, 0),
        language: Language.english,
      );

      final message2 = Message(
        id: '2',
        type: MessageType.textToSign,
        content: 'How are you?',
        timestamp: DateTime(2024, 1, 1, 10, 1, 0),
        language: Language.english,
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should emit SessionCleared when ClearSession is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const ClearSession()),
        expect: () => [const SessionCleared()],
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should clear all messages when ClearSession is added',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(message1));
          bloc.add(AddMessage(message2));
          bloc.add(const ClearSession());
        },
        expect: () => [
          SessionActive([message1]),
          SessionActive([message1, message2]),
          const SessionCleared(),
        ],
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should allow adding messages after clearing session',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(message1));
          bloc.add(const ClearSession());
          bloc.add(AddMessage(message2));
        },
        expect: () => [
          SessionActive([message1]),
          const SessionCleared(),
          SessionActive([message2]),
        ],
      );
    });

    group('GetHistory Event', () {
      final message1 = Message(
        id: '1',
        type: MessageType.signToText,
        content: 'Hello',
        timestamp: DateTime(2024, 1, 1, 10, 0, 0),
        language: Language.english,
      );

      final message2 = Message(
        id: '2',
        type: MessageType.textToSign,
        content: 'How are you?',
        timestamp: DateTime(2024, 1, 1, 10, 1, 0),
        language: Language.english,
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should emit SessionActive with empty list when GetHistory is added with no messages',
        build: () => bloc,
        act: (bloc) => bloc.add(const GetHistory()),
        expect: () => [const SessionActive([])],
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should emit SessionActive with current messages when GetHistory is added',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(message1));
          bloc.add(AddMessage(message2));
          bloc.add(const GetHistory());
        },
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages.length, equals(2));
          expect(state.messages[0].id, equals('1'));
          expect(state.messages[1].id, equals('2'));
        },
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should return empty history after clearing session',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(message1));
          bloc.add(const ClearSession());
          bloc.add(const GetHistory());
        },
        expect: () => [
          SessionActive([message1]),
          const SessionCleared(),
          const SessionActive([]),
        ],
      );
    });

    group('Chronological Ordering', () {
      final earlyMessage = Message(
        id: '1',
        type: MessageType.signToText,
        content: 'First message',
        timestamp: DateTime(2024, 1, 1, 9, 0, 0),
        language: Language.english,
      );

      final middleMessage = Message(
        id: '2',
        type: MessageType.textToSign,
        content: 'Second message',
        timestamp: DateTime(2024, 1, 1, 10, 0, 0),
        language: Language.english,
      );

      final lateMessage = Message(
        id: '3',
        type: MessageType.signToText,
        content: 'Third message',
        timestamp: DateTime(2024, 1, 1, 11, 0, 0),
        language: Language.english,
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should maintain chronological order when messages added in order',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(earlyMessage));
          bloc.add(AddMessage(middleMessage));
          bloc.add(AddMessage(lateMessage));
        },
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages[0].id, equals('1'));
          expect(state.messages[1].id, equals('2'));
          expect(state.messages[2].id, equals('3'));
        },
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should sort messages chronologically when added in reverse order',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(lateMessage));
          bloc.add(AddMessage(middleMessage));
          bloc.add(AddMessage(earlyMessage));
        },
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages[0].id, equals('1')); // Earliest
          expect(state.messages[1].id, equals('2')); // Middle
          expect(state.messages[2].id, equals('3')); // Latest
        },
      );

      blocTest<SessionManagerBloc, SessionManagerState>(
        'should sort messages chronologically when added in random order',
        build: () => bloc,
        act: (bloc) {
          bloc.add(AddMessage(middleMessage));
          bloc.add(AddMessage(lateMessage));
          bloc.add(AddMessage(earlyMessage));
        },
        verify: (bloc) {
          final state = bloc.state as SessionActive;
          expect(state.messages[0].id, equals('1')); // Earliest
          expect(state.messages[1].id, equals('2')); // Middle
          expect(state.messages[2].id, equals('3')); // Latest
        },
      );
    });

    group('Message Timestamps', () {
      test('should preserve message timestamps when added', () async {
        final timestamp = DateTime(2024, 1, 1, 12, 30, 45);
        final message = Message(
          id: '1',
          type: MessageType.signToText,
          content: 'Test message',
          timestamp: timestamp,
          language: Language.english,
        );

        bloc.add(AddMessage(message));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as SessionActive;
        expect(state.messages[0].timestamp, equals(timestamp));
      });

      test('should handle messages with same timestamp', () async {
        final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
        final message1 = Message(
          id: '1',
          type: MessageType.signToText,
          content: 'First',
          timestamp: timestamp,
          language: Language.english,
        );
        final message2 = Message(
          id: '2',
          type: MessageType.textToSign,
          content: 'Second',
          timestamp: timestamp,
          language: Language.english,
        );

        bloc.add(AddMessage(message1));
        bloc.add(AddMessage(message2));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as SessionActive;
        expect(state.messages.length, equals(2));
        expect(state.messages[0].timestamp, equals(timestamp));
        expect(state.messages[1].timestamp, equals(timestamp));
      });
    });
  });
}
