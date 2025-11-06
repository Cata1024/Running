import '../entities/territory.dart';

/// Contract isolating persistence for territory aggregation.
abstract class ITerritoryRepository {
  Future<Territory?> fetchTerritory(String userId);

  Future<void> upsertTerritory(
    String userId,
    Territory territory,
  );
}
