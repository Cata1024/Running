import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// Card personalizado con acabado Aero glassmorphism
/// 
/// Uso:
/// ```dart
/// AeroCard(
///   child: Column(
///     children: [
///       Text('Título'),
///       Text('Contenido'),
///     ],
///   ),
/// )
/// ```
class AeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AeroLevel level;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool enableBlur;
  final Color? backgroundColor;
  final List<BoxShadow>? customShadow;

  const AeroCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.level = AeroLevel.medium,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.enableBlur = true,
    this.backgroundColor,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.all(TerritoryTokens.space16);
    
    final effectiveBorderRadius = borderRadius ??
        BorderRadius.circular(TerritoryTokens.radiusLarge);

    Widget content = AeroSurface(
      level: level,
      width: width,
      height: height,
      padding: effectivePadding,
      margin: margin,
      borderRadius: effectiveBorderRadius,
      enableBlur: enableBlur,
      child: child,
    );

    // Agregar color de fondo si se especifica
    if (backgroundColor != null) {
      content = Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: effectiveBorderRadius,
        ),
        child: content,
      );
    }

    // Agregar shadow personalizado si se especifica
    if (customShadow != null) {
      content = Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: customShadow,
        ),
        child: content,
      );
    }

    // Agregar interactividad si es necesario
    if (onTap != null || onLongPress != null) {
      content = Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: effectiveBorderRadius,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}

/// Card compacto sin padding extra
class AeroCardCompact extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AeroCardCompact({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AeroCard(
      padding: const EdgeInsets.all(TerritoryTokens.space12),
      level: AeroLevel.subtle,
      onTap: onTap,
      child: child,
    );
  }
}

/// Card elevado con shadow fuerte
class AeroCardElevated extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AeroCardElevated({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AeroCard(
      level: AeroLevel.strong,
      padding: padding,
      customShadow: TerritoryTokens.elevation(
        level: 3,
        color: theme.colorScheme.shadow,
      ),
      child: child,
    );
  }
}
