import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../../core/di/injection_container.dart';
import '../../core/utils/enums.dart';
import '../../data/services/video_recording_service_impl.dart';
import '../../domain/services/video_recording_service.dart';
import '../bloc/language_manager/language_manager_bloc.dart';
import '../bloc/language_manager/language_manager_event.dart';
import '../bloc/language_manager/language_manager_state.dart';
import '../bloc/sign_language_interpreter/sign_language_interpreter_bloc.dart';
import '../bloc/sign_language_interpreter/sign_language_interpreter_event.dart';
import '../bloc/sign_language_interpreter/sign_language_interpreter_state.dart';
import '../widgets/language_selector_widget.dart';

/// Screen for recording sign language and converting it to text
class SignToTextScreen extends StatelessWidget {
  const SignToTextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<LanguageManagerBloc>()..add(const LoadSavedLanguage()),
        ),
        BlocProvider(
          create: (context) {
            final languageBloc = context.read<LanguageManagerBloc>();
            final currentLanguage = languageBloc.state is LanguageSelected
                ? (languageBloc.state as LanguageSelected).language
                : Language.english;

            return SignLanguageInterpreterBloc(
              videoRecordingService: sl(),
              interpretationService: sl(),
              currentLanguage: currentLanguage,
            );
          },
        ),
      ],
      child: const _SignToTextScreenContent(),
    );
  }
}

class _SignToTextScreenContent extends StatelessWidget {
  const _SignToTextScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign to Text'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: SizedBox(
                width: 150,
                child: const LanguageSelectorWidget(),
              ),
            ),
          ),
        ],
      ),
      body:
          BlocListener<
            SignLanguageInterpreterBloc,
            SignLanguageInterpreterState
          >(
            listener: (context, state) {
              if (state is InterpreterError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        context.read<SignLanguageInterpreterBloc>().add(
                          const ResetInterpreter(),
                        );
                      },
                    ),
                  ),
                );
              }
            },
            child: Column(
              children: [
                // Camera preview area
                Expanded(flex: 3, child: _CameraPreviewArea()),

                // Recording control button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: _RecordingControlButton(),
                ),

                // Interpretation display area
                Expanded(flex: 2, child: _InterpretationDisplayArea()),
              ],
            ),
          ),
    );
  }
}

/// Widget for displaying camera preview
class _CameraPreviewArea extends StatefulWidget {
  @override
  State<_CameraPreviewArea> createState() => _CameraPreviewAreaState();
}

class _CameraPreviewAreaState extends State<_CameraPreviewArea> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupCameraListener();
  }

  void _setupCameraListener() {
    // Get the video recording service to access the camera controller
    final videoService = sl<VideoRecordingService>();
    if (videoService is VideoRecordingServiceImpl) {
      _cameraController = videoService.controller;
      _cameraController?.addListener(_onCameraChanged);
      _updateCameraState();
    }
  }

  void _onCameraChanged() {
    if (mounted) {
      _updateCameraState();
    }
  }

  void _updateCameraState() {
    final isInitialized = _cameraController?.value.isInitialized ?? false;
    if (_isCameraInitialized != isInitialized) {
      setState(() {
        _isCameraInitialized = isInitialized;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.removeListener(_onCameraChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      SignLanguageInterpreterBloc,
      SignLanguageInterpreterState
    >(
      builder: (context, state) {
        // Update camera controller reference if it changed
        final videoService = sl<VideoRecordingService>();
        final currentController = videoService is VideoRecordingServiceImpl
            ? videoService.controller
            : null;

        if (currentController != _cameraController) {
          // Schedule the update for after the build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _cameraController?.removeListener(_onCameraChanged);
              _cameraController = currentController;
              _cameraController?.addListener(_onCameraChanged);
              _updateCameraState();
            }
          });
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: _getBorderColor(context, state),
              width: 3.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview or placeholder
                if (_isCameraInitialized && _cameraController != null)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize?.height ?? 1,
                      height: _cameraController!.value.previewSize?.width ?? 1,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state is InterpreterRecording ||
                            state is InterpreterProcessing)
                          const CircularProgressIndicator(color: Colors.white)
                        else
                          Icon(
                            Icons.videocam,
                            size: 64.0,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        const SizedBox(height: 16.0),
                        Text(
                          state is InterpreterInitial
                              ? 'Tap record to start'
                              : 'Initializing camera...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Recording status indicator
                if (state is InterpreterRecording)
                  Positioned(
                    top: 16.0,
                    left: 16.0,
                    child: _RecordingStatusIndicator(),
                  ),

                // Processing indicator
                if (state is InterpreterProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16.0),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBorderColor(
    BuildContext context,
    SignLanguageInterpreterState state,
  ) {
    if (state is InterpreterRecording) {
      return Colors.red;
    } else if (state is InterpreterProcessing) {
      return Theme.of(context).colorScheme.primary;
    } else if (state is InterpreterSuccess) {
      return Colors.green;
    } else if (state is InterpreterError) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.outline;
  }
}

/// Recording status indicator with pulsing animation
class _RecordingStatusIndicator extends StatefulWidget {
  @override
  State<_RecordingStatusIndicator> createState() =>
      _RecordingStatusIndicatorState();
}

class _RecordingStatusIndicatorState extends State<_RecordingStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 16.0),
            SizedBox(width: 8.0),
            Text(
              'Recording',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular recording control button
class _RecordingControlButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      SignLanguageInterpreterBloc,
      SignLanguageInterpreterState
    >(
      builder: (context, state) {
        final isRecording = state is InterpreterRecording;
        final isProcessing = state is InterpreterProcessing;
        final isDisabled = isProcessing;

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  if (isRecording) {
                    context.read<SignLanguageInterpreterBloc>().add(
                      const StopRecording(),
                    );
                  } else {
                    context.read<SignLanguageInterpreterBloc>().add(
                      const StartRecording(),
                    );
                  }
                },
          child: Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDisabled
                  ? Colors.grey
                  : (isRecording
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary),
              boxShadow: [
                BoxShadow(
                  color:
                      (isRecording
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary)
                          .withOpacity(0.3),
                  blurRadius: 12.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop : Icons.videocam,
              color: Colors.white,
              size: 40.0,
            ),
          ),
        );
      },
    );
  }
}

/// Area for displaying interpreted text
class _InterpretationDisplayArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      SignLanguageInterpreterBloc,
      SignLanguageInterpreterState
    >(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    SignLanguageInterpreterState state,
  ) {
    if (state is InterpreterSuccess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.0),
              const SizedBox(width: 8.0),
              Text(
                'Interpreted Text',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Confidence: ${(state.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                state.text,
                style: TextStyle(
                  fontSize: 18.0,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (state is InterpreterInitial) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_fields,
              size: 48.0,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Tap the button to start recording',
              style: TextStyle(
                fontSize: 16.0,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Text(
          'Ready to interpret...',
          style: TextStyle(
            fontSize: 16.0,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      );
    }
  }
}
