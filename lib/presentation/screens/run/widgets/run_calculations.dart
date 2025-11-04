/// Utilidades para cálculos de running (pace, speed, etc.)
class RunCalculations {
  const RunCalculations._();

  /// Calcula el pace en segundos por kilómetro
  static double? calculatePaceSecPerKm(double totalKm, Duration elapsed) {
    if (totalKm <= 0 || elapsed.inSeconds <= 0) return null;
    return elapsed.inSeconds / totalKm;
  }

  /// Formatea el pace como string (mm:ss)
  static String formatPace(double? paceSecPerKm) {
    if (paceSecPerKm == null || paceSecPerKm <= 0 || !paceSecPerKm.isFinite) {
      return '--:--';
    }
    final minutes = paceSecPerKm ~/ 60;
    final seconds = (paceSecPerKm % 60).round();
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Calcula velocidad en km/h
  static double? calculateSpeedKmh(double totalKm, Duration elapsed) {
    if (totalKm <= 0 || elapsed.inSeconds <= 0) return null;
    final distanceMeters = totalKm * 1000;
    final speed = (distanceMeters / elapsed.inSeconds) * 3.6;
    return speed.isFinite ? speed : null;
  }

  /// Formatea la velocidad como string
  static String formatSpeed(double? speedKmh) {
    if (speedKmh == null || speedKmh <= 0 || !speedKmh.isFinite) {
      return '--';
    }
    return speedKmh.toStringAsFixed(1);
  }

  /// Formatea duración como HH:MM:SS o MM:SS
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatea distancia en km con decimales apropiados
  static String formatDistance(double km) {
    if (km < 0.01) return '0.00';
    if (km < 10) return km.toStringAsFixed(2);
    return km.toStringAsFixed(1);
  }
}
