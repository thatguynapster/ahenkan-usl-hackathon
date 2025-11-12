import 'package:flutter/material.dart';

/// A skeleton loading widget that provides visual feedback during loading states
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
          ),
        );
      },
    );
  }
}

/// A skeleton widget for text loading
class TextLoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final int lines;

  const TextLoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.lines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? 8.0 : 0),
          child: LoadingSkeleton(
            width: index == lines - 1 ? width * 0.7 : width,
            height: height,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }
}

/// A skeleton widget for card loading
class CardLoadingSkeleton extends StatelessWidget {
  const CardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LoadingSkeleton(
                  width: 48.0,
                  height: 48.0,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(
                        width: double.infinity,
                        height: 16.0,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      const SizedBox(height: 8.0),
                      LoadingSkeleton(
                        width: 100.0,
                        height: 12.0,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const TextLoadingSkeleton(lines: 2),
          ],
        ),
      ),
    );
  }
}
