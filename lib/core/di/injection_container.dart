import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/storage_repository_impl.dart';
import '../../data/services/sign_language_generation_service_impl.dart';
import '../../data/services/sign_language_interpretation_service_impl.dart';
import '../../data/services/speech_to_text_service_impl.dart';
import '../../data/services/video_recording_service_impl.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/services/sign_language_generation_service.dart';
import '../../domain/services/sign_language_interpretation_service.dart';
import '../../domain/services/speech_to_text_service.dart';
import '../../domain/services/video_recording_service.dart';
import '../../presentation/bloc/language_manager/language_manager_bloc.dart';
import '../../presentation/bloc/session_manager/session_manager_bloc.dart';
import '../lifecycle/app_lifecycle_manager.dart';
import '../lifecycle/video_player_manager.dart';

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
  sl.registerLazySingleton<VideoRecordingService>(
    () => VideoRecordingServiceImpl(),
  );
  sl.registerLazySingleton<SignLanguageInterpretationService>(
    () => SignLanguageInterpretationServiceImpl(),
  );
  sl.registerLazySingleton<SignLanguageGenerationService>(
    () => SignLanguageGenerationServiceImpl(),
  );
  sl.registerLazySingleton<SpeechToTextService>(
    () => SpeechToTextServiceImpl(),
  );

  // ========== BLoCs ==========
  // Register LanguageManagerBloc as singleton to share across app and lifecycle manager
  sl.registerLazySingleton(() => LanguageManagerBloc(storageRepository: sl()));

  // Register SessionManagerBloc as singleton to share session across screens
  sl.registerLazySingleton(() => SessionManagerBloc());

  // ========== Lifecycle Management ==========
  // Register video player manager as singleton
  sl.registerLazySingleton(() => VideoPlayerManager());

  // Register lifecycle manager as singleton
  sl.registerLazySingleton(
    () => AppLifecycleManager(
      videoRecordingService: sl(),
      storageRepository: sl(),
      languageManagerBloc: sl(),
      sessionManagerBloc: sl(),
      videoPlayerManager: sl(),
    ),
  );
}

/// Reset all registered dependencies
/// Useful for testing
Future<void> resetDependencies() async {
  await sl.reset();
}
