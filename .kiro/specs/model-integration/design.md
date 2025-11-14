# Design Document

## Overview

This document outlines the design for integrating a quantized TensorFlow Lite gesture recognition model into the existing Sign Language Communication App. The integration will replace the mock `SignLanguageInterpretationServiceImpl` with a production-ready implementation that uses machine learning to interpret sign language gestures from recorded videos.

## Architecture

### High-Level Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Existing Application Layer                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   SignLanguageInterpreterBloc (No Changes)           │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Service Layer (Updated)                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   SignLanguageInterpretationService (Interface)      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   MLSignLanguageInterpretationService (NEW)          │   │
│  │   - Orchestrates the interpretation pipeline         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              ML Integration Layer (NEW)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Video      │  │   Model      │  │   Output         │  │
│  │ Preprocessor │→ │  Inference   │→ │ PostProcessor    │  │
│  │              │  │   Engine     │  │                  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              TensorFlow Lite Layer                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   TFLite Interpreter                                 │   │
│  │   - Loads quantized model                            │   │
│  │   - Executes inference                               │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. ML Integration Layer Components

#### VideoPreprocessor

Responsible for converting recorded video files into model-compatible tensor input.

```dart
class VideoPreprocessor {
  /// Configuration for preprocessing
  final int targetWidth;
  final int targetHeight;
  final int targetFrameCount;
  final double fps;

  VideoPreprocessor({
    required this.targetWidth,
    required this.targetHeight,
    required this.targetFrameCount,
    required this.fps,
  });

  /// Extracts and preprocesses frames from video file
  /// Returns a tensor ready for model inference
  Future<List<List<List<List<double>>>>> preprocessVideo(File videoFile);

  /// Extracts frames from video at specified FPS
  Future<List<Uint8List>> extractFrames(File videoFile);

  /// Resizes a frame to target dimensions
  Uint8List resizeFrame(Uint8List frame, int width, int height);

  /// Normalizes pixel values to model's expected range
  List<List<List<double>>> normalizeFrame(Uint8List frame);
}
```

#### ModelInferenceEngine

Manages the TensorFlow Lite model lifecycle and executes inference.

```dart
class ModelInferenceEngine {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Loads the quantized model from assets
  Future<void> initialize(String modelPath);

  /// Checks if model is loaded and ready
  bool get isInitialized => _isInitialized;

  /// Runs inference on preprocessed video data
  /// Returns raw model output
  Future<List<dynamic>> runInference(
    List<List<List<List<double>>>> input,
  );

  /// Gets input tensor shape required by the model
  List<int> getInputShape();

  /// Gets output tensor shape from the model
  List<int> getOutputShape();

  /// Releases model resources
  void dispose();
}
```

#### OutputPostProcessor

Converts raw model predictions into human-readable text interpretations.

```dart
class OutputPostProcessor {
  final Map<int, String> _labelMap;
  final double _confidenceThreshold;

  OutputPostProcessor({
    required Map<int, String> labelMap,
    double confidenceThreshold = 0.7,
  }) : _labelMap = labelMap,
       _confidenceThreshold = confidenceThreshold;

  /// Processes model output and returns interpretation result
  InterpretationResult processOutput(
    List<dynamic> modelOutput,
    Language language,
  );

  /// Finds the prediction with highest confidence
  (int index, double confidence) findTopPrediction(List<dynamic> output);

  /// Maps prediction index to text label
  String mapIndexToLabel(int index, Language language);

  /// Validates confidence meets threshold
  bool isConfidenceAcceptable(double confidence);
}
```

### 2. Updated Service Implementation

#### MLSignLanguageInterpretationService

The production implementation that replaces the mock service.

