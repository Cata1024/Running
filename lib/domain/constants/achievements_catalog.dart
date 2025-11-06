import '../entities/achievement.dart';

/// Catálogo completo de logros disponibles en la aplicación
class AchievementsCatalog {
  
  /// Logros de Distancia
  static const List<Achievement> distanceAchievements = [
    Achievement(
      id: 'first_km',
      title: 'Primer Kilómetro',
      description: 'Completa tu primer kilómetro',
      icon: '🎯',
      type: AchievementType.distance,
      rarity: AchievementRarity.common,
      requiredValue: 1000, // metros
      xpReward: 10,
    ),
    Achievement(
      id: 'distance_5k',
      title: 'Club 5K',
      description: 'Acumula 5 kilómetros en total',
      icon: '🏃',
      type: AchievementType.distance,
      rarity: AchievementRarity.common,
      requiredValue: 5000,
      xpReward: 20,
    ),
    Achievement(
      id: 'distance_10k',
      title: 'Corredor 10K',
      description: 'Acumula 10 kilómetros en total',
      icon: '💪',
      type: AchievementType.distance,
      rarity: AchievementRarity.common,
      requiredValue: 10000,
      xpReward: 30,
    ),
    Achievement(
      id: 'distance_21k',
      title: 'Media Maratón',
      description: 'Acumula 21 kilómetros en total',
      icon: '🏅',
      type: AchievementType.distance,
      rarity: AchievementRarity.rare,
      requiredValue: 21000,
      xpReward: 50,
    ),
    Achievement(
      id: 'distance_42k',
      title: 'Maratonista',
      description: 'Acumula 42 kilómetros en total',
      icon: '🥇',
      type: AchievementType.distance,
      rarity: AchievementRarity.epic,
      requiredValue: 42000,
      xpReward: 100,
    ),
    Achievement(
      id: 'distance_100k',
      title: 'Ultra Runner',
      description: 'Acumula 100 kilómetros en total',
      icon: '🚀',
      type: AchievementType.distance,
      rarity: AchievementRarity.legendary,
      requiredValue: 100000,
      xpReward: 200,
    ),
  ];

  /// Logros de Número de Carreras
  static const List<Achievement> runsAchievements = [
    Achievement(
      id: 'first_run',
      title: 'Primera Carrera',
      description: 'Completa tu primera carrera',
      icon: '🎉',
      type: AchievementType.runs,
      rarity: AchievementRarity.common,
      requiredValue: 1,
      xpReward: 10,
    ),
    Achievement(
      id: 'runs_5',
      title: 'Calentando Motores',
      description: 'Completa 5 carreras',
      icon: '🔥',
      type: AchievementType.runs,
      rarity: AchievementRarity.common,
      requiredValue: 5,
      xpReward: 20,
    ),
    Achievement(
      id: 'runs_10',
      title: 'Constancia',
      description: 'Completa 10 carreras',
      icon: '💯',
      type: AchievementType.runs,
      rarity: AchievementRarity.common,
      requiredValue: 10,
      xpReward: 30,
    ),
    Achievement(
      id: 'runs_25',
      title: 'Dedicación',
      description: 'Completa 25 carreras',
      icon: '⭐',
      type: AchievementType.runs,
      rarity: AchievementRarity.rare,
      requiredValue: 25,
      xpReward: 50,
    ),
    Achievement(
      id: 'runs_50',
      title: 'Medio Centenar',
      description: 'Completa 50 carreras',
      icon: '🌟',
      type: AchievementType.runs,
      rarity: AchievementRarity.epic,
      requiredValue: 50,
      xpReward: 100,
    ),
    Achievement(
      id: 'runs_100',
      title: 'Centurión',
      description: 'Completa 100 carreras',
      icon: '👑',
      type: AchievementType.runs,
      rarity: AchievementRarity.legendary,
      requiredValue: 100,
      xpReward: 200,
    ),
  ];

