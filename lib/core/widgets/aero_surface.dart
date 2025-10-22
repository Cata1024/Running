import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system/territory_tokens.dart';

enum AeroLevel {
  ghost,
  subtle,
  medium,
  strong,
}

class AeroSurface extends StatelessWidget {
  final Widget child;
  final AeroLevel level;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool enableBlur;
  final VoidCallback? onTap;

  const AeroSurface({
    super.key,
    required this.child,
    this.level = AeroLevel.medium,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.enableBlur = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final _AeroConfig config = _resolveConfig(level, isDark);
    final BorderRadius effectiveRadius =
        borderRadius ?? BorderRadius.circular(TerritoryTokens.radiusMedium);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: config.opacity),
        borderRadius: effectiveRadius,
        border: config.borderWidth > 0
            ? Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
                width: config.borderWidth,
              )
            : null,
        boxShadow: config.hasShadow
            ? TerritoryTokens.shadowSubtle(theme.colorScheme.shadow)
            : null,
      ),
      child: child,
    );

    if (enableBlur && config.blurSigma > 0) {
      content = ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: config.blurSigma,
            sigmaY: config.blurSigma,
          ),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }

  _AeroConfig _resolveConfig(AeroLevel level, bool isDark) {
    switch (level) {
      case AeroLevel.ghost:
        return _AeroConfig(
          opacity: TerritoryTokens.opacityGhost,
          blurSigma: TerritoryTokens.blurNone,
          borderWidth: TerritoryTokens.borderNone,
          hasShadow: false,
        );
      case AeroLevel.subtle:
        return _AeroConfig(
          opacity: TerritoryTokens.opacitySubtle,
          blurSigma: TerritoryTokens.blurSubtle,
          borderWidth: TerritoryTokens.borderHairline,
          hasShadow: false,
        );
      case AeroLevel.medium:
        return _AeroConfig(
          opacity: TerritoryTokens.opacityMedium,
          blurSigma: TerritoryTokens.blurMedium,
          borderWidth: TerritoryTokens.borderThin,
          hasShadow: true,
        );
      case AeroLevel.strong:
        return _AeroConfig(
          opacity: isDark ? 0.3 : TerritoryTokens.opacityStrong,
          blurSigma: TerritoryTokens.blurStrong,
          borderWidth: TerritoryTokens.borderThin,
          hasShadow: true,
        );
    }
  }
}

class _AeroConfig {
  final double opacity;
  final double blurSigma;
  final double borderWidth;
  final bool hasShadow;

  const _AeroConfig({
    required this.opacity,
    required this.blurSigma,
    required this.borderWidth,
    required this.hasShadow,
  });
}
