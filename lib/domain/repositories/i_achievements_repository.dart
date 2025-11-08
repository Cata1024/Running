/// Snapshot with the persisted progress for each achievement.
class AchievementsSnapshot {
  final Map<String, AchievementProgress> entries;

  const AchievementsSnapshot({required this.entries});

  AchievementProgress? operator [](String id) => entries[id];

  Map<String, AchievementProgress> toMap() => entries;

  static const empty = AchievementsSnapshot(entries: {});
}

class AchievementProgress {
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  AchievementProgress copyWith({
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// Contract to persist/read achievements progress without leaking
/// infrastructure details into the domain layer.
abstract class IAchievementsRepository {
  Future<AchievementsSnapshot> fetchRemoteSnapshot(String userId);

  Future<void> saveRemoteSnapshot(
    String userId,
    AchievementsSnapshot snapshot, {
    required int totalXp,
    required int unlockedCount,
  });

  Future<AchievementsSnapshot?> fetchCachedSnapshot(String userId);

  Future<void> saveCachedSnapshot(String userId, AchievementsSnapshot snapshot);

  /// Persist the baseline catalog so legacy services can migrate to the new
  /// snapshot-based flow without leaking Firebase concerns.
  Future<void> bootstrapCatalogIfNeeded(String userId);
}
