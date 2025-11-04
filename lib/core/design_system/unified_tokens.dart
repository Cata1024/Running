/// ⚠️ DEPRECATED - Este archivo ha sido fusionado con territory_tokens.dart
/// 
/// Por favor, usa TerritoryTokens en su lugar:
/// 
/// ```dart
/// // ANTES:
/// import 'package:running/core/design_system/unified_tokens.dart';
/// DesignTokens.breakpoints.tablet
/// 
/// // AHORA:
/// import 'package:running/core/design_system/territory_tokens.dart';
/// TerritoryTokens.breakpoints.tablet
/// ```
/// 
/// Este archivo será eliminado en una futura versión.
library;

import 'package:flutter/material.dart';

@Deprecated('Usa TerritoryTokens en su lugar. Este archivo será eliminado.')
class DesignTokens {
  DesignTokens._();

  // ============ SPACING ============
  /// Sistema de espaciado basado en múltiplos de 4
  static const spacing = (
    /// 4px - Espaciado mínimo
    xs: 4.0,
    /// 8px - Espaciado pequeño
    sm: 8.0,
    /// 12px - Espaciado pequeño-mediano
    smd: 12.0,
    /// 16px - Espaciado mediano (default)
    md: 16.0,
    /// 20px - Espaciado mediano-grande
    mdl: 20.0,
    /// 24px - Espaciado grande
    lg: 24.0,
    /// 32px - Espaciado extra grande
    xl: 32.0,
    /// 48px - Espaciado 2x extra grande
    xxl: 48.0,
    /// 64px - Espaciado 3x extra grande
    xxxl: 64.0,
  );

  // ============ PADDING ============
  static const padding = (
    xs: EdgeInsets.all(4.0),
    sm: EdgeInsets.all(8.0),
    md: EdgeInsets.all(16.0),
    lg: EdgeInsets.all(24.0),
    xl: EdgeInsets.all(32.0),
  );

  // ============ RADIUS ============
  /// Border radius consistentes
  static const radius = (
    /// 4px - Radio mínimo
    xs: 4.0,
    /// 8px - Radio pequeño
    sm: 8.0,
    /// 12px - Radio mediano
    md: 12.0,
    /// 16px - Radio grande
    lg: 16.0,
    /// 24px - Radio extra grande
    xl: 24.0,
    /// 32px - Radio 2x extra grande
    xxl: 32.0,
    /// 999px - Radio completo (pill shape)
    full: 999.0,
  );

  // ============ BREAKPOINTS ============
  /// Responsive breakpoints
  static const breakpoints = (
    /// 0-599px
    mobile: 0,
    /// 600-1023px
    tablet: 600,
    /// 1024-1439px
    desktop: 1024,
    /// 1440px+
    wide: 1440,
  );

  // ============ BLUR LEVELS ============
  /// Niveles de blur para efectos glassmorphism
  static const blur = (
    none: 0.0,
    subtle: 4.0,
    medium: 8.0,
    strong: 16.0,
    intense: 24.0,
  );

  // ============ OPACITY LEVELS ============
  /// Niveles de opacidad para superficies
  static const opacity = (
    /// 3% - Casi invisible
    ghost: 0.03,
    /// 8% - Muy sutil
    subtle: 0.08,
    /// 15% - Mediano
    medium: 0.15,
    /// 25% - Fuerte
    strong: 0.25,
    /// 40% - Muy fuerte
    intense: 0.40,
    /// 60% - Semi-opaco
    semiOpaque: 0.60,
    /// 80% - Casi opaco
    mostlyOpaque: 0.80,
  );

  // ============ BORDERS ============
  static const border = (
    none: 0.0,
    hairline: 0.5,
    thin: 1.0,
    medium: 2.0,
    thick: 3.0,
  );

  // ============ ANIMATIONS ============
  static const duration = (
    /// 100ms - Instantáneo
    instant: Duration(milliseconds: 100),
    /// 150ms - Muy rápido
    fast: Duration(milliseconds: 150),
    /// 250ms - Normal
    normal: Duration(milliseconds: 250),
    /// 400ms - Lento
    slow: Duration(milliseconds: 400),
    /// 600ms - Muy lento
    verySlow: Duration(milliseconds: 600),
  );

  // ============ ELEVATION (SHADOWS) ============
  static List<BoxShadow> elevation({
    required int level,
    Color? color,
  }) {
    final shadowColor = color ?? Colors.black;
    
    switch (level) {
      case 0:
        return [];
      case 1:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      default:
        return elevation(level: 2, color: color);
    }
  }

  // ============ TYPOGRAPHY SCALE ============
  static const typography = (
    /// Display - Para títulos muy grandes
    displayLarge: 57.0,
    displayMedium: 45.0,
    displaySmall: 36.0,
    
    /// Headline - Para títulos de sección
    headlineLarge: 32.0,
    headlineMedium: 28.0,
    headlineSmall: 24.0,
    
    /// Title - Para títulos de componentes
    titleLarge: 20.0,
    titleMedium: 16.0,
    titleSmall: 14.0,
    
    /// Body - Para texto de contenido
    bodyLarge: 16.0,
    bodyMedium: 14.0,
    bodySmall: 12.0,
    
    /// Label - Para etiquetas y botones
    labelLarge: 14.0,
    labelMedium: 12.0,
    labelSmall: 11.0,
  );

  // ============ ICON SIZES ============
  static const iconSize = (
    xs: 16.0,
    sm: 20.0,
    md: 24.0,
    lg: 32.0,
    xl: 40.0,
    xxl: 48.0,
  );

  // ============ TAP TARGET SIZES ============
  /// Tamaños mínimos para elementos interactivos (accesibilidad)
  static const tapTarget = (
    /// 44x44 - iOS minimum
    minimum: 44.0,
    /// 48x48 - Material Design recommended
    recommended: 48.0,
    /// 56x56 - Comfortable
    comfortable: 56.0,
    /// 64x64 - Large
    large: 64.0,
  );

  // ============ Z-INDEX ============
  static const zIndex = (
    background: -1,
    base: 0,
    dropdown: 1000,
    sticky: 1100,
    modal: 1200,
    popover: 1300,
    tooltip: 1400,
    notification: 1500,
  );

  // ============ HELPERS ============
  
  /// Determina el breakpoint actual
  static String getCurrentBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= breakpoints.wide) return 'wide';
    if (width >= breakpoints.desktop) return 'desktop';
    if (width >= breakpoints.tablet) return 'tablet';
    return 'mobile';
  }

  /// Verifica si estamos en mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpoints.tablet;
  }

  /// Verifica si estamos en tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpoints.tablet && width < breakpoints.desktop;
  }

  /// Verifica si estamos en desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpoints.desktop;
  }

  /// Obtiene el padding adaptativo según el breakpoint
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isDesktop(context)) return padding.lg;
    if (isTablet(context)) return padding.md;
    return padding.sm;
  }

  /// Obtiene el número de columnas para grids
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 12;
    if (isTablet(context)) return 8;
    return 4;
  }
}
