import 'package:equatable/equatable.dart';

/// Entidad que representa un logro en la aplicación
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final AchievementRarity rarity;
  final int requiredValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final String? badgeColor;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.requiredValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.xpReward,
    this.badgeColor,
  });

  /// Progreso del logro (0.0 a 1.0)
  double get progress => requiredValue > 0 
      ? (currentValue / requiredValue).clamp(0.0, 1.0) 
      : 0.0;

  /// Porcentaje de progreso (0 a 100)
  int get progressPercentage => (progress * 100).round();

  /// Si el logro está cerca de desbloquearse (80% o más)
  bool get isNearCompletion => progress >= 0.8 && !isUnlocked;

  /// Color basado en la rareza
  String get rarityColor {
    switch (rarity) {
      case AchievementRarity.legendary:
        return '#FFD700'; // Oro
      case AchievementRarity.epic:
        return '#9C27B0'; // Púrpura
      case AchievementRarity.rare:
        return '#2196F3'; // Azul
      case AchievementRarity.common:
        return '#4CAF50'; // Verde
    }
  }

  /// Nombre de la rareza en español
  String get rarityName {
    switch (rarity) {
      case AchievementRarity.legendary:
        return 'Legendario';
      case AchievementRarity.epic:
        return 'Épico';
      case AchievementRarity.rare:
        return 'Raro';
      case AchievementRarity.common:
        return 'Común';
    }
  }

  /// Copiar con cambios
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    AchievementRarity? rarity,
    int? requiredValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
    String? badgeColor,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      requiredValue: requiredValue ?? this.requiredValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
      badgeColor: badgeColor ?? this.badgeColor,
    );
  }

  /// Crear desde JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: AchievementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AchievementType.special,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      requiredValue: json['requiredValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      xpReward: json['xpReward'] as int,
      badgeColor: json['badgeColor'] as String?,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.name,
      'rarity': rarity.name,
      'requiredValue': requiredValue,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'xpReward': xpReward,
      'badgeColor': badgeColor,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        type,
        rarity,
        requiredValue,
        currentValue,
        isUnlocked,
        unlockedAt,
        xpReward,
        badgeColor,
      ];
}

/// Tipos de logros
enum AchievementType {
  distance('Distancia', '🏃'),      // Distancia total recorrida
  runs('Carreras', '🎯'),           // Número de carreras completadas
  streak('Racha', '🔥'),            // Días consecutivos corriendo
  speed('Velocidad', '⚡'),         // Velocidad máxima o promedio
  territory('Territorio', '🗺️'),   // Territorio conquistado
  social('Social', '👥'),           // Logros sociales (compartir, etc)
  milestone('Hitos', '🏆'),         // Hitos especiales
  challenge('Desafíos', '💪'),      // Desafíos completados
  special('Especial', '⭐');        // Eventos especiales o temporales

  final String displayName;
  final String emoji;
  const AchievementType(this.displayName, this.emoji);
}

/// Rareza de los logros
enum AchievementRarity {
  common(1, 10),      // 60% de usuarios lo obtienen - 10 XP base
  rare(2, 25),        // 30% de usuarios lo obtienen - 25 XP base
  epic(3, 50),        // 9% de usuarios lo obtienen - 50 XP base
  legendary(4, 100);  // 1% de usuarios lo obtienen - 100 XP base

  final int tier;
  final int baseXp;
  const AchievementRarity(this.tier, this.baseXp);
}

/// Categoría de progreso para agrupar logros
class AchievementCategory {
  final String id;
  final String name;
  final String icon;
  final List<Achievement> achievements;

  const AchievementCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.achievements,
  });

  /// Total de logros en la categoría
  int get totalAchievements => achievements.length;

  /// Logros desbloqueados en la categoría
  int get unlockedAchievements => 
      achievements.where((a) => a.isUnlocked).length;

  /// Progreso de la categoría (0.0 a 1.0)
  double get progress => totalAchievements > 0
      ? unlockedAchievements / totalAchievements
      : 0.0;

  /// XP total obtenido en esta categoría
  int get totalXpEarned => achievements
      .where((a) => a.isUnlocked)
      .fold(0, (sum, a) => sum + a.xpReward);
}
