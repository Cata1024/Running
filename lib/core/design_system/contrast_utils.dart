import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utilidades para manejar contrastes dinámicos y accesibles
/// 
/// Provee helpers para:
/// - Calcular ratios de contraste (WCAG)
/// - Ajustar opacidades según el tema
/// - Obtener colores accesibles automáticamente
class ContrastUtils {
  ContrastUtils._();

  // ============================================================================
  // CÁLCULO DE CONTRASTE (WCAG)
  // ============================================================================

  /// Calcula la luminancia relativa de un color (0.0 - 1.0)
  /// Fórmula WCAG 2.1
  static double _getRelativeLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round() / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round() / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round() / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4) as double;
  }

  /// Calcula el ratio de contraste entre dos colores (1.0 - 21.0)
  /// WCAG AA requiere mínimo 4.5:1 para texto normal
  /// WCAG AAA requiere mínimo 7.0:1 para texto normal
  static double getContrastRatio(Color foreground, Color background) {
    final l1 = _getRelativeLuminance(foreground);
    final l2 = _getRelativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Verifica si el contraste cumple con WCAG AA (4.5:1)
  static bool meetsWcagAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Verifica si el contraste cumple con WCAG AAA (7.0:1)
  static bool meetsWcagAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }

  // ============================================================================
  // OPACIDADES DINÁMICAS
  // ============================================================================

  /// Obtiene la opacidad ajustada según el tema para mejor contraste
  /// En modo oscuro, las opacidades deben ser más altas para mantener contraste
  static double getAdaptiveOpacity({
    required BuildContext context,
    required AeroOpacityLevel level,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (level) {
      case AeroOpacityLevel.ghost:
        return isDark ? 0.10 : 0.05; // Aumentado de 0.03
      case AeroOpacityLevel.subtle:
        return isDark ? 0.15 : 0.08;
      case AeroOpacityLevel.medium:
        return isDark ? 0.25 : 0.15;
      case AeroOpacityLevel.strong:
        return isDark ? 0.35 : 0.25;
      case AeroOpacityLevel.intense:
        return isDark ? 0.50 : 0.40;
    }
  }

  /// Obtiene el blur ajustado según el tema
  /// En modo oscuro, el blur puede ser más fuerte sin perder legibilidad
  static double getAdaptiveBlur({
    required BuildContext context,
    required AeroBlurLevel level,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final multiplier = isDark ? 1.2 : 1.0;
    
    switch (level) {
      case AeroBlurLevel.none:
        return 0.0;
      case AeroBlurLevel.subtle:
        return 4.0 * multiplier;
      case AeroBlurLevel.medium:
        return 8.0 * multiplier;
      case AeroBlurLevel.strong:
        return 16.0 * multiplier;
      case AeroBlurLevel.intense:
        return 24.0 * multiplier;
    }
  }

  // ============================================================================
  // COLORES ACCESIBLES
  // ============================================================================

  /// Obtiene un color de texto accesible sobre un fondo dado
  /// Garantiza contraste mínimo WCAG AA (4.5:1)
  static Color getAccessibleTextColor({
    required Color background,
    Color? preferredColor,
  }) {
    final darkText = Colors.black87;
    final lightText = Colors.white;

    // Si hay un color preferido, verifica si es accesible
    if (preferredColor != null) {
      if (meetsWcagAA(preferredColor, background)) {
        return preferredColor;
      }
    }

    // Decide entre texto claro u oscuro
    final darkRatio = getContrastRatio(darkText, background);
    final lightRatio = getContrastRatio(lightText, background);

    return darkRatio > lightRatio ? darkText : lightText;
  }

  /// Ajusta el alpha de un color para cumplir con contraste mínimo
  static Color adjustAlphaForContrast({
    required Color foreground,
    required Color background,
    double minRatio = 4.5,
  }) {
    double alpha = foreground.a;
    Color testColor = foreground;

    // Incrementa el alpha hasta cumplir con el contraste
    while (alpha < 1.0 && getContrastRatio(testColor, background) < minRatio) {
      alpha += 0.05;
      testColor = foreground.withValues(alpha: alpha.clamp(0.0, 1.0));
    }

    return testColor;
  }

  // ============================================================================
  // HELPERS PARA GLASSMORPHISM
  // ============================================================================

  /// Obtiene el color de superficie Aero con contraste adecuado
  static Color getAeroSurfaceColor({
    required BuildContext context,
    required AeroOpacityLevel level,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;
    
    final opacity = getAdaptiveOpacity(context: context, level: level);
    
    return baseColor.withValues(alpha: opacity);
  }

  /// Obtiene el color de borde Aero con contraste adecuado
  static Color getAeroBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return theme.colorScheme.outline.withValues(
      alpha: isDark ? 0.3 : 0.2,
    );
  }

  // ============================================================================
  // VALIDACIÓN Y DEBUG
  // ============================================================================

  /// Valida si un par de colores cumple con WCAG y retorna un reporte
  static ContrastReport analyzeContrast(Color foreground, Color background) {
    final ratio = getContrastRatio(foreground, background);
    return ContrastReport(
      ratio: ratio,
      meetsAA: ratio >= 4.5,
      meetsAAA: ratio >= 7.0,
      foreground: foreground,
      background: background,
    );
  }
}

/// Niveles de opacidad para superficies Aero
enum AeroOpacityLevel {
  ghost,   // Muy sutil
  subtle,  // Sutil
  medium,  // Medio
  strong,  // Fuerte
  intense, // Intenso
}

/// Niveles de blur para efectos glassmorphism
enum AeroBlurLevel {
  none,
  subtle,
  medium,
  strong,
  intense,
}

/// Reporte de análisis de contraste
class ContrastReport {
  final double ratio;
  final bool meetsAA;
  final bool meetsAAA;
  final Color foreground;
  final Color background;

  const ContrastReport({
    required this.ratio,
    required this.meetsAA,
    required this.meetsAAA,
    required this.foreground,
    required this.background,
  });

  String get level {
    if (meetsAAA) return 'AAA ✅';
    if (meetsAA) return 'AA ✅';
    return 'Fail ❌';
  }

  @override
  String toString() {
    return 'Contrast: ${ratio.toStringAsFixed(2)}:1 ($level)';
  }
}

/// Extension para facilitar el uso en el código
extension ColorContrastX on Color {
  /// Calcula el contraste con otro color
  double contrastWith(Color other) {
    return ContrastUtils.getContrastRatio(this, other);
  }

  /// Verifica si cumple WCAG AA con otro color
  bool isAccessibleOn(Color background) {
    return ContrastUtils.meetsWcagAA(this, background);
  }

  /// Ajusta el alpha para tener buen contraste
  Color withAccessibleAlphaOn(Color background, {double minRatio = 4.5}) {
    return ContrastUtils.adjustAlphaForContrast(
      foreground: this,
      background: background,
      minRatio: minRatio,
    );
  }
}
