# Design Document

## Overview

The Sign Language Communication App is a Flutter-based mobile application that facilitates bidirectional communication between hearing individuals and persons with hearing disabilities. The application consists of two primary modes: Sign-to-Text (recording and interpreting sign language gestures) and Text-to-Sign (generating animated sign language videos from text or speech input). The app supports multiple languages (English, Akan, Ga, Ewe) and maintains session-based communication history.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Sign-to-Text    │         │  Text-to-Sign    │         │
│  │     Screen       │         │     Screen       │         │
│  └──────────────────┘         └──────────────────┘         │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │    Language      │         │     History      │         │
│  │    Selector      │         │     Screen       │         │
│  └──────────────────┘         └──────────────────┘         │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                    │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────┐ │
│  │  Sign Language   │  │   Text-to-Sign   │  │  Session  │ │
│  │   Interpreter    │  │    Generator     │  │  Manager  │ │
│  └──────────────────┘  └──────────────────┘  └───────────┘ │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │    Language      │  │  Speech-to-Text  │                │
│  │    Manager       │  │     Service      │                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────┐ │
│  │   Video Capture  │  │   ML Model       │  │  Local    │ │
│  │     Service      │  │   Repository     │  │  Storage  │ │
│  └──────────────────┘  └──────────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns

-   **BLoC Pattern**: For state management across the application
-   **Repository Pattern**: For abstracting data sources (ML models, storage)
-   **Service Layer**: For encapsulating business logic
-   **Dependency Injection**: Using get_it for managing dependencies

## Components and Interfaces

### 1. Presentation Layer

#### SignToTextScreen

-   Displays camera preview for recording sign language
-   Shows video recording controls (start/stop)
-   Displays interpreted text output
-   Provides access to language selector
-   Shows recording status indicators

**Key Widgets:**

-   `CameraPreviewWidget`: Displays live camera feed
-   `RecordingControlButton`: Circular button for recording control
-   `InterpretationDisplayWidget`: Shows translated text in a styled container
-   `LanguageSelectorButton`: Dropdown for language selection

#### TextToSignScreen

-   Provides text input field with placeholder
-   Offers microphone button for voice input
-   Displays generated animated sign language video
-   Shows video playback controls
-   Provides access to language selector

**Key Widgets:**

-   `TextInputField`: Multi-line text input with character limit
-   `VoiceInputButton`: Microphone icon button
-   `SignVideoPlayer`: Video player for animated sign language
-   `VideoControlsWidget`: Play, pause, replay controls

#### HistoryScreen

-   Displays chronological list of communication exchanges
-   Shows timestamps for each message
-   Differentiates between sign-to-text and text-to-sign messages
-   Supports scrolling through session history

**Key Widgets:**

-   `HistoryListView`: Scrollable list of messages
-   `MessageCard`: Individual message display with timestamp and type indicator

#### LanguageSelectorWidget

-   Dropdown menu with language options
-   Displays current language selection
-   Persists language preference

### 2. Business Logic Layer

#### SignLanguageInterpreterBloc

```dart
class SignLanguageInterpreterBloc {
  // States
  - InterpreterInitial
  - InterpreterRecording
  - InterpreterProcessing
  - InterpreterSuccess(String text, double confidence)
  - InterpreterError(String message)

  // Events
  - StartRecording
  - StopRecording
  - ProcessVideo(File videoFile)
  - ResetInterpreter
}
```

#### TextToSignGeneratorBloc

```dart
class TextToSignGeneratorBloc {
  // States
  - GeneratorInitial
  - GeneratorProcessing
  - GeneratorSuccess(String videoPath)
  - GeneratorError(String message)

  // Events
  - GenerateFromText(String text)
  - GenerateFromSpeech
  - ReplayVideo
  - ClearGeneration
}
```

#### SessionManagerBloc

```dart
class SessionManagerBloc {
  // States
  - SessionActive(List<Message> history)
  - SessionCleared

  // Events
  - AddMessage(Message message)
  - ClearSession
  - GetHistory
}
```

#### LanguageManagerBloc

```dart
class LanguageManagerBloc {
  // States
  - LanguageSelected(Language language)

  // Events
  - SelectLanguage(Language language)
  - LoadSavedLanguage
}
```

### 3. Service Layer

#### VideoRecordingService

```dart
interface VideoRecordingService {
  Future<void> initialize();
  Future<void> startRecording();
  Future<File> stopRecording();
  void dispose();
}
```

#### SignLanguageInterpretationService

```dart
interface SignLanguageInterpretationService {
  Future<InterpretationResult> interpretVideo(File videoFile, Language language);
}

class InterpretationResult {
  String text;
  double confidence;
  Language language;
}
```

#### SignLanguageGenerationService

```dart
interface SignLanguageGenerationService {
  Future<String> generateSignVideo(String text, Language language);
}
```

#### SpeechToTextService

```dart
interface SpeechToTextService {
  Future<void> initialize();
  Future<String> startListening(Language language);
  void stopListening();
}
```

### 4. Data Layer

#### MLModelRepository

```dart
interface MLModelRepository {
  Future<void> loadModel(ModelType type);
  Future<dynamic> runInference(dynamic input, ModelType type);
  bool isModelLoaded(ModelType type);
}

enum ModelType {
  signLanguageRecognition,
  signLanguageGeneration
}
```

#### StorageRepository

```dart
interface StorageRepository {
  Future<void> saveLanguagePreference(Language language);
  Future<Language> getLanguagePreference();
  Future<void> saveVideoFile(File video, String filename);
  Future<File> getVideoFile(String filename);
  Future<void> deleteVideoFile(String filename);
}
```

