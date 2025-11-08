import '../constants/level_system.dart';
import '../entities/level_progress.dart';
import '../repositories/i_level_progress_repository.dart';

/// Servicio para gestionar niveles y XP del usuario sin exponer Firebase.
class LevelService {
  LevelService(this._repository);

  final ILevelProgressRepository _repository;

  /// Añade XP al usuario y verifica si subió de nivel.
  /// Retorna el nuevo nivel si cambió, null si no.
  Future<LevelUpResult?> addXP(String userId, int xpToAdd) async {
    try {
      final previousSnapshot = await _repository.fetchProgress(userId);
      final updatedSnapshot = await _repository.incrementXp(
        userId: userId,
        xpDelta: xpToAdd,
      );

      if (updatedSnapshot.level > previousSnapshot.level) {
        final reward = LevelSystem.getRewardForLevel(updatedSnapshot.level);
        final result = LevelUpResult(
          oldLevel: previousSnapshot.level,
          newLevel: updatedSnapshot.level,
          xpGained: xpToAdd,
          totalXP: updatedSnapshot.totalXp,
          reward: reward,
        );

        if (reward != null && reward.bonusXP > 0) {
          await _repository.incrementXp(
            userId: userId,
            xpDelta: reward.bonusXP,
          );
        }

        await _repository.saveMilestone(
          userId,
          LevelMilestoneEntry(
            oldLevel: previousSnapshot.level,
            newLevel: updatedSnapshot.level,
            xpGained: xpToAdd,
            totalXp: updatedSnapshot.totalXp,
            rewardType: reward?.type,
            achievedAt: DateTime.now(),
          ),
        );

        return result;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el nivel actual del usuario
  Future<UserLevel> getUserLevel(String userId) async {
    try {
      final snapshot = await _repository.fetchProgress(userId);
      return UserLevel.fromTotalXP(snapshot.totalXp);
    } catch (_) {
      final cached = await _repository.readCachedProgress(userId);
      final fallback = cached ?? LevelProgressSnapshot.initial;
      return UserLevel.fromTotalXP(fallback.totalXp);
    }
  }

  /// Obtiene el nivel del cache local (más rápido)
  Future<UserLevel> getCachedLevel(String userId) async {
    final cached = await _repository.readCachedProgress(userId);
    final snapshot = cached ?? LevelProgressSnapshot.initial;
    return UserLevel.fromTotalXP(snapshot.totalXp);
  }

  /// Inicializa el nivel de un nuevo usuario
  Future<void> initializeUserLevel(String userId) async {
    await _repository.initializeUser(userId);
  }

  /// Obtiene el historial de niveles alcanzados
  Future<List<LevelMilestoneEntry>> getLevelHistory(String userId) async {
    try {
      return await _repository.fetchRecentMilestones(userId);
    } catch (_) {
      return const [];
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
