import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime? birthDate;
  final double? weightKg;
  final int? heightCm;
  final String? gender;
  final String preferredUnits;
  final String? goalDescription;

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
    this.birthDate,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.preferredUnits = 'metric',
    this.goalDescription,
  });

  /// Crear desde mapa (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Runner',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      totalRuns: map['totalRuns'] ?? 0,
      totalDistance: (map['totalDistance'] ?? 0).toDouble(),
      totalTime: map['totalTime'] ?? 0,
      level: map['level'] ?? 1,
      experience: map['experience'] ?? 0,
      achievements: List<String>.from(map['achievements'] ?? []),
      photoUrl: map['photoUrl'],
      lastActivityAt: _parseDate(map['lastActivityAt']),
      birthDate: _parseDate(map['birthDate']),
      weightKg: map['weightKg'] != null
          ? (map['weightKg'] is int
              ? (map['weightKg'] as int).toDouble()
              : (map['weightKg'] as num).toDouble())
          : null,
      heightCm:
          map['heightCm'] != null ? (map['heightCm'] as num).round() : null,
      gender: map['gender'],
      preferredUnits: map['preferredUnits'] ?? 'metric',
      goalDescription: map['goalDescription'],
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
      'birthDate': birthDate?.toIso8601String(),
      'weightKg': weightKg,
      'heightCm': heightCm,
      'gender': gender,
      'preferredUnits': preferredUnits,
      'goalDescription': goalDescription,
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
    DateTime? birthDate,
    double? weightKg,
    int? heightCm,
    String? gender,
    String? preferredUnits,
    String? goalDescription,
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
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      goalDescription: goalDescription ?? this.goalDescription,
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

  /// Edad calculada a partir de la fecha de nacimiento
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate!.year;
    final hasHadBirthday = (now.month > birthDate!.month) ||
        (now.month == birthDate!.month && now.day >= birthDate!.day);
    if (!hasHadBirthday) {
      years -= 1;
    }
    return years;
  }

  /// Índice de masa corporal (IMC) estimado, o null si faltan datos
  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightMeters = heightCm! / 100;
    return weightKg! / (heightMeters * heightMeters);
  }

  /// Verifica si la información básica del perfil está completa
  bool get isProfileComplete {
    return birthDate != null &&
        weightKg != null &&
        heightCm != null &&
        displayName.trim().isNotEmpty;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
