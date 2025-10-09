import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modelo de carrera para Territory Run
class RunModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LatLng> route;
  final double distance; // en kilómetros
  final int duration; // en segundos
  final double averageSpeed; // km/h
  final double maxSpeed; // km/h
  final double averagePace; // min/km
  final int calories;
  final List<TerritoryPoint> capturedTerritory;
  final double? territoryArea; // metros cuadrados
  final List<LatLng>? territoryPolygon;
  final Map<String, dynamic>? metadata;
  final bool synced;
  final DateTime createdAt;

  const RunModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.route = const [],
    this.distance = 0.0,
    this.duration = 0,
    this.averageSpeed = 0.0,
    this.maxSpeed = 0.0,
    this.averagePace = 0.0,
    this.calories = 0,
    this.capturedTerritory = const [],
    this.territoryArea,
    this.territoryPolygon,
    this.metadata,
    this.synced = false,
    required this.createdAt,
  });

  /// Crear desde mapa (Firestore)
  factory RunModel.fromMap(Map<String, dynamic> map, String id) {
    return RunModel(
      id: id,
      userId: map['userId'] ?? '',
      startTime: map['startTime'] is String
          ? DateTime.parse(map['startTime'])
          : DateTime.fromMillisecondsSinceEpoch(
              map['startTime']?.millisecondsSinceEpoch ?? 0),
      endTime: map['endTime'] != null
          ? (map['endTime'] is String
              ? DateTime.parse(map['endTime'])
              : DateTime.fromMillisecondsSinceEpoch(
                  map['endTime'].millisecondsSinceEpoch))
          : null,
      route: (map['route'] as List<dynamic>? ?? [])
          .map((point) => LatLng(
                point['latitude']?.toDouble() ?? 0.0,
                point['longitude']?.toDouble() ?? 0.0,
              ))
          .toList(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      duration: map['duration'] ?? 0,
      averageSpeed: (map['averageSpeed'] ?? 0.0).toDouble(),
      maxSpeed: (map['maxSpeed'] ?? 0.0).toDouble(),
      averagePace: (map['averagePace'] ?? 0.0).toDouble(),
      calories: map['calories'] ?? 0,
      capturedTerritory: (map['capturedTerritory'] as List<dynamic>? ?? [])
          .map((territory) => TerritoryPoint.fromMap(territory))
          .toList(),
      territoryArea: (map['territoryArea'] as num?)?.toDouble(),
      territoryPolygon: (map['territoryPolygon'] as List<dynamic>? ?? [])
          .map((point) => LatLng(
                point['latitude']?.toDouble() ?? 0.0,
                point['longitude']?.toDouble() ?? 0.0,
              ))
          .toList(),
      metadata: map['metadata'],
      synced: map['synced'] ?? false,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(
              map['createdAt']?.millisecondsSinceEpoch ?? 0),
    );
  }

  /// Crear copia con cambios
  RunModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    List<LatLng>? route,
    double? distance,
    int? duration,
    double? averageSpeed,
    double? maxSpeed,
    double? averagePace,
    int? calories,
    List<TerritoryPoint>? capturedTerritory,
    double? territoryArea,
    List<LatLng>? territoryPolygon,
    Map<String, dynamic>? metadata,
    bool? synced,
    DateTime? createdAt,
  }) {
    return RunModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      route: route ?? this.route,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      averagePace: averagePace ?? this.averagePace,
      calories: calories ?? this.calories,
      capturedTerritory: capturedTerritory ?? this.capturedTerritory,
      territoryArea: territoryArea ?? this.territoryArea,
      territoryPolygon: territoryPolygon ?? this.territoryPolygon,
      metadata: metadata ?? this.metadata,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Verificar si la carrera está completa
  bool get isCompleted => endTime != null;

  /// Obtener duración formateada
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Convertir a mapa (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'route': route
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'distance': distance,
      'duration': duration,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'averagePace': averagePace,
      'calories': calories,
      'capturedTerritory': capturedTerritory.map((t) => t.toMap()).toList(),
      if (territoryArea != null) 'territoryArea': territoryArea,
      if (territoryPolygon != null)
        'territoryPolygon': territoryPolygon!
            .map((point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                })
            .toList(),
      'metadata': metadata,
      'synced': synced,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Obtener ritmo formateado
  String get formattedPace {
    if (averagePace == 0.0) return '--:--';
    
    final minutes = averagePace.floor();
    final seconds = ((averagePace - minutes) * 60).round();
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Obtener experiencia ganada en esta carrera
  int get experienceGained {
    // XP basado en distancia (100 XP por km) + duración (1 XP por minuto)
    return (distance * 100 + duration / 60).round();
  }

  @override
  String toString() {
    return 'RunModel(id: $id, distance: ${distance.toStringAsFixed(1)}km, '
           'duration: $formattedDuration, date: ${startTime.toLocal()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RunModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Punto de territorio capturado
class TerritoryPoint {
  final LatLng position;
  final double radius; // en metros
  final DateTime capturedAt;
  final String? landmark; // nombre del lugar si está disponible

  const TerritoryPoint({
    required this.position,
    required this.radius,
    required this.capturedAt,
    this.landmark,
  });

  factory TerritoryPoint.fromMap(Map<String, dynamic> map) {
    return TerritoryPoint(
      position: LatLng(
        map['latitude']?.toDouble() ?? 0.0,
        map['longitude']?.toDouble() ?? 0.0,
      ),
      radius: (map['radius'] ?? 50.0).toDouble(),
      capturedAt: map['capturedAt'] is String
          ? DateTime.parse(map['capturedAt'])
          : DateTime.fromMillisecondsSinceEpoch(
              map['capturedAt']?.millisecondsSinceEpoch ?? 0),
      landmark: map['landmark'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'radius': radius,
      'capturedAt': capturedAt.toIso8601String(),
      'landmark': landmark,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TerritoryPoint && 
           other.position == position && 
           other.capturedAt == capturedAt;
  }

  @override
  int get hashCode => Object.hash(position, capturedAt);
}