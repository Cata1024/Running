import '../entities/level_progress.dart';

/// Contract encapsulating persistence of level progression so the domain layer
/// stays decoupled from Firebase/SharedPreferences specifics.
abstract class ILevelProgressRepository {
  /// Fetch the authoritative progress snapshot for a user.
  Future<LevelProgressSnapshot> fetchProgress(String userId);

  /// Increment the user's XP atomically, returning the updated snapshot.
  Future<LevelProgressSnapshot> incrementXp({
    required String userId,
    required int xpDelta,
  });

  /// Ensure a newly registered user has baseline level data.
  Future<void> initializeUser(String userId);

  /// Retrieve cached progress when remote fetching fails or is unnecessary.
  Future<LevelProgressSnapshot?> readCachedProgress(String userId);

  /// Persist a snapshot locally for fast reads/offline usage.
  Future<void> saveCachedProgress(
    String userId,
    LevelProgressSnapshot snapshot,
  );

  /// Fetch the most recent level milestones achieved by the user.
  Future<List<LevelMilestoneEntry>> fetchRecentMilestones(
    String userId, {
    int limit = 20,
  });

  /// Store a new milestone event emitted by the level system.
  Future<void> saveMilestone(
    String userId,
    LevelMilestoneEntry milestone,
  );
}
