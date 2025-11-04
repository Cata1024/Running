import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 🎯 Pipeline completo de procesamiento de rutas GPS
/// Similar a Strava, Nike Run Club, Garmin Connect
/// 
/// Flujo: GPS Raw → Kalman Filter → Visvalingam-Whyatt → Douglas-Peucker → Catmull-Rom Spline → Polyline Encoding
/// 
/// Uso:
/// ```dart
/// final processor = RouteProcessor();
/// final result = await processor.processRoute(
///   rawPoints: gpsPoints,
///   config: RouteProcessingConfig(),
/// );
/// 
/// // Usar en mapa
/// Polyline(
///   points: result.smoothedPoints,
///   color: Colors.blue,
///   width: 5,
/// )
/// ```
class RouteProcessor {
  RouteProcessor();

  /// Procesar ruta completa con pipeline optimizado
  Future<RouteProcessingResult> processRoute({
    required List<LatLng> rawPoints,
    RouteProcessingConfig config = const RouteProcessingConfig(),
  }) async {
    if (rawPoints.isEmpty) {
      return RouteProcessingResult.empty();
    }

    // PASO 1: Filtro Kalman para eliminar ruido GPS
    final filteredPoints = config.useKalmanFilter
        ? kalmanFilter(rawPoints, processNoise: config.kalmanProcessNoise)
        : rawPoints;

    // PASO 2: Simplificación Visvalingam-Whyatt (preserva forma)
    final visvalingamPoints = config.useVisvalingam
        ? simplifyVisvalingam(
            filteredPoints,
            minArea: config.visvalingamTolerance,
          )
        : filteredPoints;

    // PASO 3: Douglas-Peucker para reducción final de puntos
    final douglasPoints = config.useDouglasPeucker
        ? simplifyDouglasPeucker(
            visvalingamPoints,
            tolerance: config.douglasPeuckerTolerance,
          )
        : visvalingamPoints;

    // PASO 4: Suavizado Catmull-Rom Spline para curvas elegantes
    final smoothedPoints = config.useSplineSmoothing
        ? smoothCatmullRom(
            douglasPoints,
            segments: config.splineSegments,
            tension: config.splineTension,
          )
        : douglasPoints;

    // PASO 5: Codificar en Google Polyline format para almacenamiento
    final encoded = encodePolyline(douglasPoints);

    // Calcular estadísticas
    final stats = _calculateStats(rawPoints, smoothedPoints);

    return RouteProcessingResult(
      rawPoints: rawPoints,
      filteredPoints: filteredPoints,
      simplifiedPoints: douglasPoints,
      smoothedPoints: smoothedPoints,
      encodedPolyline: encoded,
      stats: stats,
    );
  }

  /// 🔬 PASO 1: Filtro Kalman para reducción de ruido GPS
  /// 
  /// El GPS tiene error típico de ±5-10 metros. El filtro Kalman usa un modelo
  /// de predicción + corrección para estimar la posición real.
  /// 
  /// Ref: https://en.wikipedia.org/wiki/Kalman_filter
  List<LatLng> kalmanFilter(
    List<LatLng> points, {
    double processNoise = 0.5,
    double measurementNoise = 5.0,
  }) {
    if (points.length < 2) return points;

    final filtered = <LatLng>[points.first];
    
    // Estado inicial: [lat, lng, velocidad_lat, velocidad_lng]
    var stateLat = points.first.latitude;
    var stateLng = points.first.longitude;
    var velocityLat = 0.0;
    var velocityLng = 0.0;
    
    // Covarianza inicial
    var errorLat = 1.0;
    var errorLng = 1.0;

    for (int i = 1; i < points.length; i++) {
      final point = points[i];
      
      // PREDICCIÓN: Estimar posición basándose en velocidad
      final predictedLat = stateLat + velocityLat;
      final predictedLng = stateLng + velocityLng;
      final predictedErrorLat = errorLat + processNoise;
      final predictedErrorLng = errorLng + processNoise;

      // CORRECCIÓN: Actualizar con medición real
      final kalmanGainLat = predictedErrorLat / (predictedErrorLat + measurementNoise);
      final kalmanGainLng = predictedErrorLng / (predictedErrorLng + measurementNoise);

      stateLat = predictedLat + kalmanGainLat * (point.latitude - predictedLat);
      stateLng = predictedLng + kalmanGainLng * (point.longitude - predictedLng);
      
      errorLat = (1 - kalmanGainLat) * predictedErrorLat;
      errorLng = (1 - kalmanGainLng) * predictedErrorLng;

      // Actualizar velocidad
      velocityLat = stateLat - filtered.last.latitude;
      velocityLng = stateLng - filtered.last.longitude;

      filtered.add(LatLng(stateLat, stateLng));
    }

    return filtered;
  }

