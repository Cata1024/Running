class RunCalculations {
  static double calculateSpeedKmh(double distanceKm, Duration duration) {
    if (duration.inSeconds == 0) return 0.0;
    return distanceKm / (duration.inSeconds / 3600);
  }

  static String formatSpeed(double speedKmh) {
    return speedKmh.toStringAsFixed(1);
  }

  static double calculatePaceSecPerKm(double distanceKm, Duration duration) {
    if (distanceKm == 0) return 0.0;
    return duration.inSeconds / distanceKm;
  }

  static String formatPace(double paceSecPerKm) {
    if (paceSecPerKm == 0) return '-:--';
    final minutes = (paceSecPerKm ~/ 60);
    final seconds = (paceSecPerKm % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
