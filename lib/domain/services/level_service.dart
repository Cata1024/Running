import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/level_system.dart';

/// Servicio para gestionar niveles y XP del usuario
class LevelService {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  
  LevelService({
    FirebaseFirestore? firestore,
    required SharedPreferences prefs,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _prefs = prefs;

  // Keys para SharedPreferences (cache local)
  static const String _keyLastLevel = 'last_level';
  static const String _keyLastXP = 'last_xp';
  
  /// Añade XP al usuario y verifica si subió de nivel
  /// Retorna el nuevo nivel si cambió, null si no
  Future<LevelUpResult?> addXP(String userId, int xpToAdd) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      
      // Obtener XP actual
      final snapshot = await userDoc.get();
      final currentXP = (snapshot.data()?['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = (snapshot.data()?['level'] as num?)?.toInt() ?? 1;
      
      // Calcular nuevo XP y nivel
      final newXP = currentXP + xpToAdd;
      final newLevel = LevelSystem.levelFromXP(newXP);
      
      // Actualizar en Firestore
      await userDoc.update({
        'xp': newXP,
        'level': newLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Actualizar cache local
      await _prefs.setInt(_keyLastLevel, newLevel);
      await _prefs.setInt(_keyLastXP, newXP);
      
      // Verificar si subió de nivel
      if (newLevel > currentLevel) {
        final levelUpResult = LevelUpResult(
          oldLevel: currentLevel,
          newLevel: newLevel,
          xpGained: xpToAdd,
          totalXP: newXP,
          reward: LevelSystem.getRewardForLevel(newLevel),
        );
        
        // Si hay recompensa, añadir XP bonus
        if (levelUpResult.reward != null) {
          await addXP(userId, levelUpResult.reward!.bonusXP);
        }
        
        return levelUpResult;
      }
      
      return null;
    } catch (e) {
      // Error añadiendo XP
      return null;
    }
  }
  
  /// Obtiene el nivel actual del usuario
  Future<UserLevel> getUserLevel(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      final totalXP = (snapshot.data()?['xp'] as num?)?.toInt() ?? 0;
      
      // Actualizar cache
      final level = LevelSystem.levelFromXP(totalXP);
      await _prefs.setInt(_keyLastLevel, level);
      await _prefs.setInt(_keyLastXP, totalXP);
      
      return UserLevel.fromTotalXP(totalXP);
    } catch (e) {
      // Error obteniendo nivel, fallback a cache local
      
      final cachedXP = _prefs.getInt(_keyLastXP) ?? 0;
      return UserLevel.fromTotalXP(cachedXP);
    }
  }
  
  /// Obtiene el nivel del cache local (más rápido)
  UserLevel getCachedLevel() {
    final cachedXP = _prefs.getInt(_keyLastXP) ?? 0;
    return UserLevel.fromTotalXP(cachedXP);
  }
  
  /// Inicializa el nivel de un nuevo usuario
  Future<void> initializeUserLevel(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'xp': 0,
        'level': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      await _prefs.setInt(_keyLastLevel, 1);
      await _prefs.setInt(_keyLastXP, 0);
    } catch (e) {
      // Error inicializando nivel
    }
  }
  
  /// Obtiene el historial de niveles alcanzados
  Future<List<LevelMilestone>> getLevelHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('level_history')
          .orderBy('achievedAt', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs
          .map((doc) => LevelMilestone.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      // Error obteniendo historial
      return [];
    }
  }
  
  /// Registra un hito de nivel alcanzado
  Future<void> recordLevelMilestone(String userId, LevelUpResult result) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('level_history')
          .add({
        'oldLevel': result.oldLevel,
        'newLevel': result.newLevel,
        'xpGained': result.xpGained,
        'totalXP': result.totalXP,
        'hasReward': result.reward != null,
        'rewardType': result.reward?.type.name,
        'achievedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error registrando hito
    }
  }
}

/// Resultado de subir de nivel
class LevelUpResult {
  final int oldLevel;
  final int newLevel;
  final int xpGained;
  final int totalXP;
  final LevelReward? reward;
  
  const LevelUpResult({
    required this.oldLevel,
    required this.newLevel,
    required this.xpGained,
    required this.totalXP,
    this.reward,
  });
  
  int get levelsGained => newLevel - oldLevel;
  bool get hasReward => reward != null;
}

/// Hito de nivel alcanzado (historial)
class LevelMilestone {
  final int oldLevel;
  final int newLevel;
  final int xpGained;
  final int totalXP;
  final bool hasReward;
  final String? rewardType;
  final DateTime achievedAt;
  
  const LevelMilestone({
    required this.oldLevel,
    required this.newLevel,
    required this.xpGained,
    required this.totalXP,
    required this.hasReward,
    this.rewardType,
    required this.achievedAt,
  });
  
  factory LevelMilestone.fromFirestore(Map<String, dynamic> data) {
    return LevelMilestone(
      oldLevel: data['oldLevel'] as int,
      newLevel: data['newLevel'] as int,
      xpGained: data['xpGained'] as int,
      totalXP: data['totalXP'] as int,
      hasReward: data['hasReward'] as bool? ?? false,
      rewardType: data['rewardType'] as String?,
      achievedAt: (data['achievedAt'] as Timestamp).toDate(),
    );
  }
}
