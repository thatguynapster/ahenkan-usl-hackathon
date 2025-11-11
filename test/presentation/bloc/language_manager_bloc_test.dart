import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/data/repositories/storage_repository_impl.dart';
import 'package:ahenkan/domain/repositories/storage_repository.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_bloc.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_event.dart';
import 'package:ahenkan/presentation/bloc/language_manager/language_manager_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LanguageManagerBloc bloc;
  late StorageRepository storageRepository;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    storageRepository = StorageRepositoryImpl(sharedPreferences);
    bloc = LanguageManagerBloc(storageRepository: storageRepository);
  });

  tearDown(() async {
    await bloc.close();
    await sharedPreferences.clear();
  });

  group('LanguageManagerBloc', () {
    test('initial state should be LanguageSelected with English', () {
      // Assert
      expect(bloc.state, equals(const LanguageSelected(Language.english)));
    });

    group('SelectLanguage Event', () {
      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should emit LanguageSelected with Akan when SelectLanguage(Akan) is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectLanguage(Language.akan)),
        expect: () => [const LanguageSelected(Language.akan)],
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should emit LanguageSelected with Ga when SelectLanguage(Ga) is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectLanguage(Language.ga)),
        expect: () => [const LanguageSelected(Language.ga)],
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should emit LanguageSelected with Ewe when SelectLanguage(Ewe) is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectLanguage(Language.ewe)),
        expect: () => [const LanguageSelected(Language.ewe)],
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should persist language preference when SelectLanguage is added',
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectLanguage(Language.akan)),
        verify: (_) async {
          final (language, error) = await storageRepository
              .getLanguagePreference();
          expect(error, isNull);
          expect(language, equals(Language.akan));
        },
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should emit multiple language changes in sequence',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const SelectLanguage(Language.akan));
          bloc.add(const SelectLanguage(Language.ga));
          bloc.add(const SelectLanguage(Language.ewe));
        },
        expect: () => [
          const LanguageSelected(Language.akan),
          const LanguageSelected(Language.ga),
          const LanguageSelected(Language.ewe),
        ],
      );
    });

    group('LoadSavedLanguage Event', () {
      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should emit LanguageSelected with saved language when LoadSavedLanguage is added',
        build: () {
          // Pre-save a language preference
          storageRepository.saveLanguagePreference(Language.ga);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedLanguage()),
        expect: () => [const LanguageSelected(Language.ga)],
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should keep default English when no saved language exists',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadSavedLanguage()),
        expect: () => [],
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should load Akan when it was previously saved',
        build: () {
          storageRepository.saveLanguagePreference(Language.akan);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedLanguage()),
        expect: () => [const LanguageSelected(Language.akan)],
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should load Ewe when it was previously saved',
        build: () {
          storageRepository.saveLanguagePreference(Language.ewe);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSavedLanguage()),
        expect: () => [const LanguageSelected(Language.ewe)],
      );
    });

    group('Language Persistence Flow', () {
      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should persist and load language across bloc instances',
        build: () => bloc,
        act: (bloc) async {
          // Select and save a language
          bloc.add(const SelectLanguage(Language.ga));
          await Future.delayed(const Duration(milliseconds: 100));
        },
        verify: (_) async {
          // Create a new bloc instance
          final newBloc = LanguageManagerBloc(
            storageRepository: storageRepository,
          );

          // Load saved language
          newBloc.add(const LoadSavedLanguage());
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify the loaded language
          expect(newBloc.state, equals(const LanguageSelected(Language.ga)));

          await newBloc.close();
        },
      );

      blocTest<LanguageManagerBloc, LanguageManagerState>(
        'should update persisted language when changed multiple times',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SelectLanguage(Language.akan));
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(const SelectLanguage(Language.ewe));
          await Future.delayed(const Duration(milliseconds: 50));
        },
        verify: (_) async {
          final (language, error) = await storageRepository
              .getLanguagePreference();
          expect(error, isNull);
          expect(language, equals(Language.ewe));
        },
      );
    });

    group('Initial Language Loading', () {
      test(
        'should load saved language on initialization if available',
        () async {
          // Arrange - save a language first
          await storageRepository.saveLanguagePreference(Language.akan);

          // Act - create a new bloc and load saved language
          final newBloc = LanguageManagerBloc(
            storageRepository: storageRepository,
          );
          newBloc.add(const LoadSavedLanguage());

          // Wait for the event to process
          await Future.delayed(const Duration(milliseconds: 100));

          // Assert
          expect(newBloc.state, equals(const LanguageSelected(Language.akan)));

          await newBloc.close();
        },
      );

      test('should start with English when no saved language exists', () {
        // Act - create a new bloc
        final newBloc = LanguageManagerBloc(
          storageRepository: storageRepository,
        );

        // Assert
        expect(newBloc.state, equals(const LanguageSelected(Language.english)));

        newBloc.close();
      });
    });
  });
}