```dart
class MLSignLanguageInterpretationService
    implements SignLanguageInterpretationService {
  final VideoPreprocessor _preprocessor;
  final ModelInferenceEngine _inferenceEngine;
  final OutputPostProcessor _postProcessor;

  MLSignLanguageInterpretationService({
    required VideoPreprocessor preprocessor,
    required ModelInferenceEngine inferenceEngine,
    required OutputPostProcessor postProcessor,
  }) : _preprocessor = preprocessor,
       _inferenceEngine = inferenceEngine,
       _postProcessor = postProcessor;

  @override
  Future<InterpretationResult> interpretVideo(
    File videoFile,
    Language language,
  ) async {
    try {
      // Step 1: Preprocess video
      final tensorInput = await _preprocessor.preprocessVideo(videoFile);

      // Step 2: Run inference
      final modelOutput = await _inferenceEngine.runInference(tensorInput);

      // Step 3: Post-process output
      final result = _postProcessor.processOutput(modelOutput, language);

      return result;
    } on TimeoutException {
      throw TimeoutException(
        'Sign language interpretation timed out after 5 seconds',
      );
    } catch (e) {
      throw Exception('Failed to interpret video: $e');
    }
  }
}
```

## Data Models

### ModelConfiguration

Configuration for the gesture recognition model.

```dart
class ModelConfiguration {
  final String modelAssetPath;
  final int inputWidth;
  final int inputHeight;
  final int inputFrameCount;
  final double inputFps;
  final List<int> inputShape;
  final List<int> outputShape;
  final Map<Language, Map<int, String>> labelMaps;

  const ModelConfiguration({
    required this.modelAssetPath,
    required this.inputWidth,
    required this.inputHeight,
    required this.inputFrameCount,
    required this.inputFps,
    required this.inputShape,
    required this.outputShape,
    required this.labelMaps,
  });

  /// Default configuration (to be updated with actual model specs)
  static const ModelConfiguration defaultConfig = ModelConfiguration(
    modelAssetPath: 'assets/models/gesture_recognition.tflite',
    inputWidth: 224,
    inputHeight: 224,
    inputFrameCount: 30,
    inputFps: 15.0,
    inputShape: [1, 30, 224, 224, 3], // [batch, frames, height, width, channels]
    outputShape: [1, 100], // [batch, num_classes]
    labelMaps: {
      Language.english: {
        0: 'Hello',
        1: 'Thank you',
        2: 'Please',
        // ... more labels
      },
      // ... other languages
    },
  );
}
```

### PreprocessingResult

Intermediate result from video preprocessing.

```dart
class PreprocessingResult {
  final List<List<List<List<double>>>> tensorData;
  final int frameCount;
  final Duration processingTime;

  PreprocessingResult({
    required this.tensorData,
    required this.frameCount,
    required this.processingTime,
  });
}
```

### InferenceResult

Raw output from model inference.

```dart
class InferenceResult {
  final List<dynamic> predictions;
  final Duration inferenceTime;
  final bool usedHardwareAcceleration;

  InferenceResult({
    required this.predictions,
    required this.inferenceTime,
    required this.usedHardwareAcceleration,
  });
}
```

## Implementation Strategy

### Phase 1: Setup and Dependencies

1. Add TensorFlow Lite dependencies to `pubspec.yaml`:

    ```yaml
    dependencies:
        tflite_flutter: ^0.10.4
        tflite_flutter_helper: ^0.3.1
        image: ^4.0.17 # For image processing
        ffmpeg_kit_flutter: ^6.0.3 # For video frame extraction
    ```

2. Create assets directory structure:

    ```
    assets/
    ├── models/
    │   ├── gesture_recognition.tflite
    │   └── labels/
    │       ├── english.json
    │       ├── akan.json
    │       ├── ga.json
    │       └── ewe.json
    ```

3. Update `pubspec.yaml` to include model assets:
    ```yaml
    flutter:
        assets:
            - assets/models/
            - assets/models/labels/
    ```

### Phase 2: Core ML Components

1. Implement `ModelInferenceEngine`:

    - Load TFLite model from assets
    - Configure interpreter with delegates (GPU, NNAPI)
    - Handle tensor allocation and deallocation
    - Implement error handling for model loading failures

2. Implement `VideoPreprocessor`:

    - Use FFmpeg to extract frames from video
    - Resize frames using image processing library
    - Normalize pixel values (typically 0-1 or -1 to 1)
    - Convert to 4D tensor format

3. Implement `OutputPostProcessor`:
    - Load label maps from JSON files
    - Apply softmax to model outputs if needed
    - Map predictions to language-specific labels
    - Handle confidence thresholding

### Phase 3: Service Integration

1. Create `MLSignLanguageInterpretationService`:

    - Orchestrate preprocessing → inference → postprocessing pipeline
    - Add timeout handling (5 seconds)
    - Implement proper error propagation
    - Add logging for debugging

