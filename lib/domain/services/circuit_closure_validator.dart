import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CircuitClosureValidator {
  const CircuitClosureValidator();

  bool isClosedCircuit({
    required List<LatLng> routePoints,
    required Duration duration,
    double thresholdMeters = 50.0,
    Duration minDuration = const Duration(minutes: 5),
  }) {
    if (routePoints.length < 2) return false;
    if (duration < minDuration) return false;
    final start = routePoints.first;
    final end = routePoints.last;
    final d = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return d <= thresholdMeters;
  }
}
