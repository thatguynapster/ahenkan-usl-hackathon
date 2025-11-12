import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

/// Base class for SessionManager states
abstract class SessionManagerState extends Equatable {
  const SessionManagerState();

  @override
  List<Object?> get props => [];
}

/// State representing an active session with message history
class SessionActive extends SessionManagerState {
  final List<Message> messages;

  const SessionActive(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// State representing a cleared session
class SessionCleared extends SessionManagerState {
  const SessionCleared();
}
