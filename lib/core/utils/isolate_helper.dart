import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper para ejecutar tareas pesadas en isolates
/// Evita bloquear el UI thread
class IsolateHelper {
  IsolateHelper._();

  /// Ejecutar función en isolate separado
  static Future<R> compute<Q, R>(
    ComputeCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) async {
    return await compute(callback, message, debugLabel: debugLabel);
  }
}

/// Procesamiento de tracks en isolate
/// 
/// ⚠️ DEPRECATED: Usar RouteProcessor de route_processor.dart en su lugar
/// RouteProcessor incluye Kalman Filter + pipeline completo
@Deprecated('Usar RouteProcessor de core/services/route_processor.dart')
class TrackProcessor {
  TrackProcessor._();

  /// Simplificar polyline usando algoritmo Visvalingam-Whyatt (más eficiente que Douglas-Peucker)
  /// 
  /// ⚠️ DEPRECATED: Usar RouteProcessor.simplifyVisvalingam() en su lugar
  /// 
  /// Visvalingam-Whyatt es O(n log n) vs Douglas-Peucker O(n²)
  /// Preserva mejor la forma visual de la ruta
  static Future<List<Map<String, double>>> simplifyTrack(
    List<Map<String, double>> points, {
    double minArea = 0.00001, // Área mínima del triángulo
    int? targetPoints, // Número objetivo de puntos (opcional)
  }) async {
    if (points.length <= 2) return points;

    return await compute(_simplifyTrackIsolate, {
      'points': points,
      'minArea': minArea,
      'targetPoints': targetPoints,
    });
  }

  static List<Map<String, double>> _simplifyTrackIsolate(
    Map<String, dynamic> params,
  ) {
    final points = params['points'] as List<Map<String, double>>;
    final minArea = params['minArea'] as double;
    final targetPoints = params['targetPoints'] as int?;

    return _visvalingamWhyatt(points, minArea, targetPoints);
  }

  /// Algoritmo Visvalingam-Whyatt para simplificación de polylines
  /// Más eficiente y preciso que Douglas-Peucker
  /// Ref: https://bost.ocks.org/mike/simplify/
  static List<Map<String, double>> _visvalingamWhyatt(
    List<Map<String, double>> points,
    double minArea,
    int? targetPoints,
  ) {
    if (points.length <= 2) return points;

    // Crear lista de puntos con áreas calculadas
    final pointsWithArea = <_PointWithArea>[];
    
    // Primer y último punto siempre se mantienen
    pointsWithArea.add(_PointWithArea(points[0], double.infinity, 0));
    
    for (int i = 1; i < points.length - 1; i++) {
      final area = _calculateTriangleArea(
        points[i - 1],
        points[i],
        points[i + 1],
      );
      pointsWithArea.add(_PointWithArea(points[i], area, i));
    }
    
    pointsWithArea.add(_PointWithArea(points.last, double.infinity, points.length - 1));

    // Ordenar por área (menor primero)
    final sortedIndices = List<int>.generate(pointsWithArea.length, (i) => i)
      ..sort((a, b) => pointsWithArea[a].area.compareTo(pointsWithArea[b].area));

    // Eliminar puntos hasta alcanzar criterios
    final toRemove = <int>{};
    for (final idx in sortedIndices) {
      if (idx == 0 || idx == pointsWithArea.length - 1) continue;
      
      final point = pointsWithArea[idx];
      
      // Criterio 1: Área mínima
      if (point.area < minArea) {
        toRemove.add(idx);
      }
      
      // Criterio 2: Número objetivo de puntos
      if (targetPoints != null && 
          (pointsWithArea.length - toRemove.length) <= targetPoints) {
        break;
      }
    }

    // Construir resultado sin puntos eliminados
    final result = <Map<String, double>>[];
    for (int i = 0; i < pointsWithArea.length; i++) {
      if (!toRemove.contains(i)) {
        result.add(pointsWithArea[i].point);
      }
    }

    return result;
  }

  /// Calcular área del triángulo formado por 3 puntos
  static double _calculateTriangleArea(
    Map<String, double> p1,
    Map<String, double> p2,
    Map<String, double> p3,
  ) {
    final lat1 = p1['lat']!;
    final lng1 = p1['lng']!;
    final lat2 = p2['lat']!;
    final lng2 = p2['lng']!;
    final lat3 = p3['lat']!;
    final lng3 = p3['lng']!;

    // Fórmula del determinante para área de triángulo
    final area = ((lat1 * (lng2 - lng3) +
                   lat2 * (lng3 - lng1) +
                   lat3 * (lng1 - lng2)) / 2).abs();
    
    return area;
  }

  /// Calcular estadísticas del track (distancia, velocidad, etc.)
  /// 
  /// ⚠️ DEPRECATED: Usar RouteProcessor.processRoute() que incluye stats
  @Deprecated('Usar RouteProcessor de core/services/route_processor.dart')
  static Future<Map<String, dynamic>> calculateTrackStats(
    List<Map<String, double>> points,
  ) async {
    if (points.isEmpty) {
      return {
        'totalDistance': 0.0,
        'avgSpeed': 0.0,
        'maxSpeed': 0.0,
        'elevation': 0.0,
      };
    }

    return await compute(_calculateStatsIsolate, points);
  }

