import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// An Expressive Material 3 Card with spring-physics touch response,
/// animated elevation, custom selection state, and refined surface styling.
class M3Card extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;

  const M3Card({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
  });

  @override
  State<M3Card> createState() => _M3CardState();
}

class _M3CardState extends State<M3Card> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final radius = widget.borderRadius ?? BorderRadius.circular(AppTokens.radiusExtraLarge);
    
    // Background color based on selection and theme
    final cardBgColor = widget.isSelected
        ? colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.6)
        : (widget.color ?? colorScheme.surfaceContainerLow);

    final borderColor = widget.isSelected
        ? colorScheme.primary
        : (isDark
            ? colorScheme.outlineVariant.withValues(alpha: 0.3)
            : colorScheme.outlineVariant.withValues(alpha: 0.5));

    final defaultElevation = widget.isSelected ? AppTokens.elevation2 : (widget.elevation ?? AppTokens.elevation0);

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: AnimatedScale(
        scale: _scaleAnimation.value,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: cardBgColor,
          elevation: defaultElevation,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: widget.border ?? Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.8 : 1.0,
              ),
            ),
            child: InkWell(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              borderRadius: radius,
              splashColor: colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: colorScheme.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: widget.padding ?? AppTokens.cardPadding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
