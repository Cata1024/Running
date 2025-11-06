class UserProfileDto {
  final String id;
  final String? email;
  final String? displayName;
  final DateTime? createdAt;
  final int? totalRuns;
  final double? totalDistance;
  final int? totalTime;
  final int? level;
  final int? experience;
  final List<String>? achievements;
  final String? photoUrl;
  final DateTime? lastActivityAt;
  final DateTime? birthDate;
  final double? weightKg;
  final int? heightCm;
  final String? gender;
  final String? preferredUnits;
  final String? goalDescription;
  final String? goalType;
  final double? weeklyDistanceGoal;
  final DateTime? updatedAt;

  const UserProfileDto({
    required this.id,
    this.email,
    this.displayName,
    this.createdAt,
    this.totalRuns,
    this.totalDistance,
    this.totalTime,
    this.level,
    this.experience,
    this.achievements,
    this.photoUrl,
    this.lastActivityAt,
    this.birthDate,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.preferredUnits,
    this.goalDescription,
    this.goalType,
    this.weeklyDistanceGoal,
    this.updatedAt,
  });

  factory UserProfileDto.fromMap(String id, Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return null;
    }

    return UserProfileDto(
      id: id,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      createdAt: parseDate(json['createdAt']),
      totalRuns: (json['totalRuns'] as num?)?.toInt(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      totalTime: (json['totalTime'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      experience: (json['experience'] as num?)?.toInt(),
      achievements: (json['achievements'] as List?)?.whereType<String>().toList(),
      photoUrl: json['photoUrl'] as String?,
      lastActivityAt: parseDate(json['lastActivityAt']),
      birthDate: parseDate(json['birthDate']),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      preferredUnits: json['preferredUnits'] as String?,
      goalDescription: json['goalDescription'] as String?,
      goalType: json['goalType'] as String?,
      weeklyDistanceGoal: (json['weeklyDistanceGoal'] as num?)?.toDouble(),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    DateTime? d(DateTime? d) => d;
    return {
      'email': email,
      'displayName': displayName,
      if (createdAt != null) 'createdAt': d(createdAt)!.toIso8601String(),
      if (totalRuns != null) 'totalRuns': totalRuns,
      if (totalDistance != null) 'totalDistance': totalDistance,
      if (totalTime != null) 'totalTime': totalTime,
      if (level != null) 'level': level,
      if (experience != null) 'experience': experience,
      if (achievements != null) 'achievements': achievements,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (lastActivityAt != null) 'lastActivityAt': d(lastActivityAt)!.toIso8601String(),
      if (birthDate != null) 'birthDate': d(birthDate)!.toIso8601String(),
      if (weightKg != null) 'weightKg': weightKg,
      if (heightCm != null) 'heightCm': heightCm,
      if (gender != null) 'gender': gender,
      if (preferredUnits != null) 'preferredUnits': preferredUnits,
      if (goalDescription != null) 'goalDescription': goalDescription,
      if (goalType != null) 'goalType': goalType,
      if (weeklyDistanceGoal != null) 'weeklyDistanceGoal': weeklyDistanceGoal,
      if (updatedAt != null) 'updatedAt': d(updatedAt)!.toIso8601String(),
    }..removeWhere((k, v) => v == null);
  }
}