2. Update dependency injection in `injection_container.dart`:

    ```dart
    // Register ML components
    sl.registerLazySingleton<ModelInferenceEngine>(
      () => ModelInferenceEngine(),
    );

    sl.registerLazySingleton<VideoPreprocessor>(
      () => VideoPreprocessor(
        targetWidth: ModelConfiguration.defaultConfig.inputWidth,
        targetHeight: ModelConfiguration.defaultConfig.inputHeight,
        targetFrameCount: ModelConfiguration.defaultConfig.inputFrameCount,
        fps: ModelConfiguration.defaultConfig.inputFps,
      ),
    );

    sl.registerLazySingleton<OutputPostProcessor>(
      () => OutputPostProcessor(
        labelMap: ModelConfiguration.defaultConfig.labelMaps[Language.english]!,
      ),
    );

    // Replace mock service with ML service
    sl.registerLazySingleton<SignLanguageInterpretationService>(
      () => MLSignLanguageInterpretationService(
        preprocessor: sl<VideoPreprocessor>(),
        inferenceEngine: sl<ModelInferenceEngine>(),
        postProcessor: sl<OutputPostProcessor>(),
      ),
    );
    ```

3. Initialize model on app startup:
    ```dart
    // In main.dart or initialization function
    final inferenceEngine = sl<ModelInferenceEngine>();
    await inferenceEngine.initialize(
      ModelConfiguration.defaultConfig.modelAssetPath,
    );
    ```

### Phase 4: Testing and Validation

1. Create unit tests for each component:

    - Test video preprocessing with sample videos
    - Test model inference with mock tensors
    - Test output postprocessing with sample predictions

2. Create integration tests:

    - Test full pipeline with real videos
    - Verify performance meets 5-second requirement
    - Test error handling scenarios

3. Create test assets:
    - Sample videos with known gestures
    - Expected interpretation results
    - Edge case videos (empty, corrupted, etc.)

## Error Handling Strategy

### Error Types and Handling

```dart
enum MLErrorType {
  modelLoadFailed,
  modelNotInitialized,
  preprocessingFailed,
  inferenceFailed,
  postprocessingFailed,
  lowConfidence,
  timeout,
  unsupportedFormat,
}

class MLError extends AppError {
  final MLErrorType mlErrorType;

  MLError({
    required this.mlErrorType,
    required String message,
    required String userFriendlyMessage,
    required bool isRecoverable,
  }) : super(
    type: ErrorType.interpretation,
    message: message,
    userFriendlyMessage: userFriendlyMessage,
    isRecoverable: isRecoverable,
  );

  factory MLError.modelLoadFailed(String details) => MLError(
    mlErrorType: MLErrorType.modelLoadFailed,
    message: 'Failed to load ML model: $details',
    userFriendlyMessage: 'Unable to load gesture recognition model. Please restart the app.',
    isRecoverable: false,
  );

  factory MLError.lowConfidence(double confidence) => MLError(
    mlErrorType: MLErrorType.lowConfidence,
    message: 'Confidence too low: $confidence',
    userFriendlyMessage: 'Could not recognize the gesture clearly. Please try again.',
    isRecoverable: true,
  );

  // ... more factory constructors for other error types
}
```

## Performance Optimization

### Strategies

1. **Model Optimization**:

    - Use quantized model (INT8) for faster inference
    - Enable hardware acceleration (GPU/NNAPI) when available
    - Optimize model architecture for mobile (MobileNet, EfficientNet)

2. **Preprocessing Optimization**:

    - Extract only required number of frames
    - Use efficient image resizing algorithms
    - Cache preprocessing results when possible

3. **Memory Management**:

    - Release tensors after inference
    - Dispose of video frames after preprocessing
    - Use memory-efficient data structures

4. **Async Processing**:
    - Run preprocessing in isolate to avoid blocking UI
    - Use compute() for CPU-intensive operations
    - Implement cancellation for long-running operations

### Performance Targets

-   Model loading: < 2 seconds
-   Video preprocessing: < 2 seconds
-   Model inference: < 1 second
-   Output postprocessing: < 100 milliseconds
-   Total pipeline: < 5 seconds

## Testing Strategy

### Unit Tests

