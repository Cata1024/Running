/// Sistema de diseño Territory Run
/// 
/// Todos los tokens de diseño centralizados para mantener consistencia.
/// Incluye espaciado, colores, tipografía, animaciones y helpers responsive.
/// 
/// Uso:
/// ```dart
/// import 'package:running/core/design_system/territory_tokens.dart';
/// 
/// // Valores legacy (compatibilidad)
/// SizedBox(height: TerritoryTokens.space16)
/// 
/// // Breakpoints responsive
/// if (width > TerritoryTokens.breakpoints.tablet) { ... }
/// 
/// // Helpers
/// final isMobile = TerritoryTokens.isMobile(context);
/// ```
library;

import 'package:flutter/material.dart';

class TerritoryTokens {
  TerritoryTokens._(); // Constructor privado

  // ============================================================================
  // SPACING (Valores legacy - mantener para compatibilidad)
  // ============================================================================
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;
  static const double space64 = 64;

  // ============================================================================
  // BORDER RADIUS (Valores legacy - mantener para compatibilidad)
  // ============================================================================
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusPill = 9999;

  // ============================================================================
  // BLUR LEVELS (Valores legacy - mantener para compatibilidad)
  // ============================================================================
  static const double blurNone = 0;
  static const double blurSubtle = 4;
  static const double blurMedium = 8;
  static const double blurStrong = 16;

  // ============================================================================
  // OPACITY LEVELS (Mejorados para WCAG AA)
  // ============================================================================
  /// Opacidades mejoradas para mejor contraste (WCAG AA compliant)
  static const double opacityGhost = 0.08;    // Aumentado de 0.03 para mejor visibilidad
  static const double opacitySubtle = 0.12;   // Aumentado de 0.08
  static const double opacityMedium = 0.18;   // Aumentado de 0.15
  static const double opacityStrong = 0.28;   // Aumentado de 0.25
  static const double opacityIntense = 0.40;  // Nuevo nivel para mayor contraste

  // ============================================================================
  // BORDERS (Valores legacy - mantener para compatibilidad)
  // ============================================================================
  static const double borderNone = 0;
  static const double borderHairline = 0.5;
  static const double borderThin = 1.0;

  // ============================================================================
  // ANIMATION DURATIONS (Valores legacy - mantener para compatibilidad)
  // ============================================================================
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ============================================================================
  // RESPONSIVE BREAKPOINTS (NUEVO)
  // ============================================================================
  /// Breakpoints para diseño responsive
  static const breakpoints = (
    /// 0-599px - Móviles
    mobile: 0,
    /// 600-1023px - Tablets
    tablet: 600,
    /// 1024-1439px - Desktop
    desktop: 1024,
    /// 1440px+ - Pantallas grandes
    wide: 1440,
  );

  // ============================================================================
  // PADDING (NUEVO)
  // ============================================================================
  /// Presets de padding comunes
  static const padding = (
    xs: EdgeInsets.all(4.0),
    sm: EdgeInsets.all(8.0),
    md: EdgeInsets.all(16.0),
    lg: EdgeInsets.all(24.0),
    xl: EdgeInsets.all(32.0),
  );

  // ============================================================================
  // TAP TARGETS (NUEVO - Accesibilidad)
  // ============================================================================
  /// Tamaños mínimos para elementos táctiles (accesibilidad)
  static const tapTarget = (
    /// 44x44 - Mínimo iOS
    minimum: 44.0,
    /// 48x48 - Recomendado Material Design
    recommended: 48.0,
    /// 56x56 - Cómodo
    comfortable: 56.0,
    /// 64x64 - Grande
    large: 64.0,
  );

  // ============================================================================
  // ICON SIZES (NUEVO)
  // ============================================================================
  static const iconSize = (
    xs: 16.0,
    sm: 20.0,
    md: 24.0,
    lg: 32.0,
    xl: 40.0,
    xxl: 48.0,
  );

  // ============================================================================
  // Z-INDEX (NUEVO)
  // ============================================================================
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

  // ============================================================================
  // SHADOWS (Funciones)
  // ============================================================================
  
  /// Sombra sutil de 2 capas
  static List<BoxShadow> shadowSubtle(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra media de 2 capas
  static List<BoxShadow> shadowMedium(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Sistema de elevación con niveles (0-4)
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
        return shadowSubtle(shadowColor);
      case 3:
        return shadowMedium(shadowColor);
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

  // ============================================================================
  // RESPONSIVE HELPERS
  // ============================================================================
  
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

  /// Obtiene padding adaptativo según el breakpoint
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(24);
    if (isTablet(context)) return const EdgeInsets.all(16);
    return const EdgeInsets.all(8);
  }

  /// Obtiene el número de columnas para grids según breakpoint
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 12;
    if (isTablet(context)) return 8;
    return 4;
  }
}
