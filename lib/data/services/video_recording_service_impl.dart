import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/error/app_error.dart';
import '../../core/utils/enums.dart';
import '../../domain/services/video_recording_service.dart';

/// Implementation of [VideoRecordingService] using the camera package
class VideoRecordingServiceImpl implements VideoRecordingService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<AppError?> initialize() async {
    try {
      // Request camera and microphone permissions
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        return AppError(
          type: ErrorType.camera,
          message: 'Camera permission denied',
          userFriendlyMessage:
              'Camera permission is required. Please enable it in Settings > Apps > Ahenkan > Permissions.',
          isRecoverable: false,
        );
      }

      if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
        return AppError(
          type: ErrorType.camera,
          message: 'Microphone permission denied',
          userFriendlyMessage:
              'Microphone permission is required for camera access. Please enable it in Settings > Apps > Ahenkan > Permissions.',
          isRecoverable: false,
        );
      }

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        return AppError(
          type: ErrorType.camera,
          message: 'No cameras available on device',
          userFriendlyMessage:
              'No camera found. If using an emulator, make sure camera emulation is enabled in AVD settings.',
          isRecoverable: false,
        );
      }

      // Use the first available camera (usually back camera)
      // For sign language, we might want the front camera, so we'll look for it
      CameraDescription? frontCamera;
      try {
        frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // If no front camera, use the first available camera
        frontCamera = _cameras!.first;
      }

      // Initialize camera controller with appropriate resolution
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false, // Sign language doesn't need audio
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;

      return null;
    } on CameraException catch (e) {
      return _handleCameraException(e);
    } catch (e) {
      return AppError(
        type: ErrorType.camera,
        message: 'Failed to initialize camera: $e',
        userFriendlyMessage:
            'Could not access the camera. Error: ${e.toString()}. Please check permissions or enable camera in emulator settings.',
        isRecoverable: true,
      );
    }
  }

  @override
  Future<AppError?> startRecording() async {
    if (!_isInitialized || _controller == null) {
      return AppError(
        type: ErrorType.camera,
        message: 'Camera not initialized',
        userFriendlyMessage: 'Camera is not ready. Please wait and try again.',
        isRecoverable: true,
      );
    }

    if (_isRecording) {
      return AppError(
        type: ErrorType.camera,
        message: 'Recording already in progress',
        userFriendlyMessage: 'Recording is already in progress.',
        isRecoverable: false,
      );
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      return null;
    } on CameraException catch (e) {
      return _handleCameraException(e);
    } catch (e) {
      return AppError(
        type: ErrorType.camera,
        message: 'Failed to start recording: $e',
        userFriendlyMessage: 'Could not start recording. Please try again.',
        isRecoverable: true,
      );
    }
  }

  @override
  Future<(File?, AppError?)> stopRecording() async {
    if (!_isInitialized || _controller == null) {
      return (
        null,
        AppError(
          type: ErrorType.camera,
          message: 'Camera not initialized',
          userFriendlyMessage:
              'Camera is not ready. Please wait and try again.',
          isRecoverable: true,
        ),
      );
    }

    if (!_isRecording) {
      return (
        null,
        AppError(
          type: ErrorType.camera,
          message: 'No recording in progress',
          userFriendlyMessage: 'No recording is currently in progress.',
          isRecoverable: false,
        ),
      );
    }

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Convert XFile to File
      final file = File(videoFile.path);

      return (file, null);
    } on CameraException catch (e) {
      _isRecording = false;
      return (null, _handleCameraException(e));
    } catch (e) {
      _isRecording = false;
      return (
        null,
        AppError(
          type: ErrorType.camera,
          message: 'Failed to stop recording: $e',
          userFriendlyMessage:
              'Could not save the recording. Please try again.',
          isRecoverable: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isRecording = false;
  }

  /// Handles camera exceptions and converts them to AppError
  AppError _handleCameraException(CameraException e) {
    String userMessage;
    bool isRecoverable = true;

    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        userMessage =
            'Camera access denied. Please enable camera permissions in your device settings.';
        isRecoverable = false;
        break;
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
      case 'AudioAccessRestricted':
        userMessage =
            'Microphone access denied. Please enable microphone permissions in your device settings.';
        isRecoverable = false;
        break;
      default:
        userMessage =
            'Camera error occurred. Please try again or restart the app.';
        isRecoverable = true;
    }

    return AppError(
      type: ErrorType.camera,
      message: 'CameraException: ${e.code} - ${e.description}',
      userFriendlyMessage: userMessage,
      isRecoverable: isRecoverable,
    );
  }

  /// Gets the camera controller for use in UI (e.g., camera preview)
  CameraController? get controller => _controller;
}
