class RunDto {
  final String? id;
  final String? userId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int distanceM;
  final int durationS;
  final double? avgPaceSecPerKm;
  final bool? isClosedCircuit;
  final double? startLat;
  final double? startLon;
  final double? endLat;
  final double? endLon;
  final Map<String, dynamic>? routeGeoJson;
  final Map<String, dynamic>? polygonGeoJson;
  final double? areaGainedM2;
  final String? summaryPolyline;
  final String? polyline;
  final Map<String, dynamic>? simplification;
  final Map<String, dynamic>? metrics;
  final Map<String, dynamic>? conditions;
  final Map<String, dynamic>? storage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RunDto({
    this.id,
    this.userId,
    required this.startedAt,
    required this.endedAt,
    required this.distanceM,
    required this.durationS,
    this.avgPaceSecPerKm,
    this.isClosedCircuit,
    this.startLat,
    this.startLon,
    this.endLat,
    this.endLon,
    this.routeGeoJson,
    this.polygonGeoJson,
    this.areaGainedM2,
    this.summaryPolyline,
    this.polyline,
    this.simplification,
    this.metrics,
    this.conditions,
    this.storage,
    this.createdAt,
    this.updatedAt,
  });

  factory RunDto.fromMap(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return null;
    }

    return RunDto(
      id: json['id']?.toString(),
      userId: json['userId']?.toString(),
      startedAt: parseDate(json['startedAt']) ?? DateTime.now(),
      endedAt: parseDate(json['endedAt']) ?? DateTime.now(),
      distanceM: (json['distanceM'] as num?)?.round() ?? 0,
      durationS: (json['durationS'] as num?)?.round() ?? 0,
      avgPaceSecPerKm: (json['avgPaceSecPerKm'] as num?)?.toDouble(),
      isClosedCircuit: json['isClosedCircuit'] as bool?,
      startLat: (json['startLat'] as num?)?.toDouble(),
      startLon: (json['startLon'] as num?)?.toDouble(),
      endLat: (json['endLat'] as num?)?.toDouble(),
      endLon: (json['endLon'] as num?)?.toDouble(),
      routeGeoJson: json['routeGeoJson'] as Map<String, dynamic>?,
      polygonGeoJson: json['polygonGeoJson'] as Map<String, dynamic>?,
      areaGainedM2: (json['areaGainedM2'] as num?)?.toDouble(),
      summaryPolyline: json['summaryPolyline'] as String?,
      polyline: json['polyline'] as String?,
      simplification: json['simplification'] as Map<String, dynamic>?,
      metrics: json['metrics'] as Map<String, dynamic>?,
      conditions: json['conditions'] as Map<String, dynamic>?,
      storage: json['storage'] as Map<String, dynamic>?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (userId != null) 'userId': userId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'distanceM': distanceM,
      'durationS': durationS,
      if (avgPaceSecPerKm != null) 'avgPaceSecPerKm': avgPaceSecPerKm,
      if (isClosedCircuit != null) 'isClosedCircuit': isClosedCircuit,
      if (startLat != null) 'startLat': startLat,
      if (startLon != null) 'startLon': startLon,
      if (endLat != null) 'endLat': endLat,
      if (endLon != null) 'endLon': endLon,
      if (routeGeoJson != null) 'routeGeoJson': routeGeoJson,
      if (polygonGeoJson != null) 'polygonGeoJson': polygonGeoJson,
      if (areaGainedM2 != null) 'areaGainedM2': areaGainedM2,
      if (summaryPolyline != null) 'summaryPolyline': summaryPolyline,
      if (polyline != null) 'polyline': polyline,
      if (simplification != null) 'simplification': simplification,
      if (metrics != null) 'metrics': metrics,
      if (conditions != null) 'conditions': conditions,
      if (storage != null) 'storage': storage,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'synced': true,
    };
    return map;
  }
}
