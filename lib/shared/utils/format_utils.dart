class FormatUtils {
  const FormatUtils._();

  /// Convierte una duración a formato legible HH:MM:SS o MM:SS.
  static String duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatea una duración representada en segundos.
  static String durationFromSeconds(int seconds) {
    return duration(Duration(seconds: seconds));
  }

  /// Formatea el ritmo en minutos por kilómetro.
  static String paceMinutesPerKm(double pace) {
    if (pace <= 0 || pace.isNaN || pace.isInfinite) {
      return '--:--';
    }

    final totalSeconds = (pace * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatea la distancia en kilómetros con el número de decimales indicado.
  static String distanceKm(double kilometers, {int fractionDigits = 2}) {
    if (kilometers.isNaN || kilometers.isInfinite) {
      return '-- km';
    }
    return '${kilometers.toStringAsFixed(fractionDigits)} km';
  }

  /// Formatea velocidad en km/h.
  static String speedKmPerHour(double speed, {int fractionDigits = 1}) {
    if (speed <= 0 || speed.isNaN || speed.isInfinite) {
      return '-- km/h';
    }
    return '${speed.toStringAsFixed(fractionDigits)} km/h';
  }
}
