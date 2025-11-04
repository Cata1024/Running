import 'package:flutter/material.dart';

/// Helpers para animaciones reutilizables en toda la app
class AnimationHelpers {
  // Duraciones estándar
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  // Curvas estándar
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  
  /// Animación de escala con rebote
  static Widget scaleIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = bounceCurve,
    double initialScale = 0.8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: initialScale, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Animación de fade in
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Animación de slide desde abajo
  static Widget slideUp({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double initialOffset = 0.2,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: Offset(0, initialOffset), end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value.dy * 50),
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Animación combinada: fade + slide
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double initialOffset = 0.1,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * initialOffset * 50),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  /// Animación de shimmer mejorada
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Loop infinito
      },
    );
  }
  
  /// Pulso sutil para elementos interactivos
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.98,
    double maxScale = 1.02,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Loop infinito alternando
      },
    );
  }
}

/// Widget para stagger animations (animaciones escalonadas)
class StaggeredAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final Curve curve;
  final Axis direction;
  
  const StaggeredAnimation({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.itemDuration + (widget.itemDelay * widget.children.length),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.children.length,
        (index) {
          final start = (widget.itemDelay.inMilliseconds * index) /
              _controller.duration!.inMilliseconds;
          final end = start + (widget.itemDuration.inMilliseconds /
              _controller.duration!.inMilliseconds);
          
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
                  curve: widget.curve),
            ),
          );
          
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final offset = widget.direction == Axis.vertical
                  ? Offset(0, (1 - animation.value) * 20)
                  : Offset((1 - animation.value) * 20, 0);
              
              return Opacity(
                opacity: animation.value,
                child: Transform.translate(
                  offset: offset,
                  child: child,
                ),
              );
            },
            child: widget.children[index],
          );
        },
      ),
    );
  }
}

/// Widget para animaciones de conteo (counter)
class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;
  
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '${prefix ?? ''}$value${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

/// Widget para animaciones de progreso circular
class AnimatedProgress extends StatelessWidget {
  final double value;
  final Duration duration;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double size;
  
  const AnimatedProgress({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 600),
    this.color,
    this.backgroundColor,
    this.strokeWidth = 8.0,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ProgressPainter(
              progress: animValue,
              color: progressColor,
              backgroundColor: bgColor,
              strokeWidth: strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  
  _ProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Fondo
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progreso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