  /// 📐 PASO 2: Visvalingam-Whyatt - Simplificación preservando forma
  /// 
  /// Elimina puntos que forman triángulos pequeños (menos "importantes" visualmente)
  /// Más eficiente que Douglas-Peucker: O(n log n) vs O(n²)
  /// 
  /// Ref: https://bost.ocks.org/mike/simplify/
  List<LatLng> simplifyVisvalingam(
    List<LatLng> points, {
    double minArea = 0.00001,
  }) {
    if (points.length <= 2) return points;

    // Calcular área efectiva de cada punto
    final pointsWithArea = <_PointWithArea>[];
    
    pointsWithArea.add(_PointWithArea(points[0], double.infinity, 0));
    
    for (int i = 1; i < points.length - 1; i++) {
      final area = _triangleArea(points[i - 1], points[i], points[i + 1]);
      pointsWithArea.add(_PointWithArea(points[i], area, i));
    }
    
    pointsWithArea.add(_PointWithArea(points.last, double.infinity, points.length - 1));

    // Eliminar puntos con área menor al umbral
    final result = <LatLng>[];
    for (final p in pointsWithArea) {
      if (p.area >= minArea || p.index == 0 || p.index == points.length - 1) {
        result.add(p.point);
      }
    }

    return result;
  }

  /// 🔺 PASO 3: Douglas-Peucker - Reducción agresiva de puntos
  /// 
  /// Algoritmo clásico que mantiene puntos "alejados" de la línea recta
  /// Ideal como segundo paso después de Visvalingam
  /// 
  /// Tolerancia recomendada: 1-2 metros para rutas urbanas
  List<LatLng> simplifyDouglasPeucker(
    List<LatLng> points, {
    double tolerance = 0.00001, // ~1 metro en grados
  }) {
    if (points.length <= 2) return points;

    double maxDistance = 0;
    int maxIndex = 0;

    final start = points.first;
    final end = points.last;

    // Encontrar punto más alejado de la línea start-end
    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // Recursión si el punto está suficientemente lejos
    if (maxDistance > tolerance) {
      final left = simplifyDouglasPeucker(
        points.sublist(0, maxIndex + 1),
        tolerance: tolerance,
      );
      final right = simplifyDouglasPeucker(
        points.sublist(maxIndex),
        tolerance: tolerance,
      );

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [start, end];
    }
  }

  /// 🌊 PASO 4: Catmull-Rom Spline - Suavizado elegante de curvas
  /// 
  /// Genera curvas suaves que pasan por todos los puntos
  /// Usado en Adobe Illustrator, After Effects, etc.
  /// 
  /// Ref: https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
  List<LatLng> smoothCatmullRom(
    List<LatLng> points, {
    int segments = 10,
    double tension = 0.5, // 0 = uniform, 0.5 = centripetal, 1.0 = chordal
  }) {
    if (points.length < 2) return points;
    if (points.length == 2) return points;

    final smoothed = <LatLng>[];

    // Añadir punto de control al inicio (duplicate first)
    final controlPoints = [points[0], ...points, points[points.length - 1]];

    // Generar segmentos interpolados entre cada par de puntos
    for (int i = 1; i < controlPoints.length - 2; i++) {
      final p0 = controlPoints[i - 1];
      final p1 = controlPoints[i];
      final p2 = controlPoints[i + 1];
      final p3 = controlPoints[i + 2];

      // Distancias para spline centripetal
      final t0 = 0.0;
      final t1 = t0 + _alpha(p0, p1, tension);
      final t2 = t1 + _alpha(p1, p2, tension);
      final t3 = t2 + _alpha(p2, p3, tension);

      // Interpolar 'segments' puntos entre p1 y p2
      for (int j = 0; j < segments; j++) {
        final t = t1 + (t2 - t1) * (j / segments);

        final lat = _catmullRomInterpolate(
          t, t0, t1, t2, t3,
          p0.latitude, p1.latitude, p2.latitude, p3.latitude,
        );

        final lng = _catmullRomInterpolate(
          t, t0, t1, t2, t3,
          p0.longitude, p1.longitude, p2.longitude, p3.longitude,
        );

        smoothed.add(LatLng(lat, lng));
      }
    }

    // Añadir último punto
    smoothed.add(points.last);

    return smoothed;
  }

