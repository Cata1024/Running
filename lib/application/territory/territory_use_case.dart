import '../../domain/entities/territory.dart';
import '../../domain/repositories/i_territory_repository.dart';
import '../../domain/services/territory_service.dart';
import '../../domain/track_processing/track_processing.dart';

class TerritoryUseCase {
  TerritoryUseCase({
    required String userId,
    required ITerritoryRepository repository,
    TerritoryService? geometryService,
  })  : _userId = userId,
        _repository = repository,
        _geometryService = geometryService ?? const TerritoryService();

  final String _userId;
  final ITerritoryRepository _repository;
  final TerritoryService _geometryService;

  Future<Territory?> fetchTerritory() async {
    return _repository.fetchTerritory(_userId);
  }

  Future<Territory> mergeAndSaveTerritory({
    required List<TrackPoint> track,
    required double areaGainedM2,
  }) async {
    final existing = await _repository.fetchTerritory(_userId);
    final polygon = _geometryService.buildPolygonFromTrack(track);
    final merged = _geometryService.mergeTerritory(
      existing: existing,
      userId: _userId,
      newPolygon: polygon,
      areaGainedM2: areaGainedM2,
    );
    await _repository.upsertTerritory(_userId, merged);
    return merged;
  }
}