  /// Logros de Racha (días consecutivos)
  static const List<Achievement> streakAchievements = [
    Achievement(
      id: 'streak_3',
      title: 'Tres Días Seguidos',
      description: 'Corre 3 días consecutivos',
      icon: '🔥',
      type: AchievementType.streak,
      rarity: AchievementRarity.common,
      requiredValue: 3,
      xpReward: 15,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Semana Completa',
      description: 'Corre 7 días consecutivos',
      icon: '📅',
      type: AchievementType.streak,
      rarity: AchievementRarity.rare,
      requiredValue: 7,
      xpReward: 40,
    ),
    Achievement(
      id: 'streak_14',
      title: 'Dos Semanas',
      description: 'Corre 14 días consecutivos',
      icon: '💪',
      type: AchievementType.streak,
      rarity: AchievementRarity.epic,
      requiredValue: 14,
      xpReward: 80,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Mes Imparable',
      description: 'Corre 30 días consecutivos',
      icon: '🏆',
      type: AchievementType.streak,
      rarity: AchievementRarity.legendary,
      requiredValue: 30,
      xpReward: 150,
    ),
  ];

  /// Logros de Velocidad
  static const List<Achievement> speedAchievements = [
    Achievement(
      id: 'speed_8kmh',
      title: 'Trote Suave',
      description: 'Alcanza 8 km/h de velocidad promedio',
      icon: '🐢',
      type: AchievementType.speed,
      rarity: AchievementRarity.common,
      requiredValue: 8,
      xpReward: 15,
    ),
    Achievement(
      id: 'speed_10kmh',
      title: 'Buen Ritmo',
      description: 'Alcanza 10 km/h de velocidad promedio',
      icon: '🏃',
      type: AchievementType.speed,
      rarity: AchievementRarity.common,
      requiredValue: 10,
      xpReward: 25,
    ),
    Achievement(
      id: 'speed_12kmh',
      title: 'Rápido',
      description: 'Alcanza 12 km/h de velocidad promedio',
      icon: '💨',
      type: AchievementType.speed,
      rarity: AchievementRarity.rare,
      requiredValue: 12,
      xpReward: 40,
    ),
    Achievement(
      id: 'speed_15kmh',
      title: 'Velocista',
      description: 'Alcanza 15 km/h de velocidad promedio',
      icon: '⚡',
      type: AchievementType.speed,
      rarity: AchievementRarity.epic,
      requiredValue: 15,
      xpReward: 75,
    ),
    Achievement(
      id: 'speed_18kmh',
      title: 'Relámpago',
      description: 'Alcanza 18 km/h de velocidad promedio',
      icon: '🚀',
      type: AchievementType.speed,
      rarity: AchievementRarity.legendary,
      requiredValue: 18,
      xpReward: 150,
    ),
  ];

  /// Logros de Territorio
  static const List<Achievement> territoryAchievements = [
    Achievement(
      id: 'territory_1',
      title: 'Mi Primera Zona',
      description: 'Conquista tu primera zona del territorio',
      icon: '🗺️',
      type: AchievementType.territory,
      rarity: AchievementRarity.common,
      requiredValue: 1,
      xpReward: 20,
    ),
    Achievement(
      id: 'territory_5',
      title: 'Explorador',
      description: 'Conquista 5 zonas diferentes',
      icon: '🧭',
      type: AchievementType.territory,
      rarity: AchievementRarity.rare,
      requiredValue: 5,
      xpReward: 50,
    ),
    Achievement(
      id: 'territory_10',
      title: 'Conquistador',
      description: 'Conquista 10 zonas diferentes',
      icon: '🏰',
      type: AchievementType.territory,
      rarity: AchievementRarity.epic,
      requiredValue: 10,
      xpReward: 100,
    ),
    Achievement(
      id: 'territory_25',
      title: 'Rey del Territorio',
      description: 'Conquista 25 zonas diferentes',
      icon: '👑',
      type: AchievementType.territory,
      rarity: AchievementRarity.legendary,
      requiredValue: 25,
      xpReward: 200,
    ),
  ];

  /// Logros de Hitos
  static const List<Achievement> milestoneAchievements = [
    Achievement(
      id: 'early_bird',
      title: 'Madrugador',
      description: 'Completa una carrera antes de las 6:00 AM',
      icon: '🌅',
      type: AchievementType.milestone,
      rarity: AchievementRarity.common,
      requiredValue: 1,
      xpReward: 20,
    ),
    Achievement(
      id: 'night_runner',
      title: 'Corredor Nocturno',
      description: 'Completa una carrera después de las 9:00 PM',
      icon: '🌙',
      type: AchievementType.milestone,
      rarity: AchievementRarity.common,
      requiredValue: 1,
      xpReward: 20,
    ),
    Achievement(
      id: 'weekend_warrior',
      title: 'Guerrero de Fin de Semana',
      description: 'Corre sábado y domingo la misma semana',
      icon: '🦸',
      type: AchievementType.milestone,
      rarity: AchievementRarity.rare,
      requiredValue: 1,
      xpReward: 35,
    ),
    Achievement(
      id: 'rain_runner',
      title: 'Lluvia o Sol',
      description: 'Completa una carrera bajo la lluvia',
      icon: '🌧️',
      type: AchievementType.milestone,
      rarity: AchievementRarity.rare,
      requiredValue: 1,
      xpReward: 40,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Semana Perfecta',
      description: 'Corre al menos 5 días en una semana',
      icon: '✨',
      type: AchievementType.milestone,
      rarity: AchievementRarity.epic,
      requiredValue: 1,
      xpReward: 75,
    ),
  ];

