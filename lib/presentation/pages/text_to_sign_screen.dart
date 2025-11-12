import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../core/di/injection_container.dart';
import '../../core/utils/app_configuration.dart';
import '../../core/utils/enums.dart';
import '../bloc/language_manager/language_manager_bloc.dart';
import '../bloc/language_manager/language_manager_event.dart';
import '../bloc/language_manager/language_manager_state.dart';
import '../bloc/text_to_sign_generator/text_to_sign_generator_bloc.dart';
import '../bloc/text_to_sign_generator/text_to_sign_generator_event.dart';
import '../bloc/text_to_sign_generator/text_to_sign_generator_state.dart';
import '../widgets/language_selector_widget.dart';

/// Screen for converting text or speech to sign language video
class TextToSignScreen extends StatelessWidget {
  const TextToSignScreen({super.key});

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

            return TextToSignGeneratorBloc(
              generationService: sl(),
              speechToTextService: sl(),
              currentLanguage: currentLanguage,
            );
          },
        ),
      ],
      child: const _TextToSignScreenContent(),
    );
  }
}

class _TextToSignScreenContent extends StatelessWidget {
  const _TextToSignScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Sign'),
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
      body: BlocListener<TextToSignGeneratorBloc, TextToSignGeneratorState>(
        listener: (context, state) {
          if (state is GeneratorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<TextToSignGeneratorBloc>().add(
                      const ClearGeneration(),
                    );
                  },
                ),
              ),
            );
          }
        },
        child: Column(
          children: [
            // Video player area
            Expanded(flex: 3, child: _VideoPlayerArea()),

            // Text input area
            Expanded(flex: 2, child: _TextInputArea()),
          ],
        ),
      ),
    );
  }
}

/// Widget for text input with microphone button
class _TextInputArea extends StatefulWidget {
  @override
  State<_TextInputArea> createState() => _TextInputAreaState();
}

class _TextInputAreaState extends State<_TextInputArea> {
  final TextEditingController _textController = TextEditingController();
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _textController.text.length;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with character counter
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: Theme.of(context).colorScheme.primary,
                size: 24.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Enter Text',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '$_characterCount/${AppConfiguration.maxTextInputLength}',
                style: TextStyle(
                  fontSize: 12.0,
                  color: _characterCount > AppConfiguration.maxTextInputLength
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Text input field
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 16.0),
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // Action buttons row
          Row(
            children: [
              // Microphone button
              _MicrophoneButton(),
              const SizedBox(width: 12.0),

              // Generate button
              Expanded(
                child:
                    BlocBuilder<
                      TextToSignGeneratorBloc,
                      TextToSignGeneratorState
                    >(
                      builder: (context, state) {
                        final isProcessing = state is GeneratorProcessing;

                        return ElevatedButton(
                          onPressed:
                              isProcessing || _textController.text.isEmpty
                              ? null
                              : () {
                                  context.read<TextToSignGeneratorBloc>().add(
                                    GenerateFromText(_textController.text),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            minimumSize: const Size(
                              AppConfiguration.minTouchTargetSize,
                              AppConfiguration.minTouchTargetSize,
                            ),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Generate Sign Language',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Microphone button for voice input
class _MicrophoneButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextToSignGeneratorBloc, TextToSignGeneratorState>(
      builder: (context, state) {
        final isProcessing = state is GeneratorProcessing;
        final isListening = state is GeneratorListening;
        final isDisabled = isProcessing || isListening;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    context.read<TextToSignGeneratorBloc>().add(
                      const GenerateFromSpeech(),
                    );
                  },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: AppConfiguration.minTouchTargetSize,
              height: AppConfiguration.minTouchTargetSize,
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.withValues(alpha: 0.3)
                    : isListening
                    ? Colors.red.withValues(alpha: 0.1)
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey
                      : isListening
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              child: Icon(
                Icons.mic,
                color: isDisabled
                    ? Colors.grey
                    : isListening
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                size: 24.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget for displaying generated sign language video
class _VideoPlayerArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextToSignGeneratorBloc, TextToSignGeneratorState>(
      builder: (context, state) {
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
                // Video player or placeholder
                if (state is GeneratorSuccess)
                  _VideoPlayer(videoPath: state.videoPath)
                else
                  _VideoPlaceholder(state: state),

                // Listening indicator
                if (state is GeneratorListening)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            size: 64.0,
                            color: Colors.red.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 24.0),
                          const Text(
                            'Listening...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Speak now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Processing indicator
                if (state is GeneratorProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16.0),
                          Text(
                            'Generating sign language...',
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

  Color _getBorderColor(BuildContext context, TextToSignGeneratorState state) {
    if (state is GeneratorProcessing) {
      return Theme.of(context).colorScheme.primary;
    } else if (state is GeneratorSuccess) {
      return Colors.green;
    } else if (state is GeneratorError) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.outline;
  }
}

/// Placeholder widget when no video is available
class _VideoPlaceholder extends StatelessWidget {
  final TextToSignGeneratorState state;

  const _VideoPlaceholder({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sign_language,
            size: 64.0,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16.0),
          Text(
            state is GeneratorInitial
                ? 'Enter text or use voice input\nto generate sign language'
                : 'Ready to generate...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Video player widget with playback controls
class _VideoPlayer extends StatefulWidget {
  final String videoPath;

  const _VideoPlayer({required this.videoPath});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(_VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _disposeController();
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Check if the path is a network URL or a file path
      if (widget.videoPath.startsWith('http://') ||
          widget.videoPath.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
        );
      } else {
        // For file paths, use VideoPlayerController.file
        // Note: This requires dart:io import
        _controller = VideoPlayerController.asset(widget.videoPath);
      }

      await _controller!.initialize();
      await _controller!.setLooping(false);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Handle video initialization error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video display
        FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),

        // Video controls overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _VideoControls(controller: _controller!),
        ),
      ],
    );
  }
}

/// Video playback controls widget
class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVideoStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onVideoStateChanged);
    super.dispose();
  }

  void _onVideoStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          VideoProgressIndicator(
            widget.controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
              bufferedColor: Colors.white.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 8.0),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause button
              IconButton(
                onPressed: () {
                  setState(() {
                    if (isPlaying) {
                      widget.controller.pause();
                    } else {
                      widget.controller.play();
                    }
                  });
                },
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32.0,
                ),
                iconSize: AppConfiguration.minTouchTargetSize,
              ),

              const SizedBox(width: 16.0),

              // Replay button
              IconButton(
                onPressed: () {
                  widget.controller.seekTo(Duration.zero);
                  widget.controller.play();
                },
                icon: const Icon(Icons.replay, color: Colors.white, size: 32.0),
                iconSize: AppConfiguration.minTouchTargetSize,
              ),

              const SizedBox(width: 16.0),

              // Time display
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
