import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../entities/achievement.dart';
import '../entities/run.dart';
import '../constants/achievements_catalog.dart';

/// Servicio para gestionar el sistema de logros
class AchievementsService {
  final FirebaseFirestore _firestore;
  final String userId;
  
  // Cache local de logros del usuario
  List<Achievement> _userAchievements = [];
  bool _isInitialized = false;

  AchievementsService({
    FirebaseFirestore? firestore,
    required this.userId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Inicializar el servicio cargando los logros del usuario
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Cargar logros desde Firestore
      await _loadUserAchievements();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando achievements: $e');
      // Intentar cargar desde cache local si falla Firestore
      await _loadFromLocalCache();
    }
  }

  /// Cargar logros del usuario desde Firestore
  Future<void> _loadUserAchievements() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('progress')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _userAchievements = _mergeWithCatalog(data['achievements'] ?? {});
      } else {
        // Primera vez - inicializar con el catálogo
        _userAchievements = AchievementsCatalog.allAchievements;
        await _saveUserAchievements();
      }
      
      // Guardar en cache local
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Error cargando achievements desde Firestore: $e');
      rethrow;
    }
  }

  /// Combinar progreso del usuario con el catálogo de logros
  List<Achievement> _mergeWithCatalog(Map<String, dynamic> userProgress) {
    return AchievementsCatalog.allAchievements.map((catalogAchievement) {
      final progress = userProgress[catalogAchievement.id];
      
      if (progress != null) {
        // Manejar unlockedAt que puede venir como Timestamp (Firestore) o String (cache)
        DateTime? unlockedAt;
        final unlockedAtValue = progress['unlockedAt'];
        if (unlockedAtValue != null) {
          if (unlockedAtValue is Timestamp) {
            unlockedAt = unlockedAtValue.toDate();
          } else if (unlockedAtValue is String) {
            unlockedAt = DateTime.parse(unlockedAtValue);
          }
        }
        
        return catalogAchievement.copyWith(
          currentValue: progress['currentValue'] ?? 0,
          isUnlocked: progress['isUnlocked'] ?? false,
          unlockedAt: unlockedAt,
        );
      }
      
      return catalogAchievement;
    }).toList();
  }

  /// Guardar logros en Firestore
  Future<void> _saveUserAchievements() async {
    try {
      final Map<String, dynamic> achievementsData = {};
      
      for (final achievement in _userAchievements) {
        achievementsData[achievement.id] = {
          'currentValue': achievement.currentValue,
          'isUnlocked': achievement.isUnlocked,
          'unlockedAt': achievement.unlockedAt?.toIso8601String(),
        };
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('progress')
          .set({
        'achievements': achievementsData,
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalXp': getTotalXp(),
        'unlockedCount': getUnlockedCount(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error guardando achievements: $e');
    }
  }

  /// Guardar en cache local (SharedPreferences)
  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = _userAchievements
          .map((a) => {
                'id': a.id,
                'currentValue': a.currentValue,
                'isUnlocked': a.isUnlocked,
                'unlockedAt': a.unlockedAt?.toIso8601String(),
              })
          .toList();
      
      await prefs.setString(
        'achievements_$userId',
        jsonEncode(achievementsJson),
      );
    } catch (e) {
      debugPrint('Error guardando cache local: $e');
    }
  }

  /// Cargar desde cache local
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('achievements_$userId');
      
      if (cacheString != null) {
        final List<dynamic> cacheData = jsonDecode(cacheString);
        final Map<String, dynamic> userProgress = {};
        
        for (final item in cacheData) {
          userProgress[item['id']] = item;
        }
        
        _userAchievements = _mergeWithCatalog(userProgress);
        _isInitialized = true;
      } else {
        _userAchievements = AchievementsCatalog.allAchievements;
      }
    } catch (e) {
      debugPrint('Error cargando cache local: $e');
      _userAchievements = AchievementsCatalog.allAchievements;
    }
  }

  /// Obtener todos los logros del usuario
  List<Achievement> getUserAchievements() {
    if (!_isInitialized) {
      return AchievementsCatalog.allAchievements;
    }
    return _userAchievements;
  }

  /// Obtener logros por categoría
  List<AchievementCategory> getAchievementsByCategory() {
    final categories = AchievementsCatalog.getCategories();
    
    return categories.map((category) {
      final userAchievements = _userAchievements
          .where((a) => category.achievements.any((ca) => ca.id == a.id))
          .toList();
      
      return AchievementCategory(
        id: category.id,
        name: category.name,
        icon: category.icon,
        achievements: userAchievements,
      );
    }).toList();
  }

  /// Obtener logros desbloqueados
  List<Achievement> getUnlockedAchievements() {
    return _userAchievements.where((a) => a.isUnlocked).toList();
  }

  /// Obtener logros cercanos a completar (>80%)
  List<Achievement> getNearCompletionAchievements() {
    return _userAchievements
        .where((a) => !a.isUnlocked && a.progress >= 0.8)
        .toList();
  }

  /// Obtener XP total
  int getTotalXp() {
    return _userAchievements
        .where((a) => a.isUnlocked)
        .fold(0, (total, a) => total + a.xpReward);
  }

  /// Obtener número de logros desbloqueados
  int getUnlockedCount() {
    return _userAchievements.where((a) => a.isUnlocked).length;
  }

  /// Obtener porcentaje de completado
  double getCompletionPercentage() {
    if (_userAchievements.isEmpty) return 0.0;
    return getUnlockedCount() / _userAchievements.length;
  }

  /// Procesar una nueva carrera y actualizar logros
  Future<List<Achievement>> processRunForAchievements(Run run) async {
    if (!_isInitialized) await initialize();
    
    final List<Achievement> newlyUnlocked = [];
    
    // Actualizar logros de distancia
    newlyUnlocked.addAll(await _updateDistanceAchievements(run.distanceMeters));
    
    // Actualizar logros de número de carreras
    newlyUnlocked.addAll(await _updateRunCountAchievements());
    
    // Actualizar logros de velocidad
    if (run.avgSpeedKmh > 0) {
      newlyUnlocked.addAll(await _updateSpeedAchievements(run.avgSpeedKmh));
    }
    
    // Actualizar logros de territorio
    if (run.territoryCovered > 0) {
      newlyUnlocked.addAll(await _updateTerritoryAchievements(run.territoryCovered));
    }
    
    // Actualizar logros de hitos especiales
    newlyUnlocked.addAll(await _updateMilestoneAchievements(run));
    
    // Guardar cambios si hay nuevos logros
    if (newlyUnlocked.isNotEmpty) {
      await _saveUserAchievements();
      await _saveToLocalCache();
    }
    
    return newlyUnlocked;
  }

  /// Actualizar logros de distancia usando incremento local (sin depender de agregados externos)
  Future<List<Achievement>> _updateDistanceAchievements(double distanceMeters) async {
    final newlyUnlocked = <Achievement>[];
    final increment = distanceMeters.toInt();

    for (int i = 0; i < _userAchievements.length; i++) {
      final achievement = _userAchievements[i];
      if (achievement.type == AchievementType.distance && !achievement.isUnlocked) {
        final nextValue = (achievement.currentValue + increment).clamp(0, 1 << 31);
        final updatedAchievement = achievement.copyWith(currentValue: nextValue);
        if (updatedAchievement.currentValue >= updatedAchievement.requiredValue) {
          _userAchievements[i] = updatedAchievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          newlyUnlocked.add(_userAchievements[i]);
        } else {
          _userAchievements[i] = updatedAchievement;
        }
      }
    }
    return newlyUnlocked;
  }

  /// Actualizar logros de número de carreras (incremental local)
  Future<List<Achievement>> _updateRunCountAchievements() async {
    final newlyUnlocked = <Achievement>[];
    for (int i = 0; i < _userAchievements.length; i++) {
      final achievement = _userAchievements[i];
      if (achievement.type == AchievementType.runs && !achievement.isUnlocked) {
        final updatedAchievement = achievement.copyWith(
          currentValue: achievement.currentValue + 1,
        );
        if (updatedAchievement.currentValue >= updatedAchievement.requiredValue) {
          _userAchievements[i] = updatedAchievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          newlyUnlocked.add(_userAchievements[i]);
        } else {
          _userAchievements[i] = updatedAchievement;
        }
      }
    }
    return newlyUnlocked;
  }

  /// Actualizar logros de velocidad
  Future<List<Achievement>> _updateSpeedAchievements(double avgSpeedKmh) async {
    final newlyUnlocked = <Achievement>[];
    
    for (int i = 0; i < _userAchievements.length; i++) {
      final achievement = _userAchievements[i];
      
      if (achievement.type == AchievementType.speed && !achievement.isUnlocked) {
        if (avgSpeedKmh >= achievement.requiredValue) {
          _userAchievements[i] = achievement.copyWith(
            currentValue: avgSpeedKmh.toInt(),
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          newlyUnlocked.add(_userAchievements[i]);
        } else {
          // Actualizar el progreso con la mejor velocidad alcanzada
          if (avgSpeedKmh > achievement.currentValue) {
            _userAchievements[i] = achievement.copyWith(
              currentValue: avgSpeedKmh.toInt(),
            );
          }
        }
      }
    }
    
    return newlyUnlocked;
  }

  /// Actualizar logros de territorio (incremental local)
  Future<List<Achievement>> _updateTerritoryAchievements(double territoryCovered) async {
    final newlyUnlocked = <Achievement>[];
    final increment = territoryCovered.toInt();
    for (int i = 0; i < _userAchievements.length; i++) {
      final achievement = _userAchievements[i];
      if (achievement.type == AchievementType.territory && !achievement.isUnlocked) {
        final updatedAchievement = achievement.copyWith(
          currentValue: achievement.currentValue + increment,
        );
        if (updatedAchievement.currentValue >= updatedAchievement.requiredValue) {
          _userAchievements[i] = updatedAchievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          newlyUnlocked.add(_userAchievements[i]);
        } else {
          _userAchievements[i] = updatedAchievement;
        }
      }
    }
    return newlyUnlocked;
  }

  /// Actualizar logros de hitos especiales
  Future<List<Achievement>> _updateMilestoneAchievements(Run run) async {
    final newlyUnlocked = <Achievement>[];
    final runTime = run.startTime;
    
    // Early bird - antes de las 6 AM
    if (runTime.hour < 6) {
      final earlyBird = _userAchievements.firstWhere(
        (a) => a.id == 'early_bird' && !a.isUnlocked,
        orElse: () => const Achievement(
          id: '',
          title: '',
          description: '',
          icon: '',
          type: AchievementType.special,
          rarity: AchievementRarity.common,
          requiredValue: 0,
          xpReward: 0,
        ),
      );
      
      if (earlyBird.id.isNotEmpty) {
        final index = _userAchievements.indexWhere((a) => a.id == 'early_bird');
        _userAchievements[index] = earlyBird.copyWith(
          currentValue: 1,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        newlyUnlocked.add(_userAchievements[index]);
      }
    }
    
    // Night runner - después de las 9 PM
    if (runTime.hour >= 21) {
      final nightRunner = _userAchievements.firstWhere(
        (a) => a.id == 'night_runner' && !a.isUnlocked,
        orElse: () => const Achievement(
          id: '',
          title: '',
          description: '',
          icon: '',
          type: AchievementType.special,
          rarity: AchievementRarity.common,
          requiredValue: 0,
          xpReward: 0,
        ),
      );
      
      if (nightRunner.id.isNotEmpty) {
        final index = _userAchievements.indexWhere((a) => a.id == 'night_runner');
        _userAchievements[index] = nightRunner.copyWith(
          currentValue: 1,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        newlyUnlocked.add(_userAchievements[index]);
      }
    }
    
    // Challenge achievements - 5K en menos de 30 minutos
    if (run.distanceMeters >= 5000 && run.durationSeconds < 1800) {
      final challenge5k = _userAchievements.firstWhere(
        (a) => a.id == 'challenge_5k_under_30' && !a.isUnlocked,
        orElse: () => const Achievement(
          id: '',
          title: '',
          description: '',
          icon: '',
          type: AchievementType.special,
          rarity: AchievementRarity.common,
          requiredValue: 0,
          xpReward: 0,
        ),
      );
      
      if (challenge5k.id.isNotEmpty) {
        final index = _userAchievements.indexWhere((a) => a.id == 'challenge_5k_under_30');
        _userAchievements[index] = challenge5k.copyWith(
          currentValue: 1,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        newlyUnlocked.add(_userAchievements[index]);
      }
    }
    
    return newlyUnlocked;
  }

  /// Marcar logro social como completado
  Future<Achievement?> unlockSocialAchievement(String achievementId) async {
    if (!_isInitialized) await initialize();
    
    final index = _userAchievements.indexWhere((a) => a.id == achievementId);
    
    if (index != -1 && !_userAchievements[index].isUnlocked) {
      _userAchievements[index] = _userAchievements[index].copyWith(
        currentValue: _userAchievements[index].requiredValue,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      
      await _saveUserAchievements();
      await _saveToLocalCache();
      
      return _userAchievements[index];
    }
    
    return null;
  }
}
