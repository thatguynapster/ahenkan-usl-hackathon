import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/enums.dart';
import '../../../domain/repositories/storage_repository.dart';
import 'language_manager_event.dart';
import 'language_manager_state.dart';

/// BLoC for managing language selection and persistence
class LanguageManagerBloc
    extends Bloc<LanguageManagerEvent, LanguageManagerState> {
  final StorageRepository _storageRepository;

  LanguageManagerBloc({required StorageRepository storageRepository})
    : _storageRepository = storageRepository,
      super(const LanguageSelected(Language.english)) {
    on<SelectLanguage>(_onSelectLanguage);
    on<LoadSavedLanguage>(_onLoadSavedLanguage);
  }

  /// Handles the SelectLanguage event
  Future<void> _onSelectLanguage(
    SelectLanguage event,
    Emitter<LanguageManagerState> emit,
  ) async {
    // Save the language preference
    await _storageRepository.saveLanguagePreference(event.language);

    // Emit the new language state
    emit(LanguageSelected(event.language));
  }

  /// Handles the LoadSavedLanguage event
  Future<void> _onLoadSavedLanguage(
    LoadSavedLanguage event,
    Emitter<LanguageManagerState> emit,
  ) async {
    // Retrieve the saved language preference
    final (language, error) = await _storageRepository.getLanguagePreference();

    // If a language was found, emit it; otherwise, keep the default (English)
    if (language != null && error == null) {
      emit(LanguageSelected(language));
    }
    // If there's no saved language, the default state (English) remains
  }
}
