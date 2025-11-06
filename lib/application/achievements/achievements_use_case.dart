import 'package:flutter/foundation.dart';

import '../../domain/constants/achievements_catalog.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/run.dart';
import '../../domain/repositories/i_achievements_repository.dart';

/// Orchestrates achievements lifecycle using domain logic while delegating
/// persistence to [IAchievementsRepository].
class AchievementsUseCase {
  AchievementsUseCase({
    required String userId,
    required IAchievementsRepository repository,
  })  : _userId = userId,
        _repository = repository;

  final String _userId;
  final IAchievementsRepository _repository;

  List<Achievement> _userAchievements = AchievementsCatalog.allAchievements;
  bool _isInitialized = false;

  /// Initializes achievements by fetching the remote snapshot and merging it
  /// with the catalog. Falls back to cached snapshot when remote fails.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final remoteSnapshot = await _repository.fetchRemoteSnapshot(_userId);
      if (remoteSnapshot.entries.isEmpty) {
        _userAchievements = AchievementsCatalog.allAchievements;
        await _persistSnapshot();
      } else {
        _userAchievements = _mergeWithCatalog(remoteSnapshot.entries);
      }
      await _repository.saveCachedSnapshot(
        _userId,
        AchievementsSnapshot(entries: _snapshotFromAchievements()),
      );
      _isInitialized = true;
    } catch (error) {
      debugPrint('Error loading achievements remotely: $error');
      await _loadFromCache();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await _repository.fetchCachedSnapshot(_userId);
      if (cached != null && cached.entries.isNotEmpty) {
        _userAchievements = _mergeWithCatalog(cached.entries);
        _isInitialized = true;
      } else {
        _userAchievements = AchievementsCatalog.allAchievements;
      }
    } catch (e) {
      debugPrint('Error loading achievements cache: $e');
      _userAchievements = AchievementsCatalog.allAchievements;
    }
  }

  Map<String, AchievementProgress> _snapshotFromAchievements() {
    return {
      for (final achievement in _userAchievements)
        achievement.id: AchievementProgress(
          currentValue: achievement.currentValue,
          isUnlocked: achievement.isUnlocked,
          unlockedAt: achievement.unlockedAt,
        ),
    };
  }

  List<Achievement> _mergeWithCatalog(
    Map<String, AchievementProgress> userProgress,
  ) {
    return AchievementsCatalog.allAchievements.map((catalogAchievement) {
      final progress = userProgress[catalogAchievement.id];

      if (progress != null) {
        return catalogAchievement.copyWith(
          currentValue: progress.currentValue,
          isUnlocked: progress.isUnlocked,
          unlockedAt: progress.unlockedAt,
        );
      }

      return catalogAchievement;
    }).toList();
  }

  Future<void> _persistSnapshot() async {
    final snapshot = AchievementsSnapshot(entries: _snapshotFromAchievements());
    await _repository.saveRemoteSnapshot(
      _userId,
      snapshot,
      totalXp: getTotalXp(),
      unlockedCount: getUnlockedCount(),
    );
  }

  List<Achievement> getUserAchievements() {
    if (!_isInitialized) {
      return AchievementsCatalog.allAchievements;
    }
    return _userAchievements;
  }

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

  List<Achievement> getUnlockedAchievements() {
    return _userAchievements.where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getNearCompletionAchievements() {
    return _userAchievements
        .where((a) => !a.isUnlocked && a.progress >= 0.8)
        .toList();
  }

  int getTotalXp() {
    return _userAchievements
        .where((a) => a.isUnlocked)
        .fold(0, (total, a) => total + a.xpReward);
  }

  int getUnlockedCount() {
    return _userAchievements.where((a) => a.isUnlocked).length;
  }

  double getCompletionPercentage() {
    if (_userAchievements.isEmpty) return 0.0;
    return getUnlockedCount() / _userAchievements.length;
  }

  Future<List<Achievement>> processRunForAchievements(Run run) async {
    if (!_isInitialized) await initialize();

    final newlyUnlocked = <Achievement>[];

    newlyUnlocked.addAll(await _updateDistanceAchievements(run.distanceMeters));
    newlyUnlocked.addAll(await _updateRunCountAchievements());

    if (run.avgSpeedKmh > 0) {
      newlyUnlocked.addAll(await _updateSpeedAchievements(run.avgSpeedKmh));
    }

    if (run.territoryCovered > 0) {
      newlyUnlocked.addAll(
        await _updateTerritoryAchievements(run.territoryCovered),
      );
    }

    newlyUnlocked.addAll(await _updateMilestoneAchievements(run));

    if (newlyUnlocked.isNotEmpty) {
      await _persistSnapshot();
      await _repository.saveCachedSnapshot(
        _userId,
        AchievementsSnapshot(entries: _snapshotFromAchievements()),
      );
    }

    return newlyUnlocked;
  }

  Future<List<Achievement>> _updateDistanceAchievements(
      double distanceMeters) async {
    final newlyUnlocked = <Achievement>[];
    final increment = distanceMeters.toInt();

    for (int i = 0; i < _userAchievements.length; i++) {
      final achievement = _userAchievements[i];
      if (achievement.type == AchievementType.distance && !achievement.isUnlocked) {
        final nextValue =
            (achievement.currentValue + increment).clamp(0, 1 << 31);
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

  Future<List<Achievement>> _updateTerritoryAchievements(
      double territoryCovered) async {
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

  Future<List<Achievement>> _updateMilestoneAchievements(Run run) async {
    final newlyUnlocked = <Achievement>[];
    final runTime = run.startTime;

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
        final index =
            _userAchievements.indexWhere((a) => a.id == 'challenge_5k_under_30');
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

  Future<Achievement?> unlockSocialAchievement(String achievementId) async {
    if (!_isInitialized) await initialize();

    final index = _userAchievements.indexWhere((a) => a.id == achievementId);

    if (index != -1 && !_userAchievements[index].isUnlocked) {
      _userAchievements[index] = _userAchievements[index].copyWith(
        currentValue: _userAchievements[index].requiredValue,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      await _persistSnapshot();
      await _repository.saveCachedSnapshot(
        _userId,
        AchievementsSnapshot(entries: _snapshotFromAchievements()),
      );

      return _userAchievements[index];
    }

    return null;
  }
}