  static Map<String, dynamic> _calculateStatsIsolate(
    List<Map<String, double>> points,
  ) {
    double totalDistance = 0.0;
    double totalElevation = 0.0;
    double maxSpeed = 0.0;
    List<double> speeds = [];

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      // Distancia usando fórmula de Haversine
      final distance = _haversineDistance(
        prev['lat']!,
        prev['lng']!,
        curr['lat']!,
        curr['lng']!,
      );
      totalDistance += distance;

      // Elevación (si está disponible)
      if (prev.containsKey('alt') && curr.containsKey('alt')) {
        final elevDiff = curr['alt']! - prev['alt']!;
        if (elevDiff > 0) {
          totalElevation += elevDiff;
        }
      }

      // Velocidad (si hay timestamp)
      if (prev.containsKey('timestamp') && curr.containsKey('timestamp')) {
        final timeDiff = curr['timestamp']! - prev['timestamp']!;
        if (timeDiff > 0) {
          final speed = distance / timeDiff; // m/s
          speeds.add(speed);
          if (speed > maxSpeed) {
            maxSpeed = speed;
          }
        }
      }
    }

    final avgSpeed = speeds.isNotEmpty
        ? speeds.reduce((a, b) => a + b) / speeds.length
        : 0.0;

    return {
      'totalDistance': totalDistance,
      'avgSpeed': avgSpeed * 3.6, // convertir a km/h
      'maxSpeed': maxSpeed * 3.6,
      'elevation': totalElevation,
      'points': points.length,
    };
  }

  /// Fórmula de Haversine para calcular distancia entre dos puntos
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Radio de la Tierra en metros
    final phi1 = lat1 * 0.017453292519943295; // toRadians
    final phi2 = lat2 * 0.017453292519943295;
    final deltaPhi = (lat2 - lat1) * 0.017453292519943295;
    final deltaLambda = (lon2 - lon1) * 0.017453292519943295;

    final a = _sin(deltaPhi / 2) * _sin(deltaPhi / 2) +
        _cos(phi1) * _cos(phi2) * _sin(deltaLambda / 2) * _sin(deltaLambda / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return R * c;
  }

  // Math helpers (evitar import dart:math en isolate)
  static double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  static double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double _sqrt(double x) {
    if (x == 0) return 0;
    double z = x;
    for (int i = 0; i < 10; i++) {
      z = (z + x / z) / 2;
    }
    return z;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }

  static double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }

  /// Detectar paradas en el track
  /// 
  /// ⚠️ DEPRECATED: Funcionalidad movida a RouteProcessor
  @Deprecated('Usar RouteProcessor de core/services/route_processor.dart')
  static Future<List<Map<String, dynamic>>> detectStops(
    List<Map<String, double>> points, {
    double speedThreshold = 0.5, // m/s
    int minDuration = 30, // segundos
  }) async {
    if (points.isEmpty) return [];

    return await compute(_detectStopsIsolate, {
      'points': points,
      'speedThreshold': speedThreshold,
      'minDuration': minDuration,
    });
  }

  static List<Map<String, dynamic>> _detectStopsIsolate(
    Map<String, dynamic> params,
  ) {
    final points = params['points'] as List<Map<String, double>>;
    final speedThreshold = params['speedThreshold'] as double;
    final minDuration = params['minDuration'] as int;

    final stops = <Map<String, dynamic>>[];
    int stopStart = -1;
    double stopLat = 0;
    double stopLng = 0;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      if (!curr.containsKey('timestamp') || !prev.containsKey('timestamp')) {
        continue;
      }

      final timeDiff = curr['timestamp']! - prev['timestamp']!;
      if (timeDiff == 0) continue;

      final distance = _haversineDistance(
        prev['lat']!,
        prev['lng']!,
        curr['lat']!,
        curr['lng']!,
      );
      final speed = distance / timeDiff;

      if (speed < speedThreshold) {
        if (stopStart == -1) {
          stopStart = i - 1;
          stopLat = prev['lat']!;
          stopLng = prev['lng']!;
        }
      } else {
        if (stopStart != -1) {
          final duration = points[i - 1]['timestamp']! - points[stopStart]['timestamp']!;
          if (duration >= minDuration) {
            stops.add({
              'lat': stopLat,
              'lng': stopLng,
              'duration': duration.toInt(),
              'startIndex': stopStart,
              'endIndex': i - 1,
            });
          }
          stopStart = -1;
        }
      }
    }

    return stops;
  }
}

/// Clase helper para Visvalingam-Whyatt
class _PointWithArea {
  final Map<String, double> point;
  final double area;
  final int originalIndex;

  _PointWithArea(this.point, this.area, this.originalIndex);
}