```dart
// Test VideoPreprocessor
test('preprocessVideo extracts correct number of frames', () async {
  final preprocessor = VideoPreprocessor(
    targetWidth: 224,
    targetHeight: 224,
    targetFrameCount: 30,
    fps: 15.0,
  );

  final result = await preprocessor.preprocessVideo(testVideoFile);

  expect(result.length, equals(1)); // batch size
  expect(result[0].length, equals(30)); // frame count
  expect(result[0][0].length, equals(224)); // height
  expect(result[0][0][0].length, equals(224)); // width
});

// Test ModelInferenceEngine
test('runInference returns valid predictions', () async {
  final engine = ModelInferenceEngine();
  await engine.initialize('assets/models/test_model.tflite');

  final input = createMockTensorInput();
  final output = await engine.runInference(input);

  expect(output, isNotEmpty);
  expect(output[0], isA<List>());
});

// Test OutputPostProcessor
test('processOutput returns correct interpretation', () {
  final postProcessor = OutputPostProcessor(
    labelMap: {0: 'Hello', 1: 'Thank you'},
    confidenceThreshold: 0.7,
  );

  final mockOutput = [[0.9, 0.1]]; // High confidence for "Hello"
  final result = postProcessor.processOutput(mockOutput, Language.english);

  expect(result.text, equals('Hello'));
  expect(result.confidence, equals(0.9));
});
```

### Integration Tests

```dart
testWidgets('Full interpretation pipeline works end-to-end', (tester) async {
  // Setup
  final service = MLSignLanguageInterpretationService(
    preprocessor: VideoPreprocessor(...),
    inferenceEngine: ModelInferenceEngine(),
    postProcessor: OutputPostProcessor(...),
  );

  // Execute
  final result = await service.interpretVideo(
    testVideoFile,
    Language.english,
  );

  // Verify
  expect(result.text, isNotEmpty);
  expect(result.confidence, greaterThan(0.7));
  expect(result.language, equals(Language.english));
});
```

## Migration Path

### From Mock to ML Service

1. **Keep mock service available**:

    - Rename `SignLanguageInterpretationServiceImpl` to `MockSignLanguageInterpretationService`
    - Keep it for testing and development

2. **Feature flag for switching**:

    ```dart
    class AppConfiguration {
      static const bool useMockInterpretation = false; // Set to true for testing
    }

    // In injection_container.dart
    if (AppConfiguration.useMockInterpretation) {
      sl.registerLazySingleton<SignLanguageInterpretationService>(
        () => MockSignLanguageInterpretationService(),
      );
    } else {
      sl.registerLazySingleton<SignLanguageInterpretationService>(
        () => MLSignLanguageInterpretationService(...),
      );
    }
    ```

3. **Gradual rollout**:
    - Test ML service thoroughly in development
    - Use mock service as fallback if ML service fails
    - Monitor performance and errors in production

## Platform-Specific Considerations

### Android

-   Enable NNAPI delegate for hardware acceleration
-   Configure ProGuard rules to keep TFLite classes
-   Request appropriate permissions in AndroidManifest.xml

### iOS

-   Enable Metal delegate for GPU acceleration
-   Configure Info.plist for camera and storage access
-   Ensure model is included in app bundle

### Configuration Files

**android/app/build.gradle**:

```gradle
android {
    aaptOptions {
        noCompress 'tflite'
    }
}
```

**android/app/proguard-rules.pro**:

```
-keep class org.tensorflow.** { *; }
```

## Demo Readiness Checklist

-   [ ] Model file added to assets
-   [ ] Label maps created for all languages
-   [ ] TFLite dependencies added
-   [ ] VideoPreprocessor implemented and tested
-   [ ] ModelInferenceEngine implemented and tested
-   [ ] OutputPostProcessor implemented and tested
-   [ ] MLSignLanguageInterpretationService implemented
-   [ ] Dependency injection updated
-   [ ] Model initialization on app startup
-   [ ] Error handling implemented
-   [ ] Performance optimization applied
-   [ ] Unit tests passing
-   [ ] Integration tests passing
-   [ ] Tested with real sign language videos
-   [ ] Performance meets 5-second requirement
-   [ ] All languages supported
-   [ ] Confidence threshold working correctly
-   [ ] Error messages user-friendly
-   [ ] App stable and crash-free
