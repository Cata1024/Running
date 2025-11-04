import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// Botón moderno con acabado Aero
class AeroButton extends StatefulWidget {
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
  final String? semanticLabel;

  const AeroButton({
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
    this.semanticLabel,
  });

  @override
  State<AeroButton> createState() => _AeroButtonState();
}

class _AeroButtonState extends State<AeroButton>
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
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = widget.borderRadius ??
        BorderRadius.circular(TerritoryTokens.radiusMedium);
    final padding = widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: TerritoryTokens.space24,
          vertical: TerritoryTokens.space12,
        );
    final bool disabled = widget.onPressed == null || widget.isLoading;
    final gradient = widget.gradient ??
        LinearGradient(
          colors: [
            scheme.primary,
            scheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final backgroundColor = widget.backgroundColor ??
        (widget.isOutlined
            ? scheme.surfaceContainerHigh
            : scheme.primary);

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: disabled ? null : _handleTapDown,
        onTapUp: disabled ? null : _handleTapUp,
        onTapCancel: disabled ? null : _handleTapCancel,
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: disabled ? 0.6 : 1,
              child: AeroSurface(
                width: widget.width,
                height: widget.height,
                level:
                    widget.isOutlined ? AeroLevel.ghost : AeroLevel.medium,
                borderRadius: borderRadius,
                padding: EdgeInsets.zero,
                enableBlur: !widget.isOutlined,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: widget.isOutlined ? null : gradient,
                    color: widget.isOutlined ? backgroundColor : null,
                    borderRadius: borderRadius,
                    border: widget.isOutlined
                        ? Border.all(
                            color: backgroundColor,
                            width: TerritoryTokens.borderThin,
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: padding,
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isOutlined
                                      ? backgroundColor
                                      : theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : DefaultTextStyle(
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: widget.isOutlined
                                    ? backgroundColor
                                    : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ) ??
                              const TextStyle(),
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
      ),
    );
  }
}

/// Botón de icono con acabado Aero
class AeroIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isLoading;
  final String? semanticLabel;

  const AeroIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48,
    this.iconColor,
    this.backgroundColor,
    this.isLoading = false,
    this.semanticLabel,
  });

  @override
  State<AeroIconButton> createState() => _AeroIconButtonState();
}

class _AeroIconButtonState extends State<AeroIconButton>
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
    final scheme = theme.colorScheme;
    final bool disabled = widget.onPressed == null || widget.isLoading;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel,
      child: GestureDetector(
      onTapDown: disabled
          ? null
          : (_) {
              _controller.forward();
            },
      onTapUp: disabled
          ? null
          : (_) {
              _controller.reverse();
            },
      onTapCancel: disabled
          ? null
          : () {
              _controller.reverse();
            },
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: disabled ? 0.6 : 1,
              child: AeroSurface(
                width: widget.size,
                height: widget.size,
                borderRadius: BorderRadius.circular(widget.size / 2),
                level: AeroLevel.subtle,
                padding: const EdgeInsets.all(TerritoryTokens.space12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ??
                        scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(widget.size / 2),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: widget.size * 0.4,
                            height: widget.size * 0.4,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.iconColor ?? scheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            widget.icon,
                            size: widget.size * 0.5,
                            color: widget.iconColor ?? scheme.primary,
                          ),
                  ),
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}

/// FAB con estilo Aero
class AeroFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final bool extended;
  final Gradient? gradient;

  const AeroFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.extended = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (extended && label != null) {
      return AeroButton(
        onPressed: onPressed,
        gradient: gradient ??
            LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
        borderRadius:
            BorderRadius.circular(TerritoryTokens.radiusXLarge),
        padding: const EdgeInsets.symmetric(
          horizontal: TerritoryTokens.space16,
          vertical: TerritoryTokens.space12,
        ),
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

    return AeroIconButton(
      onPressed: onPressed,
      icon: icon,
      size: 56,
      backgroundColor:
          gradient?.colors.first ?? theme.colorScheme.primary,
      iconColor: Colors.white,
    );
  }
}