  /// 📦 PASO 5: Google Polyline Encoding
  /// 
  /// Codifica lista de coordenadas en string compacto
  /// Reduce tamaño ~60-70% vs JSON
  /// 
  /// Ref: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  String encodePolyline(List<LatLng> points, {int precision = 5}) {
    if (points.isEmpty) return '';

    final buffer = StringBuffer();
    int lastLat = 0;
    int lastLng = 0;

    for (final point in points) {
      final lat = (point.latitude * math.pow(10, precision)).round();
      final lng = (point.longitude * math.pow(10, precision)).round();

      final dLat = lat - lastLat;
      final dLng = lng - lastLng;

      buffer.write(_encodeValue(dLat));
      buffer.write(_encodeValue(dLng));

      lastLat = lat;
      lastLng = lng;
    }

    return buffer.toString();
  }

  /// 📖 Decodificar Google Polyline a coordenadas
  List<LatLng> decodePolyline(String encoded, {int precision = 5}) {
    if (encoded.isEmpty) return [];

    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int byte;

      // Decodificar latitud
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      result = 0;
      shift = 0;

      // Decodificar longitud
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      points.add(LatLng(
        lat / math.pow(10, precision),
        lng / math.pow(10, precision),
      ));
    }

    return points;
  }

  // ============================================================================
  // 🛠️ MÉTODOS AUXILIARES
  // ============================================================================

  /// Calcular área del triángulo (Visvalingam)
  double _triangleArea(LatLng p1, LatLng p2, LatLng p3) {
    return ((p1.latitude * (p2.longitude - p3.longitude) +
                p2.latitude * (p3.longitude - p1.longitude) +
                p3.latitude * (p1.longitude - p2.longitude)) / 2)
        .abs();
  }

  /// Distancia perpendicular punto-línea (Douglas-Peucker)
  double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final area = _triangleArea(point, lineStart, lineEnd);
    final base = _distance(lineStart, lineEnd);
    return base > 0 ? (2 * area / base) : 0;
  }

  /// Distancia euclidiana entre dos puntos
  double _distance(LatLng p1, LatLng p2) {
    final dx = p2.latitude - p1.latitude;
    final dy = p2.longitude - p1.longitude;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Factor alpha para Catmull-Rom centripetal
  double _alpha(LatLng p0, LatLng p1, double tension) {
    return math.pow(_distance(p0, p1), tension).toDouble();
  }

  /// Interpolación Catmull-Rom
  double _catmullRomInterpolate(
    double t,
    double t0,
    double t1,
    double t2,
    double t3,
    double p0,
    double p1,
    double p2,
    double p3,
  ) {
    if (t2 - t1 == 0) return p1;

    final a1 = (t1 - t) / (t1 - t0) * p0 + (t - t0) / (t1 - t0) * p1;
    final a2 = (t2 - t) / (t2 - t1) * p1 + (t - t1) / (t2 - t1) * p2;
    final a3 = (t3 - t) / (t3 - t2) * p2 + (t - t2) / (t3 - t2) * p3;

    final b1 = (t2 - t) / (t2 - t0) * a1 + (t - t0) / (t2 - t0) * a2;
    final b2 = (t3 - t) / (t3 - t1) * a2 + (t - t1) / (t3 - t1) * a3;

    return (t2 - t) / (t2 - t1) * b1 + (t - t1) / (t2 - t1) * b2;
  }

  /// Codificar valor para polyline
  String _encodeValue(int value) {
    var encoded = '';
    var val = value < 0 ? ~(value << 1) : (value << 1);

    while (val >= 0x20) {
      encoded += String.fromCharCode((0x20 | (val & 0x1f)) + 63);
      val >>= 5;
    }

    encoded += String.fromCharCode(val + 63);
    return encoded;
  }

  /// Calcular estadísticas de procesamiento
  RouteStats _calculateStats(List<LatLng> original, List<LatLng> processed) {
    final reductionRate = original.isEmpty
        ? 0.0
        : (1 - (processed.length / original.length)) * 100;

    return RouteStats(
      originalPoints: original.length,
      processedPoints: processed.length,
      reductionRate: reductionRate,
    );
  }
}

