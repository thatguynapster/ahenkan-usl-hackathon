# App Lifecycle Management

This directory contains components for managing the application lifecycle and resource cleanup.

## Components

### AppLifecycleManager

The `AppLifecycleManager` is responsible for coordinating resource cleanup across the application lifecycle. It implements `WidgetsBindingObserver` to listen to app lifecycle state changes.

**Key Responsibilities:**

-   Dispose camera resources when app is paused or closed
-   Pause and dispose video players when app goes to background
-   Save language preference before app closes
-   Clear session history when app is terminated
-   Handle app pause/resume for camera and recording

**Lifecycle States Handled:**

-   `resumed`: App returns to foreground
-   `inactive`: App becomes inactive (e.g., incoming call)
-   `paused`: App moves to background
-   `detached`: App is about to be terminated

### VideoPlayerManager

The `VideoPlayerManager` tracks all active video player controllers and provides centralized lifecycle management.

**Key Features:**

-   Register/unregister video player controllers
-   Pause all active video players
-   Dispose all active video players
-   Track count of active controllers

## Usage

The lifecycle manager is automatically initialized in `main.dart` and registered with the dependency injection container. It requires no manual intervention from developers.

### Integration

```dart
// In main.dart
class _MyAppState extends State<MyApp> {
  late final AppLifecycleManager _lifecycleManager;

  @override
  void initState() {
    super.initState();
    _lifecycleManager = sl<AppLifecycleManager>();
    _lifecycleManager.initialize();
  }

  @override
  void dispose() {
    _lifecycleManager.dispose();
    super.dispose();
  }
}
```

### Video Player Registration

Video players should register themselves with the `VideoPlayerManager`:

```dart
final videoPlayerManager = sl<VideoPlayerManager>();
videoPlayerManager.registerController(controller);

// When disposing manually
videoPlayerManager.unregisterController(controller);
```

## Requirements Addressed

This implementation addresses **Requirement 7.4**:

-   Session history is cleared when the app is closed
-   Language preference is saved before app closes
-   Camera resources are properly disposed
-   Video player resources are properly disposed
-   App pause/resume is handled for camera and recording
