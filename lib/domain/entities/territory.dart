class Territory {
  final String id;
  final Map<String, dynamic>? unionGeoJson;
  final double totalAreaM2;
  final double lastAreaGainM2;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Territory({
    required this.id,
    this.unionGeoJson,
    this.totalAreaM2 = 0,
    this.lastAreaGainM2 = 0,
    this.createdAt,
    this.updatedAt,
  });

  Territory copyWith({
    Map<String, dynamic>? unionGeoJson,
    double? totalAreaM2,
    double? lastAreaGainM2,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Territory(
      id: id,
      unionGeoJson: unionGeoJson ?? this.unionGeoJson,
      totalAreaM2: totalAreaM2 ?? this.totalAreaM2,
      lastAreaGainM2: lastAreaGainM2 ?? this.lastAreaGainM2,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Territory.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      return null;
    }

    return Territory(
      id: id,
      unionGeoJson: map['unionGeoJson'] as Map<String, dynamic>?,
      totalAreaM2: (map['totalAreaM2'] as num?)?.toDouble() ?? 0.0,
      lastAreaGainM2: (map['lastAreaGainM2'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toPersistenceMap() {
    return {
      if (unionGeoJson != null) 'unionGeoJson': unionGeoJson,
      'totalAreaM2': totalAreaM2,
      'lastAreaGainM2': lastAreaGainM2,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
