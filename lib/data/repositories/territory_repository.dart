import '../services/api_service.dart';
import '../../domain/entities/territory.dart';
import '../../domain/repositories/i_territory_repository.dart';

class TerritoryRepository implements ITerritoryRepository {
  TerritoryRepository({required ApiService apiService}) : _apiService = apiService;

  final ApiService _apiService;

  @override
  Future<Territory?> fetchTerritory(String userId) async {
    final map = await _apiService.fetchTerritory(userId);
    if (map == null) return null;
    return Territory.fromMap(userId, map);
  }

  @override
  Future<void> upsertTerritory(String userId, Territory territory) async {
    await _apiService.upsertTerritory(userId, territory.toPersistenceMap());
  }
}
