import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';

/// Widget para construir interfaces responsive de manera declarativa.
/// 
/// Ejemplo de uso:
/// ```dart
/// ResponsiveBuilder(
///   mobile: MobileLayout(),
///   tablet: TabletLayout(),
///   desktop: DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// Widget para dispositivos móviles (< 600px)
  final Widget mobile;
  
  /// Widget para tablets (600px - 1023px)
  final Widget? tablet;
  
  /// Widget para desktop (1024px - 1439px)
  final Widget? desktop;
  
  /// Widget para pantallas anchas (>= 1440px)
  final Widget? wide;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Wide screens
        if (width >= TerritoryTokens.breakpoints.wide && wide != null) {
          return wide!;
        }
        
        // Desktop
        if (width >= TerritoryTokens.breakpoints.desktop && desktop != null) {
          return desktop!;
        }
        
        // Tablet
        if (width >= TerritoryTokens.breakpoints.tablet && tablet != null) {
          return tablet!;
        }
        
        // Mobile (default)
        return mobile;
      },
    );
  }
}

/// Widget que oculta o muestra contenido según el breakpoint
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool hiddenOnMobile;
  final bool hiddenOnTablet;
  final bool hiddenOnDesktop;
  final bool hiddenOnWide;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.hiddenOnMobile = false,
    this.hiddenOnTablet = false,
    this.hiddenOnDesktop = false,
    this.hiddenOnWide = false,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = TerritoryTokens.getCurrentBreakpoint(context);
    bool shouldHide = false;

    switch (breakpoint) {
      case 'mobile':
        shouldHide = hiddenOnMobile;
        break;
      case 'tablet':
        shouldHide = hiddenOnTablet;
        break;
      case 'desktop':
        shouldHide = hiddenOnDesktop;
        break;
      case 'wide':
        shouldHide = hiddenOnWide;
        break;
    }

    if (shouldHide) {
      return replacement ?? const SizedBox.shrink();
    }
    
    return child;
  }
}

/// Grid responsive que adapta columnas según el tamaño de pantalla
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? wideColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.wideColumns,
  });

  int _getColumns(BuildContext context) {
    final breakpoint = TerritoryTokens.getCurrentBreakpoint(context);
    
    switch (breakpoint) {
      case 'mobile':
        return mobileColumns ?? 1;
      case 'tablet':
        return tabletColumns ?? 2;
      case 'desktop':
        return desktopColumns ?? 3;
      case 'wide':
        return wideColumns ?? 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = _getColumns(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Padding responsive que se adapta al tamaño de pantalla
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;
  final EdgeInsets? wide;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  EdgeInsets _getPadding(BuildContext context) {
    final breakpoint = TerritoryTokens.getCurrentBreakpoint(context);
    
    switch (breakpoint) {
      case 'mobile':
        return mobile ?? TerritoryTokens.padding.sm;
      case 'tablet':
        return tablet ?? TerritoryTokens.padding.md;
      case 'desktop':
        return desktop ?? TerritoryTokens.padding.lg;
      case 'wide':
        return wide ?? TerritoryTokens.padding.xl;
      default:
        return TerritoryTokens.padding.sm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _getPadding(context),
      child: child,
    );
  }
}

/// Contenedor con ancho máximo responsive
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;
  final double? wideMaxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobileMaxWidth,
    this.tabletMaxWidth,
    this.desktopMaxWidth,
    this.wideMaxWidth,
    this.padding,
  });

  double? _getMaxWidth(BuildContext context) {
    final breakpoint = TerritoryTokens.getCurrentBreakpoint(context);
    
    switch (breakpoint) {
      case 'mobile':
        return mobileMaxWidth ?? double.infinity;
      case 'tablet':
        return tabletMaxWidth ?? 720;
      case 'desktop':
        return desktopMaxWidth ?? 1200;
      case 'wide':
        return wideMaxWidth ?? 1440;
      default:
        return double.infinity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: _getMaxWidth(context) ?? double.infinity),
        padding: padding ?? TerritoryTokens.getAdaptivePadding(context),
        child: child,
      ),
    );
  }
}

/// Helpers para valores responsive
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? wide;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  T getValue(BuildContext context) {
    final breakpoint = TerritoryTokens.getCurrentBreakpoint(context);
    
    switch (breakpoint) {
      case 'wide':
        return wide ?? desktop ?? tablet ?? mobile;
      case 'desktop':
        return desktop ?? tablet ?? mobile;
      case 'tablet':
        return tablet ?? mobile;
      case 'mobile':
      default:
        return mobile;
    }
  }
}

/// Extension para facilitar el uso de responsive values
extension ResponsiveContext on BuildContext {
  /// Obtiene un valor responsive según el breakpoint actual
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
  }) {
    final value = ResponsiveValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      wide: wide,
    );
    return value.getValue(this);
  }

  /// Verifica si estamos en modo mobile
  bool get isMobile => TerritoryTokens.isMobile(this);

  /// Verifica si estamos en modo tablet
  bool get isTablet => TerritoryTokens.isTablet(this);

  /// Verifica si estamos en modo desktop
  bool get isDesktop => TerritoryTokens.isDesktop(this);

  /// Obtiene el breakpoint actual
  String get breakpoint => TerritoryTokens.getCurrentBreakpoint(this);
}