## Data Models

### Message

```dart
class Message {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final Language language;
  final String? videoPath; // For text-to-sign messages

  Message({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.language,
    this.videoPath,
  });
}

enum MessageType {
  signToText,
  textToSign
}
```

### Language

```dart
enum Language {
  english,
  akan,
  ga,
  ewe
}

extension LanguageExtension on Language {
  String get displayName {
    switch (this) {
      case Language.english: return 'English';
      case Language.akan: return 'Akan';
      case Language.ga: return 'Ga';
      case Language.ewe: return 'Ewe';
    }
  }

  String get code {
    switch (this) {
      case Language.english: return 'en';
      case Language.akan: return 'ak';
      case Language.ga: return 'gaa';
      case Language.ewe: return 'ee';
    }
  }
}
```

### AppConfiguration

```dart
class AppConfiguration {
  static const int maxTextInputLength = 500;
  static const int minConfidenceThreshold = 70;
  static const Duration interpretationTimeout = Duration(seconds: 5);
  static const Duration generationTimeout = Duration(seconds: 3);
  static const int minFrameRate = 24;
  static const double minTouchTargetSize = 44.0;
  static const Duration feedbackDelay = Duration(milliseconds: 100);
}
```

## Error Handling

### Error Types

1. **Camera Errors**

    - Camera permission denied
    - Camera initialization failed
    - Recording failed

2. **Interpretation Errors**

    - Low confidence interpretation (< 70%)
    - Video processing timeout
    - Model inference failed
    - Unsupported gesture detected

3. **Generation Errors**

    - Text-to-sign generation failed
    - Animation rendering failed
    - Invalid input text

4. **Speech Recognition Errors**

    - Microphone permission denied
    - Speech recognition failed
    - No speech detected

5. **Storage Errors**
    - Insufficient storage space
    - File read/write failed

### Error Handling Strategy

```dart
class AppError {
  final ErrorType type;
  final String message;
  final String userFriendlyMessage;
  final bool isRecoverable;

  AppError({
    required this.type,
    required this.message,
    required this.userFriendlyMessage,
    required this.isRecoverable,
  });
}

enum ErrorType {
  camera,
  interpretation,
  generation,
  speech,
  storage,
  network,
  permission
}
```

**Error Display:**

-   Show user-friendly error messages in SnackBars
-   Provide retry options for recoverable errors
-   Log technical errors for debugging
-   Display permission request dialogs when needed

## Testing Strategy

### Unit Tests

-   Test BLoC state transitions
-   Test service layer methods
-   Test data model serialization
-   Test utility functions and extensions

### Widget Tests

-   Test individual widget rendering
-   Test user interactions (button taps, text input)
-   Test widget state changes
-   Test navigation flows

### Integration Tests

-   Test complete user flows (record → interpret → display)
-   Test mode switching
-   Test language selection persistence
-   Test session history management

### Key Test Scenarios

1. **Sign-to-Text Flow**

    - User starts recording → video captures → stops recording → interpretation displays
    - Low confidence scenario → error message displays → retry option available

2. **Text-to-Sign Flow**

    - User enters text → generates video → video plays
    - User uses voice input → transcribes → generates video

3. **Language Selection**

    - User selects language → preference persists → affects all interpretations

4. **Session History**
    - Messages added to history → history displays chronologically → clears on app close

## UI/UX Specifications

### Color Scheme

-   Primary: Clean, accessible colors with 4.5:1 contrast ratio
-   Background: White (#FFFFFF)
-   Text: Dark gray/black for readability
-   Accent: For interactive elements and status indicators
-   Error: Red tones for error states
-   Success: Green tones for successful operations

### Typography

-   Headers: Bold, larger font sizes
-   Body text: Regular weight, readable size (16sp minimum)
-   Hints/placeholders: Lighter gray

### Layout

-   Minimum touch target: 44x44 dp
-   Padding: Consistent spacing (16dp, 24dp)
-   Video display: Rounded corners for visual appeal
-   Bottom navigation or tab bar for mode switching

### Animations

-   Smooth transitions between screens (300ms)
-   Recording indicator pulse animation
-   Video playback smooth at 24+ fps
-   Loading indicators for processing states

## Technical Considerations

### Flutter Packages

-   **camera**: For video recording functionality
-   **video_player**: For playing generated sign language videos
-   **speech_to_text**: For voice input
-   **flutter_bloc**: For state management
-   **get_it**: For dependency injection
-   **shared_preferences**: For storing language preference
-   **path_provider**: For file system access
-   **tflite_flutter**: For running ML models (if using TensorFlow Lite)

### ML Model Integration

-   Models should be bundled with the app or downloaded on first launch
-   Separate models for each language if needed
-   Optimize models for mobile performance (quantization, pruning)
-   Consider using cloud-based APIs for complex interpretation/generation if local models are insufficient

### Performance Optimization

-   Lazy load ML models
-   Cache generated sign videos for repeated phrases
-   Optimize video encoding/decoding
-   Use efficient state management to minimize rebuilds
-   Implement proper disposal of camera and video resources

### Accessibility

-   Support screen readers for UI elements
-   High contrast mode support
-   Adjustable text sizes
-   Clear visual feedback for all interactions
-   Haptic feedback for important actions

### Platform Considerations

-   Request camera and microphone permissions appropriately
-   Handle different screen sizes and orientations
-   Test on both iOS and Android
-   Consider platform-specific UI guidelines where appropriate
