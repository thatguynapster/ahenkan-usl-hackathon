import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/enums.dart';
import '../bloc/language_manager/language_manager_bloc.dart';
import '../bloc/language_manager/language_manager_event.dart';
import '../bloc/language_manager/language_manager_state.dart';

/// A dropdown widget for selecting the application language
///
/// This widget displays a dropdown menu with all available languages
/// and connects to the LanguageManagerBloc to persist the selection.
class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageManagerBloc, LanguageManagerState>(
      builder: (context, state) {
        final currentLanguage = state is LanguageSelected
            ? state.language
            : Language.english;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Language>(
              value: currentLanguage,
              icon: const Icon(Icons.arrow_drop_down),
              elevation: 16,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16.0,
              ),
              onChanged: (Language? newLanguage) {
                if (newLanguage != null) {
                  context.read<LanguageManagerBloc>().add(
                    SelectLanguage(newLanguage),
                  );
                }
              },
              selectedItemBuilder: (BuildContext context) {
                return Language.values.map<Widget>((Language language) {
                  return Container(
                    alignment: Alignment.center,
                    child: Text(
                      language.displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16.0,
                      ),
                    ),
                  );
                }).toList();
              },
              items: Language.values.map<DropdownMenuItem<Language>>((
                Language language,
              ) {
                final isSelected = language == currentLanguage;

                return DropdownMenuItem<Language>(
                  value: language,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language.displayName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8.0),
                        Icon(
                          Icons.check,
                          size: 20.0,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
