import 'dart:io';
import 'package:equatable/equatable.dart';

/// Base class for SignLanguageInterpreter events
abstract class SignLanguageInterpreterEvent extends Equatable {
  const SignLanguageInterpreterEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start recording sign language video
class StartRecording extends SignLanguageInterpreterEvent {
  const StartRecording();
}

/// Event to stop recording sign language video
class StopRecording extends SignLanguageInterpreterEvent {
  const StopRecording();
}

/// Event to process a recorded video file for interpretation
class ProcessVideo extends SignLanguageInterpreterEvent {
  final File videoFile;

  const ProcessVideo(this.videoFile);

  @override
  List<Object?> get props => [videoFile];
}

/// Event to reset the interpreter to initial state
class ResetInterpreter extends SignLanguageInterpreterEvent {
  const ResetInterpreter();
}
