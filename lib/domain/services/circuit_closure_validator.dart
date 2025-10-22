import '../track_processing/track_processing.dart';
import 'package:geolocator/geolocator.dart';
class CircuitClosureValidator {
  const CircuitClosureValidator();

  bool isClosedCircuit({
    required List<TrackPoint> routePoints,
    required Duration duration,
    double thresholdMeters = 50.0,
    Duration minDuration = const Duration(minutes: 5),
  }) {
    if (routePoints.length < 2) return false;
    if (duration < minDuration) return false;
    final start = routePoints.first;
    final end = routePoints.last;
    final distance = Geolocator.distanceBetween(
      start.lat,
      start.lon,
      end.lat,
      end.lon,
    );
    return distance <= thresholdMeters;
  }
}