// ============================================================================
// 📦 CLASES DE CONFIGURACIÓN Y RESULTADO
// ============================================================================

/// Configuración del pipeline de procesamiento
class RouteProcessingConfig {
  /// Usar filtro Kalman para ruido GPS
  final bool useKalmanFilter;
  final double kalmanProcessNoise;
  
  /// Usar Visvalingam-Whyatt para simplificación
  final bool useVisvalingam;
  final double visvalingamTolerance;
  
  /// Usar Douglas-Peucker para reducción final
  final bool useDouglasPeucker;
  final double douglasPeuckerTolerance;
  
  /// Usar Catmull-Rom para suavizado
  final bool useSplineSmoothing;
  final int splineSegments;
  final double splineTension;

  const RouteProcessingConfig({
    this.useKalmanFilter = true,
    this.kalmanProcessNoise = 0.5,
    this.useVisvalingam = true,
    this.visvalingamTolerance = 0.00001,
    this.useDouglasPeucker = true,
    this.douglasPeuckerTolerance = 0.00001, // ~1 metro
    this.useSplineSmoothing = true,
    this.splineSegments = 10,
    this.splineTension = 0.5, // Centripetal
  });

  /// Configuración agresiva (máxima compresión)
  const RouteProcessingConfig.aggressive()
      : useKalmanFilter = true,
        kalmanProcessNoise = 1.0,
        useVisvalingam = true,
        visvalingamTolerance = 0.0001,
        useDouglasPeucker = true,
        douglasPeuckerTolerance = 0.0001,
        useSplineSmoothing = true,
        splineSegments = 8,
        splineTension = 0.5;

  /// Configuración suave (máxima calidad)
  const RouteProcessingConfig.smooth()
      : useKalmanFilter = true,
        kalmanProcessNoise = 0.3,
        useVisvalingam = true,
        visvalingamTolerance = 0.000005,
        useDouglasPeucker = false,
        douglasPeuckerTolerance = 0.0,
        useSplineSmoothing = true,
        splineSegments = 15,
        splineTension = 0.5;

  /// Solo almacenamiento (sin suavizado visual)
  const RouteProcessingConfig.storage()
      : useKalmanFilter = true,
        kalmanProcessNoise = 0.5,
        useVisvalingam = true,
        visvalingamTolerance = 0.00005,
        useDouglasPeucker = true,
        douglasPeuckerTolerance = 0.00002,
        useSplineSmoothing = false,
        splineSegments = 0,
        splineTension = 0.0;
}

/// Resultado del procesamiento
class RouteProcessingResult {
  final List<LatLng> rawPoints;
  final List<LatLng> filteredPoints;
  final List<LatLng> simplifiedPoints;
  final List<LatLng> smoothedPoints;
  final String encodedPolyline;
  final RouteStats stats;

  RouteProcessingResult({
    required this.rawPoints,
    required this.filteredPoints,
    required this.simplifiedPoints,
    required this.smoothedPoints,
    required this.encodedPolyline,
    required this.stats,
  });

  factory RouteProcessingResult.empty() {
    return RouteProcessingResult(
      rawPoints: [],
      filteredPoints: [],
      simplifiedPoints: [],
      smoothedPoints: [],
      encodedPolyline: '',
      stats: RouteStats(
        originalPoints: 0,
        processedPoints: 0,
        reductionRate: 0,
      ),
    );
  }
}

/// Estadísticas de procesamiento
class RouteStats {
  final int originalPoints;
  final int processedPoints;
  final double reductionRate;

  RouteStats({
    required this.originalPoints,
    required this.processedPoints,
    required this.reductionRate,
  });

  @override
  String toString() {
    return 'RouteStats(original: $originalPoints, processed: $processedPoints, reduction: ${reductionRate.toStringAsFixed(1)}%)';
  }
}

