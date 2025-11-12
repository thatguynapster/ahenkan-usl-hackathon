import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/message.dart';
import 'session_manager_event.dart';
import 'session_manager_state.dart';

/// BLoC for managing session history and message storage
/// Maintains in-memory storage of communication exchanges during the active session
class SessionManagerBloc
    extends Bloc<SessionManagerEvent, SessionManagerState> {
  // In-memory storage for session messages
  final List<Message> _messages = [];

  SessionManagerBloc() : super(const SessionActive([])) {
    on<AddMessage>(_onAddMessage);
    on<ClearSession>(_onClearSession);
    on<GetHistory>(_onGetHistory);
  }

  /// Handles the AddMessage event
  /// Adds a new message to the session history with timestamp
  Future<void> _onAddMessage(
    AddMessage event,
    Emitter<SessionManagerState> emit,
  ) async {
    // Add the message to the in-memory list
    _messages.add(event.message);

    // Sort messages chronologically by timestamp
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Emit the updated session state with all messages
    emit(SessionActive(List.unmodifiable(_messages)));
  }

  /// Handles the ClearSession event
  /// Clears all messages from the session history
  Future<void> _onClearSession(
    ClearSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    // Clear the in-memory message list
    _messages.clear();

    // Emit the cleared session state
    emit(const SessionCleared());
  }

  /// Handles the GetHistory event
  /// Returns the current session history
  Future<void> _onGetHistory(
    GetHistory event,
    Emitter<SessionManagerState> emit,
  ) async {
    // Emit the current session state with all messages
    emit(SessionActive(List.unmodifiable(_messages)));
  }
}
