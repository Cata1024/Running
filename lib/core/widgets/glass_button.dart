import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Botón moderno con efecto Glassmorphism
class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool isLoading;
  final bool isOutlined;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultGradient = widget.gradient ?? (widget.isOutlined 
        ? null 
        : AppTheme.primaryGradient);

    final defaultBgColor = widget.backgroundColor ?? (widget.isOutlined
        ? Colors.transparent
        : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.9)));

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading || widget.onPressed == null 
          ? null 
          : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.isOutlined ? null : defaultGradient,
                color: widget.isOutlined ? defaultBgColor : null,
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(AppTheme.radiusMedium),
                border: widget.isOutlined
                    ? Border.all(
                        color: AppTheme.primaryGradientStart,
                        width: 2,
                      )
                    : null,
                boxShadow: [
                  if (!widget.isOutlined && !_isPressed)
                    BoxShadow(
                      color: (defaultGradient?.colors.first ?? 
                          AppTheme.primaryGradientStart).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(AppTheme.radiusMedium),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: widget.padding ?? 
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isOutlined
                                      ? AppTheme.primaryGradientStart
                                      : Colors.white,
                                ),
                              ),
                            )
                          : DefaultTextStyle(
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: widget.isOutlined
                                    ? AppTheme.primaryGradientStart
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ) ?? const TextStyle(),
                              child: widget.child,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Botón de icono con efecto Glassmorphism
class GlassIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isLoading;

  const GlassIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48,
    this.iconColor,
    this.backgroundColor,
    this.isLoading = false,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null && !widget.isLoading) {
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null && !widget.isLoading) {
          _controller.reverse();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null && !widget.isLoading) {
          _controller.reverse();
        }
      },
      onTap: widget.isLoading || widget.onPressed == null 
          ? null 
          : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassContainer(
              width: widget.size,
              height: widget.size,
              padding: const EdgeInsets.all(0),
              borderRadius: BorderRadius.circular(widget.size / 2),
              backgroundColor: widget.backgroundColor ?? 
                  (isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.8)),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.size * 0.4,
                        height: widget.size * 0.4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.iconColor ?? theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        widget.icon,
                        size: widget.size * 0.5,
                        color: widget.iconColor ?? theme.colorScheme.primary,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// FAB con estilo Glassmorphism
class GlassFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final bool extended;
  final Gradient? gradient;

  const GlassFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.extended = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    if (extended && label != null) {
      return GlassButton(
        onPressed: onPressed,
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GlassIconButton(
      onPressed: onPressed,
      icon: icon,
      size: 56,
      backgroundColor: gradient?.colors.first ?? AppTheme.primaryGradientStart,
      iconColor: Colors.white,
    );
  }
}