  /// Logros Sociales
  static const List<Achievement> socialAchievements = [
    Achievement(
      id: 'first_share',
      title: 'Compartiendo el Éxito',
      description: 'Comparte tu primera carrera',
      icon: '📱',
      type: AchievementType.social,
      rarity: AchievementRarity.common,
      requiredValue: 1,
      xpReward: 10,
    ),
    Achievement(
      id: 'profile_complete',
      title: 'Perfil Completo',
      description: 'Completa todos los datos de tu perfil',
      icon: '✅',
      type: AchievementType.social,
      rarity: AchievementRarity.common,
      requiredValue: 1,
      xpReward: 15,
    ),
    Achievement(
      id: 'photo_upload',
      title: 'Cara Visible',
      description: 'Sube una foto de perfil',
      icon: '📸',
      type: AchievementType.social,
      rarity: AchievementRarity.common,
      requiredValue: 1,
      xpReward: 10,
    ),
  ];

  /// Logros de Desafíos
  static const List<Achievement> challengeAchievements = [
    Achievement(
      id: 'challenge_5k_under_30',
      title: '5K en 30 Minutos',
      description: 'Completa 5K en menos de 30 minutos',
      icon: '⏱️',
      type: AchievementType.challenge,
      rarity: AchievementRarity.rare,
      requiredValue: 1,
      xpReward: 50,
    ),
    Achievement(
      id: 'challenge_10k_under_60',
      title: '10K en 1 Hora',
      description: 'Completa 10K en menos de 60 minutos',
      icon: '⏰',
      type: AchievementType.challenge,
      rarity: AchievementRarity.epic,
      requiredValue: 1,
      xpReward: 100,
    ),
    Achievement(
      id: 'challenge_negative_split',
      title: 'Negative Split',
      description: 'Termina una carrera más rápido de lo que empezaste',
      icon: '📈',
      type: AchievementType.challenge,
      rarity: AchievementRarity.rare,
      requiredValue: 1,
      xpReward: 40,
    ),
  ];

  /// Todos los logros disponibles
  static List<Achievement> get allAchievements => [
        ...distanceAchievements,
        ...runsAchievements,
        ...streakAchievements,
        ...speedAchievements,
        ...territoryAchievements,
        ...milestoneAchievements,
        ...socialAchievements,
        ...challengeAchievements,
      ];

  /// Obtener logro por ID
  static Achievement? getAchievementById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Obtener categorías de logros
  static List<AchievementCategory> getCategories() {
    return [
      const AchievementCategory(
        id: 'distance',
        name: 'Distancia',
        icon: '🏃',
        achievements: distanceAchievements,
      ),
      const AchievementCategory(
        id: 'runs',
        name: 'Carreras',
        icon: '🎯',
        achievements: runsAchievements,
      ),
      const AchievementCategory(
        id: 'streak',
        name: 'Rachas',
        icon: '🔥',
        achievements: streakAchievements,
      ),
      const AchievementCategory(
        id: 'speed',
        name: 'Velocidad',
        icon: '⚡',
        achievements: speedAchievements,
      ),
      const AchievementCategory(
        id: 'territory',
        name: 'Territorio',
        icon: '🗺️',
        achievements: territoryAchievements,
      ),
      const AchievementCategory(
        id: 'milestone',
        name: 'Hitos',
        icon: '🏆',
        achievements: milestoneAchievements,
      ),
      const AchievementCategory(
        id: 'social',
        name: 'Social',
        icon: '👥',
        achievements: socialAchievements,
      ),
      const AchievementCategory(
        id: 'challenge',
        name: 'Desafíos',
        icon: '💪',
        achievements: challengeAchievements,
      ),
    ];
  }
}
