/// Sistema de niveles y experiencia para Territory Run
/// 
/// Curva de XP balanceada con progresión exponencial suave
/// Niveles del 1 al 50 con XP bien distribuido
class LevelSystem {
  // Constantes de balanceo
  static const int maxLevel = 50;
  static const double baseXP = 100.0;
  static const double exponent = 1.5;
  
  /// Calcula el XP total requerido para alcanzar un nivel
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    
    // Fórmula: XP = baseXP * (level ^ exponent)
    // Esto crea una curva exponencial suave
    return (baseXP * _pow(level - 1, exponent)).round();
  }
  
  /// Calcula el XP acumulado total hasta un nivel
  static int totalXpForLevel(int level) {
    if (level <= 1) return 0;
    
    int total = 0;
    for (int i = 2; i <= level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }
  
  /// Calcula el nivel basado en XP total
  static int levelFromXP(int totalXP) {
    if (totalXP <= 0) return 1;
    
    for (int level = 1; level <= maxLevel; level++) {
      if (totalXP < totalXpForLevel(level + 1)) {
        return level;
      }
    }
    
    return maxLevel;
  }
  
  /// Calcula el progreso hacia el siguiente nivel (0.0 a 1.0)
  static double progressToNextLevel(int totalXP) {
    final currentLevel = levelFromXP(totalXP);
    
    if (currentLevel >= maxLevel) return 1.0;
    
    final xpForCurrentLevel = totalXpForLevel(currentLevel);
    final xpForNextLevel = totalXpForLevel(currentLevel + 1);
    final xpInCurrentLevel = totalXP - xpForCurrentLevel;
    final xpNeededForNextLevel = xpForNextLevel - xpForCurrentLevel;
    
    if (xpNeededForNextLevel <= 0) return 1.0;
    
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }
  
  /// XP restante para el siguiente nivel
  static int xpToNextLevel(int totalXP) {
    final currentLevel = levelFromXP(totalXP);
    
    if (currentLevel >= maxLevel) return 0;
    
    final xpForNextLevel = totalXpForLevel(currentLevel + 1);
    
    return (xpForNextLevel - totalXP).clamp(0, double.infinity).toInt();
  }
  
  /// Recompensas por alcanzar un nivel
  static LevelReward? getRewardForLevel(int level) {
    // Niveles múltiplos de 5 dan recompensas especiales
    if (level % 10 == 0) {
      return LevelReward(
        level: level,
        type: RewardType.legendary,
        title: getLevelTitle(level),
        description: 'Has alcanzado el nivel $level. ¡Eres una leyenda!',
        iconEmoji: '🏆',
      );
    } else if (level % 5 == 0) {
      return LevelReward(
        level: level,
        type: RewardType.milestone,
        title: getLevelTitle(level),
        description: 'Nivel $level alcanzado. ¡Sigue así!',
        iconEmoji: '⭐',
      );
    }
    
    return null;
  }
  
  /// Título descriptivo para cada nivel
  static String getLevelTitle(int level) {
    if (level >= 50) return 'Maestro del Running';
    if (level >= 45) return 'Campeón Olímpico';
    if (level >= 40) return 'Ultra Maratonista';
    if (level >= 35) return 'Maratonista Elite';
    if (level >= 30) return 'Corredor Profesional';
    if (level >= 25) return 'Atleta Avanzado';
    if (level >= 20) return 'Corredor Experimentado';
    if (level >= 15) return 'Corredor Intermedio';
    if (level >= 10) return 'Corredor Dedicado';
    if (level >= 5) return 'Corredor Novato';
    return 'Principiante';
  }
  
  /// Rango de color para el nivel
  static String getLevelColor(int level) {
    if (level >= 40) return '#FFD700'; // Oro
    if (level >= 30) return '#C0C0C0'; // Plata
    if (level >= 20) return '#CD7F32'; // Bronce
    if (level >= 10) return '#00E676'; // Verde
    return '#2196F3'; // Azul
  }
  
  /// Helper para potencia
  static double _pow(num base, num exponent) {
    if (exponent == 0) return 1.0;
    if (exponent == 1) return base.toDouble();
    
    double result = 1.0;
    for (int i = 0; i < exponent.toInt(); i++) {
      result *= base;
    }
    
    // Manejar exponente decimal
    if (exponent % 1 != 0) {
      final decimal = exponent % 1;
      result *= _nthRoot(base.toDouble(), (1 / decimal).round());
    }
    
    return result;
  }
  
  /// Raíz n-ésima aproximada
  static double _nthRoot(double value, int n) {
    if (n <= 0) return 1.0;
    
    double x = value / n;
    double lastX = 0;
    
    while ((x - lastX).abs() > 0.0001) {
      lastX = x;
      x = ((n - 1) * x + value / _pow(x, n - 1)) / n;
    }
    
    return x;
  }
  
  /// Tabla de XP pre-calculada para los primeros 50 niveles
  static const Map<int, int> xpTable = {
    1: 0,
    2: 100,
    3: 282,
    4: 519,
    5: 800,
    6: 1118,
    7: 1469,
    8: 1848,
    9: 2253,
    10: 2683,
    15: 5196,
    20: 8485,
    25: 12449,
    30: 17008,
    35: 22097,
    40: 27661,
    45: 33655,
    50: 40042,
  };
}

/// Tipo de recompensa por nivel
enum RewardType {
  milestone,  // Niveles múltiplos de 5
  legendary,  // Niveles múltiplos de 10
}

/// Recompensa por alcanzar un nivel
class LevelReward {
  final int level;
  final RewardType type;
  final String title;
  final String description;
  final String iconEmoji;
  
  const LevelReward({
    required this.level,
    required this.type,
    required this.title,
    required this.description,
    required this.iconEmoji,
  });
  
  /// XP bonus por la recompensa
  int get bonusXP {
    switch (type) {
      case RewardType.legendary:
        return 500;
      case RewardType.milestone:
        return 200;
    }
  }
}

/// Modelo de datos del nivel del usuario
class UserLevel {
  final int level;
  final int totalXP;
  final int xpInCurrentLevel;
  final int xpForNextLevel;
  final double progressToNextLevel;
  final String title;
  final String colorHex;
  
  const UserLevel({
    required this.level,
    required this.totalXP,
    required this.xpInCurrentLevel,
    required this.xpForNextLevel,
    required this.progressToNextLevel,
    required this.title,
    required this.colorHex,
  });
  
  factory UserLevel.fromTotalXP(int totalXP) {
    final level = LevelSystem.levelFromXP(totalXP);
    final progress = LevelSystem.progressToNextLevel(totalXP);
    final xpToNext = LevelSystem.xpToNextLevel(totalXP);
    final xpForCurrentLevel = LevelSystem.totalXpForLevel(level);
    final xpInCurrent = totalXP - xpForCurrentLevel;
    
    return UserLevel(
      level: level,
      totalXP: totalXP,
      xpInCurrentLevel: xpInCurrent,
      xpForNextLevel: xpToNext,
      progressToNextLevel: progress,
      title: LevelSystem.getLevelTitle(level),
      colorHex: LevelSystem.getLevelColor(level),
    );
  }
  
  bool get isMaxLevel => level >= LevelSystem.maxLevel;
}
