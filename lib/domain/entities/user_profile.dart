/// Entidad de perfil de usuario optimizada
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final int totalRuns;
  final double totalDistance;
  final int totalTime;
  final int level;
  final int experience;
  final List<String> achievements;
  final String? photoUrl;
  final DateTime? lastActivityAt;
  final DateTime? birthDate;
  final double? weightKg;
  final int? heightCm;
  final String? gender;
  final String preferredUnits;
  final String? goalDescription;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.totalRuns = 0,
    this.totalDistance = 0.0,
    this.totalTime = 0,
    this.level = 1,
    this.experience = 0,
    this.achievements = const [],
    this.photoUrl,
    this.lastActivityAt,
    this.birthDate,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.preferredUnits = 'metric',
    this.goalDescription,
  });

  /// Constructor desde JSON (REST API)
  factory UserProfile.fromJson(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Runner',
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      totalRuns: data['totalRuns'] ?? 0,
      totalDistance: (data['totalDistance'] ?? 0.0).toDouble(),
      totalTime: data['totalTime'] ?? 0,
      level: data['level'] ?? 1,
      experience: data['experience'] ?? 0,
      achievements: List<String>.from(data['achievements'] ?? []),
      photoUrl: data['photoUrl'],
      lastActivityAt: _parseDate(data['lastActivityAt']),
      birthDate: _parseDate(data['birthDate']),
      weightKg: data['weightKg']?.toDouble(),
      heightCm: data['heightCm']?.round(),
      gender: data['gender'],
      preferredUnits: data['preferredUnits'] ?? 'metric',
      goalDescription: data['goalDescription'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'totalRuns': totalRuns,
      'totalDistance': totalDistance,
      'totalTime': totalTime,
      'level': level,
      'experience': experience,
      'achievements': achievements,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (lastActivityAt != null) 
        'lastActivityAt': lastActivityAt!.toIso8601String(),
      if (birthDate != null) 
        'birthDate': birthDate!.toIso8601String(),
      if (weightKg != null) 'weightKg': weightKg,
      if (heightCm != null) 'heightCm': heightCm,
      if (gender != null) 'gender': gender,
      'preferredUnits': preferredUnits,
      if (goalDescription != null) 'goalDescription': goalDescription,
    };
  }

  /// Constructor con copia modificada
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    int? totalRuns,
    double? totalDistance,
    int? totalTime,
    int? level,
    int? experience,
    List<String>? achievements,
    String? photoUrl,
    DateTime? lastActivityAt,
    DateTime? birthDate,
    double? weightKg,
    int? heightCm,
    String? gender,
    String? preferredUnits,
    String? goalDescription,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      totalRuns: totalRuns ?? this.totalRuns,
      totalDistance: totalDistance ?? this.totalDistance,
      totalTime: totalTime ?? this.totalTime,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      achievements: achievements ?? this.achievements,
      photoUrl: photoUrl ?? this.photoUrl,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      goalDescription: goalDescription ?? this.goalDescription,
    );
  }

  // Getters calculados optimizados
  double get averagePace {
    if (totalDistance == 0 || totalTime == 0) return 0.0;
    return totalTime / 60 / totalDistance; // minutos por km
  }

  double get averageSpeed {
    if (totalTime == 0) return 0.0;
    return totalDistance / (totalTime / 3600); // km/h
  }

  int get nextLevelExperience => level * 1000;

  double get levelProgress {
    final currentLevelExp = (level - 1) * 1000;
    final nextLevelExp = nextLevelExperience;
    final currentProgress = experience - currentLevelExp;
    final levelRange = nextLevelExp - currentLevelExp;
    
    if (levelRange == 0) return 1.0;
    return (currentProgress / levelRange).clamp(0.0, 1.0);
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  bool get isProfileComplete {
    return birthDate != null &&
        weightKg != null &&
        heightCm != null &&
        displayName.trim().isNotEmpty;
  }

  String get initials {
    final names = displayName.trim().split(' ');
    if (names.isEmpty) return '';
    if (names.length == 1) {
      return names.first.substring(0, 1).toUpperCase();
    }
    return '${names.first.substring(0, 1)}${names.last.substring(0, 1)}'
        .toUpperCase();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
