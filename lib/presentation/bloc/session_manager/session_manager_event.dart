import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

/// Base class for SessionManager events
abstract class SessionManagerEvent extends Equatable {
  const SessionManagerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to add a message to the session history
class AddMessage extends SessionManagerEvent {
  final Message message;

  const AddMessage(this.message);

  @override
  List<Object?> get props => [message];
}

/// Event to clear the session history
class ClearSession extends SessionManagerEvent {
  const ClearSession();
}

/// Event to get the session history
class GetHistory extends SessionManagerEvent {
  const GetHistory();
}
