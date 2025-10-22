import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Container con efecto Glassmorphism moderno y optimizado
/// Usa BackdropFilter de manera eficiente para mejor performance
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double blur;
  final double opacity;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.gradient,
    this.border,
    this.boxShadow,
    this.onTap,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    double clampOpacity(double value, double min, double max) =>
        value.clamp(min, max).toDouble();

    final double baseOpacity = clampOpacity(
      isDark ? opacity * 1.6 : opacity,
      0.06,
      0.75,
    );

    final Color surfaceTint = (isDark
            ? scheme.surface
            : scheme.surfaceContainerHighest)
        .withValues(alpha: isDark ? 0.95 : 0.85);
    final Color overlay = Colors.white.withValues(alpha: baseOpacity);
    final Color blendedColor = Color.alphaBlend(overlay, surfaceTint);

    final Gradient? defaultGradient =
        gradient == null && backgroundColor == null
            ? LinearGradient(
                colors: [
                  Colors.white.withValues(
                    alpha: clampOpacity(baseOpacity * (isDark ? 1.4 : 1.1), 0.08, 0.6),
                  ),
                  Colors.white.withValues(
                    alpha: clampOpacity(baseOpacity * (isDark ? 0.6 : 0.4), 0.04, 0.4),
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null;

    final Border defaultBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.22),
          width: 1,
        );

    final List<BoxShadow> effectiveShadow = boxShadow ??
        (isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: -14,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: -6,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppTheme.glassyShadow);

    final Gradient? effectiveGradient = gradient ?? defaultGradient;
    final Color? effectiveColor = backgroundColor ??
        (effectiveGradient == null ? blendedColor : null);

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveGradient == null ? effectiveColor : null,
        gradient: effectiveGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLarge),
        border: defaultBorder,
        boxShadow: effectiveShadow,
      ),
      child: enableBlur
          ? ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLarge),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  padding: padding ?? AppTheme.paddingMedium,
                  child: child,
                ),
              ),
            )
          : Container(
              padding: padding ?? AppTheme.paddingMedium,
              child: child,
            ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLarge),
        child: container,
      );
    }

    return container;
  }
}

/// Card con efecto Glassmorphism y animación
class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enableAnimation;
  final Duration animationDuration;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.onTap,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    if (widget.enableAnimation) {
      _controller = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
    }
  }

  @override
  void dispose() {
    if (widget.enableAnimation) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableAnimation) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableAnimation) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableAnimation) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      margin: widget.margin,
      child: widget.child,
    );

    if (widget.enableAnimation && widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: card,
            );
          },
        ),
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: card,
      );
    }

    return card;
  }
}
