import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong2;

/// Utilidades geoespaciales compartidas en la app.
class GeoUtils {
  const GeoUtils._();

  /// Calcula la distancia en metros entre dos puntos usando Haversine.
  static double distanceMeters(LatLng a, LatLng b) {
    const distance = latlong2.Distance();
    return distance.as(latlong2.LengthUnit.Meter, _toLatLng2(a), _toLatLng2(b));
  }

  /// Calcula la distancia total (metros) de un conjunto ordenado de puntos.
  static double pathLengthMeters(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (var i = 1; i < points.length; i++) {
      total += distanceMeters(points[i - 1], points[i]);
    }
    return total;
  }

  /// Calcula velocidad (m/s) dados distancia (m) y duración (s).
  static double speedMetersPerSecond(double meters, int seconds) {
    if (seconds <= 0) return 0;
    return meters / seconds;
  }

  /// Calcula ritmo en segundos por kilómetro.
  static int paceSecondsPerKm(double speedMetersPerSecond) {
    if (speedMetersPerSecond <= 0) return 0;
    return (1000 / speedMetersPerSecond).round();
  }

  /// Detecta desplazamientos sospechosos ("teleports") midiendo velocidad instantánea.
  static bool isTeleport(LatLng from, LatLng to, int elapsedMs,
      {double thresholdMetersPerSecond = 20}) {
    if (elapsedMs <= 0) return false;
    final meters = distanceMeters(from, to);
    final speed = meters / (elapsedMs / 1000);
    return speed > thresholdMetersPerSecond;
  }

  /// Simplifica una ruta usando Douglas-Peucker.
  static List<LatLng> simplify(List<LatLng> points, double epsilon) {
    if (points.length < 3) return List.unmodifiable(points);
    return List.unmodifiable(_douglasPeucker(points, epsilon));
  }

  /// Codifica una lista de puntos a polyline.
  static String encodePolyline(List<LatLng> points) {
    if (points.isEmpty) return '';
    final encoded = _encode(points);
    return encoded;
  }

  /// Decodifica un polyline a lista de puntos.
  static List<LatLng> decodePolyline(String polyline) {
    if (polyline.isEmpty) return const [];
    return _decode(polyline);
  }

  static latlong2.LatLng _toLatLng2(LatLng point) =>
      latlong2.LatLng(point.latitude, point.longitude);

  static List<LatLng> _douglasPeucker(List<LatLng> points, double epsilon) {
    if (points.length < 3) return points;

    double maxDistance = 0;
    int index = 0;
    final start = points.first;
    final end = points.last;

    for (var i = 1; i < points.length - 1; i++) {
      final d = _perpendicularDistance(points[i], start, end);
      if (d > maxDistance) {
        index = i;
        maxDistance = d;
      }
    }

    if (maxDistance > epsilon) {
      final firstHalf = _douglasPeucker(points.sublist(0, index + 1), epsilon);
      final secondHalf = _douglasPeucker(points.sublist(index), epsilon);
      return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
    } else {
      return [start, end];
    }
  }

  static double _perpendicularDistance(LatLng point, LatLng start, LatLng end) {
    final A = point.latitude - start.latitude;
    final B = point.longitude - start.longitude;
    final C = end.latitude - start.latitude;
    final D = end.longitude - start.longitude;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) {
      return distanceMeters(point, start);
    }

    final param = dot / lenSq;
    late final LatLng closest;

    if (param < 0) {
      closest = start;
    } else if (param > 1) {
      closest = end;
    } else {
      closest = LatLng(start.latitude + param * C, start.longitude + param * D);
    }

    return distanceMeters(point, closest);
  }

  static String _encode(List<LatLng> points) {
    var lastLat = 0;
    var lastLng = 0;
    final result = StringBuffer();

    for (final point in points) {
      final lat = _coordinateToSigned(point.latitude);
      final lng = _coordinateToSigned(point.longitude);

      final deltaLat = lat - lastLat;
      final deltaLng = lng - lastLng;

      _encodeValue(deltaLat, result);
      _encodeValue(deltaLng, result);

      lastLat = lat;
      lastLng = lng;
    }

    return result.toString();
  }

  static List<LatLng> _decode(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      final latResult = _decodeValue(encoded, index);
      index = latResult.nextIndex;
      lat += latResult.delta;

      final lngResult = _decodeValue(encoded, index);
      index = lngResult.nextIndex;
      lng += lngResult.delta;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  static int _coordinateToSigned(double coordinate) =>
      (coordinate * 1e5).round();

  static void _encodeValue(int value, StringBuffer buffer) {
    var v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  static _DecodeResult _decodeValue(String encoded, int index) {
    var result = 0;
    var shift = 0;
    var byte = 0;

    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    final delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    return _DecodeResult(delta: delta, nextIndex: index);
  }
}

class _DecodeResult {
  final int delta;
  final int nextIndex;

  const _DecodeResult({required this.delta, required this.nextIndex});
}
