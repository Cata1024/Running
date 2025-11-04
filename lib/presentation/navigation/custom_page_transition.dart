import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tipos de transición disponibles
enum PageTransitionType {
  fade,
  slide,
  scale,
  rotation,
  fadeScale,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  sharedAxis,
  fadeThrough,
}

/// Custom page transition builder para GoRouter
/// 
/// Uso:
/// ```dart
/// GoRoute(
///   path: '/profile',
///   pageBuilder: (context, state) => CustomPageTransition(
///     key: state.pageKey,
///     child: ProfileScreen(),
///     type: PageTransitionType.slideLeft,
///   ).build(context, state),
/// )
/// ```
class CustomPageTransition {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;
  final Alignment? alignment;
  final Axis? axis;
  final LocalKey? key;

  const CustomPageTransition({
    required this.child,
    this.type = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alignment,
    this.axis,
    this.key,
  });

  /// Construir la página con la transición
  Page<void> build(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: key ?? state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case PageTransitionType.slide:
      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: curvedAnimation,
          alignment: alignment ?? Alignment.center,
          child: child,
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation),
          alignment: alignment ?? Alignment.center,
          child: child,
        );

      case PageTransitionType.fadeScale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );

      case PageTransitionType.sharedAxis:
        return _SharedAxisTransition(
          animation: curvedAnimation,
          secondaryAnimation: secondaryAnimation,
          axis: axis ?? Axis.horizontal,
          child: child,
        );

      case PageTransitionType.fadeThrough:
        return _FadeThroughTransition(
          animation: curvedAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
    }
  }
}

/// Shared Axis Transition (Material Design 3)
/// La pantalla saliente se desvanece mientras se desliza,
/// la entrante aparece con fade y deslizamiento en dirección opuesta
class _SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final Axis axis;

  const _SharedAxisTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    // Entrada: fade + slide desde 30% offset
    final incomingOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    final incomingOffset = axis == Axis.horizontal
        ? Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ))
        : Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

    // Salida: fade + slide hacia -30% offset
    final outgoingOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    final outgoingOffset = axis == Axis.horizontal
        ? Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.3, 0.0),
          ).animate(CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOut,
          ))
        : Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0.0, -0.3),
          ).animate(CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOut,
          ));

    return SlideTransition(
      position: secondaryAnimation.status == AnimationStatus.completed
          ? incomingOffset
          : outgoingOffset,
      child: FadeTransition(
        opacity: secondaryAnimation.status == AnimationStatus.completed
            ? incomingOpacity
            : outgoingOpacity,
        child: child,
      ),
    );
  }
}

/// Fade Through Transition (Material Design 3)
/// La pantalla actual se desvanece completamente antes de que aparezca la nueva
class _FadeThroughTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _FadeThroughTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Entrada: fade in desde 50% en adelante
    final incomingOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    // Salida: fade out hasta 50%
    final outgoingOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    // Escala sutil
    final scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    return FadeTransition(
      opacity: secondaryAnimation.status == AnimationStatus.completed
          ? incomingOpacity
          : outgoingOpacity,
      child: ScaleTransition(
        scale: scale,
        child: child,
      ),
    );
  }
}

/// Helper para crear transiciones rápidas en MaterialPageRoute
class PageTransitionHelper {
  PageTransitionHelper._();

  /// Crear un PageRouteBuilder con transición personalizada
  static PageRouteBuilder<T> createRoute<T>({
    required Widget child,
    PageTransitionType type = PageTransitionType.fadeScale,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CustomPageTransition(
          child: child,
          type: type,
          duration: duration,
          curve: curve,
        )._buildTransition(context, animation, secondaryAnimation, child);
      },
    );
  }

  /// Navegación con transición personalizada
  static Future<T?> push<T>(
    BuildContext context, {
    required Widget child,
    PageTransitionType type = PageTransitionType.fadeScale,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.of(context).push<T>(
      createRoute<T>(
        child: child,
        type: type,
        duration: duration,
      ),
    );
  }

  /// Reemplazar ruta actual con transición
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context, {
    required Widget child,
    PageTransitionType type = PageTransitionType.fadeScale,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      createRoute<T>(
        child: child,
        type: type,
        duration: duration,
      ),
    );
  }
}
