import 'package:equatable/equatable.dart';
import '../../../core/utils/enums.dart';

/// Base class for LanguageManager events
abstract class LanguageManagerEvent extends Equatable {
  const LanguageManagerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to select a new language
class SelectLanguage extends LanguageManagerEvent {
  final Language language;

  const SelectLanguage(this.language);

  @override
  List<Object?> get props => [language];
}

/// Event to load the saved language preference
class LoadSavedLanguage extends LanguageManagerEvent {
  const LoadSavedLanguage();
}
