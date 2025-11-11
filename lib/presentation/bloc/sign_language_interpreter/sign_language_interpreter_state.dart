import 'package:equatable/equatable.dart';

/// Base class for SignLanguageInterpreter states
abstract class SignLanguageInterpreterState extends Equatable {
  const SignLanguageInterpreterState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any recording or interpretation
class InterpreterInitial extends SignLanguageInterpreterState {
  const InterpreterInitial();
}

/// State when video recording is in progress
class InterpreterRecording extends SignLanguageInterpreterState {
  const InterpreterRecording();
}

/// State when video is being processed for interpretation
class InterpreterProcessing extends SignLanguageInterpreterState {
  const InterpreterProcessing();
}

/// State when interpretation is successful
class InterpreterSuccess extends SignLanguageInterpreterState {
  final String text;
  final double confidence;

  const InterpreterSuccess({required this.text, required this.confidence});

  @override
  List<Object?> get props => [text, confidence];
}

/// State when an error occurs during recording or interpretation
class InterpreterError extends SignLanguageInterpreterState {
  final String message;

  const InterpreterError(this.message);

  @override
  List<Object?> get props => [message];
}
