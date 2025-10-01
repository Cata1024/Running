/// Modelo de usuario para Territory Run
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final int totalRuns;
  final double totalDistance;
  final int totalTime; // en segundos
  final int level;
  final int experience;
  final List<String> achievements;
  final String? photoUrl;
  final DateTime? lastActivityAt;

  const UserModel({
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
  });

  /// Crear desde mapa (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Runner',
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(
              map['createdAt']?.millisecondsSinceEpoch ?? 0),
      totalRuns: map['totalRuns'] ?? 0,
      totalDistance: (map['totalDistance'] ?? 0.0).toDouble(),
      totalTime: map['totalTime'] ?? 0,
      level: map['level'] ?? 1,
      experience: map['experience'] ?? 0,
      achievements: List<String>.from(map['achievements'] ?? []),
      photoUrl: map['photoUrl'],
      lastActivityAt: map['lastActivityAt'] != null
          ? (map['lastActivityAt'] is String
              ? DateTime.parse(map['lastActivityAt'])
              : DateTime.fromMillisecondsSinceEpoch(
                  map['lastActivityAt'].millisecondsSinceEpoch))
          : null,
    );
  }

  /// Convertir a mapa (Firestore)
  Map<String, dynamic> toMap() {
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
      'photoUrl': photoUrl,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
    };
  }

  /// Crear copia con cambios
  UserModel copyWith({
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
  }) {
    return UserModel(
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
    );
  }

  /// Calcular estadísticas derivadas
  double get averagePace {
    if (totalDistance == 0 || totalTime == 0) return 0.0;
    return totalTime / 60 / totalDistance; // minutos por kilómetro
  }

  double get averageSpeed {
    if (totalTime == 0) return 0.0;
    return totalDistance / (totalTime / 3600); // km/h
  }

  /// Obtener siguiente nivel de experiencia
  int get nextLevelExperience {
    return level * 1000; // 1000 XP por nivel
  }

  /// Progreso al siguiente nivel (0.0 - 1.0)
  double get levelProgress {
    final currentLevelExp = (level - 1) * 1000;
    final nextLevelExp = nextLevelExperience;
    final currentProgress = experience - currentLevelExp;
    final levelRange = nextLevelExp - currentLevelExp;
    
    if (levelRange == 0) return 1.0;
    return (currentProgress / levelRange).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, displayName: $displayName, level: $level, '
           'totalRuns: $totalRuns, totalDistance: ${totalDistance.toStringAsFixed(1)}km)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}