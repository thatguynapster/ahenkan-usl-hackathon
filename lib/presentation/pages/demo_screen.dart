import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection_container.dart';
import '../../core/utils/enums.dart';
import '../bloc/language_manager/language_manager_bloc.dart';
import '../bloc/language_manager/language_manager_event.dart';
import '../bloc/language_manager/language_manager_state.dart';
import '../widgets/language_selector_widget.dart';

/// Demo screen to showcase the LanguageSelectorWidget
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<LanguageManagerBloc>()..add(const LoadSavedLanguage()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ahenkan'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              const LanguageSelectorWidget(),
              const SizedBox(height: 32.0),
              BlocBuilder<LanguageManagerBloc, LanguageManagerState>(
                builder: (context, state) {
                  if (state is LanguageSelected) {
                    return Card(
                      elevation: 2.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Language:',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              state.language.displayName,
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Language Code: ${state.language.code}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
