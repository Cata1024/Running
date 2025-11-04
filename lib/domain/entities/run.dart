/// Entidad Run ligera para el sistema de logros
/// Basada en los datos de Firestore
class Run {
  final String id;
  final DateTime startTime;
  final int durationSeconds;
  final double distanceMeters;
  final double avgSpeedKmh;
  final double territoryCovered;
  final bool isClosed;

  const Run({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.avgSpeedKmh,
    this.territoryCovered = 0,
    this.isClosed = true,
  });

  /// Crear desde Map de Firestore
  factory Run.fromMap(String id, Map<String, dynamic> data) {
    return Run(
      id: id,
      startTime: data['startTime'] is DateTime
          ? data['startTime']
          : DateTime.parse(data['startTime'] ?? DateTime.now().toIso8601String()),
      durationSeconds: data['durationSeconds'] ?? 0,
      distanceMeters: (data['distanceMeters'] ?? 0.0).toDouble(),
      avgSpeedKmh: (data['avgSpeedKmh'] ?? 0.0).toDouble(),
      territoryCovered: (data['territoryCovered'] ?? 0.0).toDouble(),
      isClosed: data['isClosed'] ?? true,
    );
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'avgSpeedKmh': avgSpeedKmh,
      'territoryCovered': territoryCovered,
      'isClosed': isClosed,
    };
  }
}
