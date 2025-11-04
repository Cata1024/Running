import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Marcador con efecto pulsante animado
class PulsingMarker extends StatefulWidget {
  final Color color;
  final double size;
  final Widget? child;
  final Duration duration;

  const PulsingMarker({
    super.key,
    this.color = Colors.blue,
    this.size = 40,
    this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulso animado
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: _opacityAnimation.value),
                  ),
                ),
              );
            },
          ),
          // Marcador central
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.child ??
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: widget.size * 0.6,
                ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter para marcador pulsante
class PulsingMarkerPainter extends CustomPainter {
  final Color color;
  final double progress;

  PulsingMarkerPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Pulso exterior
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: (1.0 - progress) * 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius * (1.0 + progress),
      pulsePaint,
    );

    // Marcador principal
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.8, markerPaint);

    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * 0.8, borderPaint);
  }

  @override
  bool shouldRepaint(PulsingMarkerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Helper para animaciones suaves de cámara
class MapCameraAnimator {
  final GoogleMapController controller;
  final Duration defaultDuration;

  MapCameraAnimator({
    required this.controller,
    this.defaultDuration = const Duration(milliseconds: 800),
  });

  /// Animar a una posición específica
  Future<void> animateTo({
    required LatLng target,
    double? zoom,
    double? bearing,
    double? tilt,
    Duration? duration,
  }) async {
    final cameraUpdate = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: target,
        zoom: zoom ?? 15.0,
        bearing: bearing ?? 0.0,
        tilt: tilt ?? 0.0,
      ),
    );

    await controller.animateCamera(cameraUpdate);
  }

  /// Animar a bounds para mostrar múltiples puntos
  Future<void> animateToBounds({
    required LatLngBounds bounds,
    double padding = 50,
    Duration? duration,
  }) async {
    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, padding);
    await controller.animateCamera(cameraUpdate);
  }

  /// Animar zoom in/out
  Future<void> zoomTo(double zoom) async {
    final cameraUpdate = CameraUpdate.zoomTo(zoom);
    await controller.animateCamera(cameraUpdate);
  }

  /// Animar zoom in incremental
  Future<void> zoomIn() async {
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  /// Animar zoom out incremental
  Future<void> zoomOut() async {
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  /// Calcular bounds desde lista de puntos
  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
      throw ArgumentError('Cannot compute bounds of empty list');
    }

    double? minLat, maxLat, minLng, maxLng;

    for (final point in list) {
      if (minLat == null || point.latitude < minLat) {
        minLat = point.latitude;
      }
      if (maxLat == null || point.latitude > maxLat) {
        maxLat = point.latitude;
      }
      if (minLng == null || point.longitude < minLng) {
        minLng = point.longitude;
      }
      if (maxLng == null || point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}

/// Widget para animar el dibujado de polyline
class AnimatedPolylineDrawer extends StatefulWidget {
  final List<LatLng> points;
  final Color color;
  final double width;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedPolylineDrawer({
    super.key,
    required this.points,
    this.color = Colors.blue,
    this.width = 5,
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  @override
  State<AnimatedPolylineDrawer> createState() => _AnimatedPolylineDrawerState();
}

class _AnimatedPolylineDrawerState extends State<AnimatedPolylineDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  List<LatLng> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ))..addListener(_updatePoints);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  void _updatePoints() {
    if (!mounted) return;

    final progress = _progressAnimation.value;
    final totalPoints = widget.points.length;
    final pointsToShow = (totalPoints * progress).round();

    setState(() {
      _currentPoints = widget.points.take(pointsToShow).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPoints.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: PolylinePainter(
        points: _currentPoints,
        color: widget.color,
        width: widget.width,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Painter para polyline
class PolylinePainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;
  final double width;

  PolylinePainter({
    required this.points,
    required this.color,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Convertir lat/lng a coordenadas de canvas
    // (esto es simplificado, en uso real necesitarías proyección adecuada)
    final firstPoint = _latLngToOffset(points.first, size);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < points.length; i++) {
      final point = _latLngToOffset(points[i], size);
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  Offset _latLngToOffset(LatLng latLng, Size size) {
    // Proyección simple (Mercator simplificado)
    // En producción usarías las coordenadas de screen del mapa
    final x = (latLng.longitude + 180) / 360 * size.width;
    final y = (90 - latLng.latitude) / 180 * size.height;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(PolylinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.width != width;
  }
}

/// Widget para mostrar progreso de carrera con animación
class RunProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 a 1.0
  final Color color;
  final double height;

  const RunProgressIndicator({
    super.key,
    required this.progress,
    this.color = Colors.blue,
    this.height = 4,
  });

  @override
  State<RunProgressIndicator> createState() => _RunProgressIndicatorState();
}

class _RunProgressIndicatorState extends State<RunProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: RunProgressPainter(
          progress: widget.progress,
          color: widget.color,
          shimmerProgress: _shimmerController.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class RunProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double shimmerProgress;

  RunProgressPainter({
    required this.progress,
    required this.color,
    required this.shimmerProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.height / 2),
      ),
      backgroundPaint,
    );

    // Progreso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * progress, size.height),
        Radius.circular(size.height / 2),
      ),
      progressPaint,
    );

    // Shimmer effect
    if (progress > 0 && progress < 1) {
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromLTWH(
            size.width * progress * shimmerProgress,
            0,
            size.width * 0.3,
            size.height,
          ),
        );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width * progress, size.height),
          Radius.circular(size.height / 2),
        ),
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RunProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shimmerProgress != shimmerProgress;
  }
}