/// Helper class para Visvalingam
class _PointWithArea {
  final LatLng point;
  final double area;
  final int index;

  _PointWithArea(this.point, this.area, this.index);
}

// ============================================================================
// 🎨 WIDGET DE RENDERIZADO CON GRADIENTE
// ============================================================================

/// Widget para pintar ruta con gradiente de velocidad/ritmo
/// 
/// Uso:
/// ```dart
/// CustomPaint(
///   painter: GradientRoutePainter(
///     points: result.smoothedPoints,
///     speeds: speedData,
///     minSpeed: 0,
///     maxSpeed: 15,
///   ),
/// )
/// ```
class GradientRoutePainter extends CustomPainter {
  final List<LatLng> points;
  final List<double>? speeds; // km/h o min/km
  final double minSpeed;
  final double maxSpeed;
  final double strokeWidth;
  final List<Color> gradientColors;

  GradientRoutePainter({
    required this.points,
    this.speeds,
    this.minSpeed = 0,
    this.maxSpeed = 15,
    this.strokeWidth = 5,
    this.gradientColors = const [
      Color(0xFF00FF00), // Verde (rápido)
      Color(0xFFFFFF00), // Amarillo
      Color(0xFFFFA500), // Naranja
      Color(0xFFFF0000), // Rojo (lento)
    ],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Convertir LatLng a Offset (simplificado, usar proyección real en producción)
    final offsets = points.map((p) {
      final x = ((p.longitude + 180) / 360) * size.width;
      final y = ((90 - p.latitude) / 180) * size.height;
      return Offset(x, y);
    }).toList();

    // Dibujar segmentos con colores según velocidad
    for (int i = 0; i < offsets.length - 1; i++) {
      final color = speeds != null && i < speeds!.length
          ? _getColorForSpeed(speeds![i])
          : gradientColors.first;

      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(offsets[i], offsets[i + 1], paint);
    }
  }

  Color _getColorForSpeed(double speed) {
    final normalized = ((speed - minSpeed) / (maxSpeed - minSpeed)).clamp(0.0, 1.0);
    final index = (normalized * (gradientColors.length - 1)).floor();
    
    if (index >= gradientColors.length - 1) {
      return gradientColors.last;
    }

    final localT = (normalized * (gradientColors.length - 1)) - index;
    return Color.lerp(gradientColors[index], gradientColors[index + 1], localT)!;
  }

  @override
  bool shouldRepaint(GradientRoutePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.speeds != speeds ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ============================================================================
// 📱 EJEMPLO DE INTEGRACIÓN EN GOOGLE MAPS
// ============================================================================

/// Helper para crear Polyline con ruta procesada
class RoutePolylineHelper {
  /// Crear polyline básica
  static Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color color = Colors.blue,
    double width = 5,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width.toInt(),
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
  }

  /// Crear polyline con gradiente de velocidad
  static Set<Polyline> createGradientPolylines({
    required String baseId,
    required List<LatLng> points,
    required List<double> speeds,
    double minSpeed = 0,
    double maxSpeed = 15,
    double width = 5,
  }) {
    final polylines = <Polyline>{};

    final colors = _generateGradientColors(speeds, minSpeed, maxSpeed);

    for (int i = 0; i < points.length - 1; i++) {
      polylines.add(Polyline(
        polylineId: PolylineId('${baseId}_segment_$i'),
        points: [points[i], points[i + 1]],
        color: colors[i],
        width: width.toInt(),
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));
    }

    return polylines;
  }

  static List<Color> _generateGradientColors(
    List<double> speeds,
    double minSpeed,
    double maxSpeed,
  ) {
    const gradientColors = [
      Color(0xFF00FF00), // Verde
      Color(0xFFFFFF00), // Amarillo
      Color(0xFFFFA500), // Naranja
      Color(0xFFFF0000), // Rojo
    ];

    return speeds.map((speed) {
      final normalized = ((speed - minSpeed) / (maxSpeed - minSpeed)).clamp(0.0, 1.0);
      final index = (normalized * (gradientColors.length - 1)).floor().clamp(0, gradientColors.length - 2);
      final localT = (normalized * (gradientColors.length - 1)) - index;
      return Color.lerp(gradientColors[index], gradientColors[index + 1], localT)!;
    }).toList();
  }
}
