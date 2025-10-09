import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as gpa;

/// Utilidades para manejar polylines encoded
class PolylineUtils {
  /// Codificar lista de puntos en polyline encoded
  static String encodePolyline(List<LatLng> points) {
    if (points.isEmpty) return '';
    final coordinates = points.map((p) => [p.latitude, p.longitude]).toList();
    return gpa.encodePolyline(coordinates);
  }

  /// Decodificar polyline encoded en lista de puntos
  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];
    final coordinates = gpa.decodePolyline(encoded);
  return coordinates
    .map((coord) => LatLng(coord[0].toDouble(), coord[1].toDouble()))
    .toList();
  }

  /// Calcular distancia total de una lista de puntos (km)
  static double calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double totalDistance = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      totalDistance += _haversineDistance(p1, p2);
    }
    return totalDistance / 1000; // Convertir a km
  }

  /// Distancia Haversine entre dos puntos (metros)
  static double _haversineDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // Radio de la Tierra en metros
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLon = _toRadians(p2.longitude - p1.longitude);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(p1.latitude)) * math.cos(_toRadians(p2.latitude)) *
            math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
}