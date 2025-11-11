import 'package:equatable/equatable.dart';

/// Base class for TextToSignGenerator events
abstract class TextToSignGeneratorEvent extends Equatable {
  const TextToSignGeneratorEvent();

  @override
  List<Object?> get props => [];
}

/// Event to generate sign language video from text input
class GenerateFromText extends TextToSignGeneratorEvent {
  final String text;

  const GenerateFromText(this.text);

  @override
  List<Object?> get props => [text];
}

/// Event to generate sign language video from speech input
class GenerateFromSpeech extends TextToSignGeneratorEvent {
  const GenerateFromSpeech();
}

/// Event to replay the generated video
class ReplayVideo extends TextToSignGeneratorEvent {
  const ReplayVideo();
}

/// Event to clear the current generation and reset to initial state
class ClearGeneration extends TextToSignGeneratorEvent {
  const ClearGeneration();
}
