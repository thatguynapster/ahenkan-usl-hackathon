import 'package:flutter/material.dart';
import '../../core/utils/accessibility_utils.dart';
import '../../core/utils/app_configuration.dart';

/// An accessible button widget that meets all accessibility requirements
/// - Minimum 44x44 dp touch target
/// - Haptic feedback on tap
/// - Smooth animations
/// - High contrast colors
class AccessibleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final HapticFeedbackType hapticType;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.semanticLabel,
    this.hapticType = HapticFeedbackType.medium,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConfiguration.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  Future<void> _handleTap() async {
    if (widget.onPressed != null) {
      await AccessibilityUtils.provideHapticFeedback(type: widget.hapticType);
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? Colors.white;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: widget.onPressed != null,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.width,
            height: widget.height,
            constraints: const BoxConstraints(
              minWidth: AppConfiguration.minTouchTargetSize,
              minHeight: AppConfiguration.minTouchTargetSize,
            ),
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: widget.onPressed == null
                  ? backgroundColor.withValues(alpha: 0.5)
                  : backgroundColor,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12.0),
              boxShadow: widget.onPressed != null && !_isPressed
                  ? [
                      BoxShadow(
                        color: backgroundColor.withValues(alpha: 0.3),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: foregroundColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
