# Dependency Injection Setup

This directory contains the dependency injection configuration using `get_it`.

## Usage

The service locator is initialized in `main.dart` before the app runs:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initializeDependencies();
  runApp(const MyApp());
}
```

## Registering Dependencies

### Singleton Registration

Use `registerLazySingleton` for services that should have only one instance:

```dart
sl.registerLazySingleton<StorageRepository>(
  () => StorageRepositoryImpl(sharedPreferences: sl()),
);
```

### Factory Registration

Use `registerFactory` for BLoCs that need a new instance each time:

```dart
sl.registerFactory(
  () => LanguageManagerBloc(storageRepository: sl()),
);
```

### Async Registration

For dependencies that require async initialization:

```dart
final sharedPreferences = await SharedPreferences.getInstance();
sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
```

## Accessing Dependencies

In your code, access registered dependencies using the service locator:

```dart
import 'package:ahenkan/core/di/injection_container.dart';

// In a widget or class
final languageBloc = sl<LanguageManagerBloc>();
```

## Testing

For testing, use `resetDependencies()` to clear all registrations:

```dart
setUp(() async {
  await resetDependencies();
  // Register test doubles
});
```

## Registration Order

Dependencies should be registered in this order:

1. External dependencies (SharedPreferences, etc.)
2. Data sources
3. Repositories
4. Services
5. BLoCs

This ensures that dependencies are available when needed by other components.
