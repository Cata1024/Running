class TerritoryDto {
  final String id; // uid
  final Map<String, dynamic>? unionGeoJson;
  final double? totalAreaM2;
  final double? lastAreaGainM2;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TerritoryDto({
    required this.id,
    this.unionGeoJson,
    this.totalAreaM2,
    this.lastAreaGainM2,
    this.createdAt,
    this.updatedAt,
  });

  factory TerritoryDto.fromMap(String id, Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return null;
    }

    return TerritoryDto(
      id: id,
      unionGeoJson: json['unionGeoJson'] as Map<String, dynamic>?,
      totalAreaM2: (json['totalAreaM2'] as num?)?.toDouble(),
      lastAreaGainM2: (json['lastAreaGainM2'] as num?)?.toDouble(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (unionGeoJson != null) 'unionGeoJson': unionGeoJson,
      if (totalAreaM2 != null) 'totalAreaM2': totalAreaM2,
      if (lastAreaGainM2 != null) 'lastAreaGainM2': lastAreaGainM2,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    }..removeWhere((k, v) => v == null);
  }
}
