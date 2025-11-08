import '../constants/level_system.dart';

/// Immutable snapshot describing the current level progression for a user.
class LevelProgressSnapshot {
  const LevelProgressSnapshot({
    required this.level,
    required this.totalXp,
    this.updatedAt,
    this.cachedAt,
  });

  /// Current level reached by the user.
  final int level;

  /// Total accumulated XP that produced [level].
  final int totalXp;

  /// Last time the backend reported this progression.
  final DateTime? updatedAt;

  /// Timestamp when this snapshot was cached locally.
  final DateTime? cachedAt;

  static const LevelProgressSnapshot initial = LevelProgressSnapshot(
    level: 1,
    totalXp: 0,
  );

  LevelProgressSnapshot copyWith({
    int? level,
    int? totalXp,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) {
    return LevelProgressSnapshot(
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  /// Convenience getter exposing remaining XP to next level using [LevelSystem].
  int get xpToNextLevel => LevelSystem.xpToNextLevel(totalXp);

  /// Progress ratio (0-1) towards the following level.
  double get progressToNextLevel => LevelSystem.progressToNextLevel(totalXp);
}

/// Historic entry describing a level-up event stored by the backend.
class LevelMilestoneEntry {
  const LevelMilestoneEntry({
    required this.oldLevel,
    required this.newLevel,
    required this.xpGained,
    required this.totalXp,
    this.rewardType,
    this.achievedAt,
  });

  final int oldLevel;
  final int newLevel;
  final int xpGained;
  final int totalXp;

  /// Optional reward identifier associated to this milestone.
  final RewardType? rewardType;

  /// Moment when the backend persisted this milestone.
  final DateTime? achievedAt;

  LevelMilestoneEntry copyWith({
    int? oldLevel,
    int? newLevel,
    int? xpGained,
    int? totalXp,
    RewardType? rewardType,
    DateTime? achievedAt,
  }) {
    return LevelMilestoneEntry(
      oldLevel: oldLevel ?? this.oldLevel,
      newLevel: newLevel ?? this.newLevel,
      xpGained: xpGained ?? this.xpGained,
      totalXp: totalXp ?? this.totalXp,
      rewardType: rewardType ?? this.rewardType,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }
}
