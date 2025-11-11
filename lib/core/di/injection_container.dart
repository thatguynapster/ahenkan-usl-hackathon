import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/storage_repository_impl.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../presentation/bloc/language_manager/language_manager_bloc.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
/// This function should be called before runApp() in main.dart
Future<void> initializeDependencies() async {
  // ========== External Dependencies ==========
  // Register external packages that need initialization
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ========== Data Sources ==========
  // Register data sources (local storage, remote APIs, etc.)

  // ========== Repositories ==========
  // Register repository implementations
  sl.registerLazySingleton<StorageRepository>(
    () => StorageRepositoryImpl(sl()),
  );

  // ========== Services ==========
  // Register service implementations
  // Example:
  // sl.registerLazySingleton<VideoRecordingService>(
  //   () => VideoRecordingServiceImpl(),
  // );
  // sl.registerLazySingleton<SignLanguageInterpretationService>(
  //   () => SignLanguageInterpretationServiceImpl(mlRepository: sl()),
  // );
  // sl.registerLazySingleton<SignLanguageGenerationService>(
  //   () => SignLanguageGenerationServiceImpl(mlRepository: sl()),
  // );
  // sl.registerLazySingleton<SpeechToTextService>(
  //   () => SpeechToTextServiceImpl(),
  // );

  // ========== BLoCs ==========
  // Register BLoC instances as factories (new instance each time)
  sl.registerFactory(() => LanguageManagerBloc(storageRepository: sl()));
  // sl.registerFactory(
  //   () => SignLanguageInterpreterBloc(
  //     videoRecordingService: sl(),
  //     interpretationService: sl(),
  //   ),
  // );
  // sl.registerFactory(
  //   () => TextToSignGeneratorBloc(
  //     generationService: sl(),
  //     speechToTextService: sl(),
  //   ),
  // );
  // sl.registerFactory(
  //   () => SessionManagerBloc(),
  // );
}

/// Reset all registered dependencies
/// Useful for testing
Future<void> resetDependencies() async {
  await sl.reset();
}
