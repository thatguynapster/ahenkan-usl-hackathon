import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_bloc.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_event.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_state.dart';
import 'package:ahenkan/presentation/widgets/language_selector_widget.dart';

class MockLanguageManagerBloc
    extends MockBloc<LanguageManagerEvent, LanguageManagerState>
    implements LanguageManagerBloc {}

void main() {
  late MockLanguageManagerBloc mockBloc;

  setUp(() {
    mockBloc = MockLanguageManagerBloc();
  });

  Widget createWidgetUnderTest(LanguageManagerState initialState) {
    whenListen(
      mockBloc,
      Stream<LanguageManagerState>.fromIterable([initialState]),
      initialState: initialState,
    );

    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<LanguageManagerBloc>(
          create: (_) => mockBloc,
          child: const LanguageSelectorWidget(),
        ),
      ),
    );
  }

  group('LanguageSelectorWidget', () {
    testWidgets('displays dropdown with current language', (tester) async {
      // Arrange
      const initialState = LanguageSelected(Language.english);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(initialState));

      // Assert
      expect(find.byType(DropdownButton<Language>), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('displays all language options when dropdown is opened', (
      tester,
    ) async {
      // Arrange
      const initialState = LanguageSelected(Language.english);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(initialState));
      await tester.tap(find.byType(DropdownButton<Language>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('English'), findsWidgets);
      expect(find.text('Akan'), findsOneWidget);
      expect(find.text('Ga'), findsOneWidget);
      expect(find.text('Ewe'), findsOneWidget);
    });

    testWidgets('displays checkmark for selected language', (tester) async {
      // Arrange
      const initialState = LanguageSelected(Language.akan);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(initialState));
      await tester.tap(find.byType(DropdownButton<Language>));
      await tester.pumpAndSettle();

      // Assert - checkmark should be visible for Akan
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
