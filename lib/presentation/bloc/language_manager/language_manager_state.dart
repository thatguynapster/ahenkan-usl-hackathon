import 'package:equatable/equatable.dart';
import '../../../core/utils/enums.dart';

/// Base class for LanguageManager states
abstract class LanguageManagerState extends Equatable {
  const LanguageManagerState();

  @override
  List<Object?> get props => [];
}

/// State representing a selected language
class LanguageSelected extends LanguageManagerState {
  final Language language;

  const LanguageSelected(this.language);

  @override
  List<Object?> get props => [language];
}
