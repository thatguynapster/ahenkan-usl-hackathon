import 'package:equatable/equatable.dart';

/// Base class for TextToSignGenerator states
abstract class TextToSignGeneratorState extends Equatable {
  const TextToSignGeneratorState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any generation
class GeneratorInitial extends TextToSignGeneratorState {
  const GeneratorInitial();
}

/// State when video generation is in progress
class GeneratorProcessing extends TextToSignGeneratorState {
  const GeneratorProcessing();
}

/// State when video generation is successful
class GeneratorSuccess extends TextToSignGeneratorState {
  final String videoPath;

  const GeneratorSuccess({required this.videoPath});

  @override
  List<Object?> get props => [videoPath];
}

/// State when an error occurs during generation
class GeneratorError extends TextToSignGeneratorState {
  final String message;

  const GeneratorError(this.message);

  @override
  List<Object?> get props => [message];
}
