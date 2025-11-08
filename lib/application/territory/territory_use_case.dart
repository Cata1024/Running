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
  Territory? _cached;

  Future<Territory?> fetchTerritory({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) {
      return _cached;
    }
    _cached = await _repository.fetchTerritory(_userId);
    return _cached;
  }

  Future<Territory> mergeAndSaveFromTrack({
    required List<TrackPoint> track,
  }) async {
    final polygon = _geometryService.buildPolygonFromTrack(track);
    final area = _geometryService.polygonAreaM2(polygon);
    return mergeAndSaveFromPolygon(
      newPolygon: polygon,
      areaGainedM2: area,
    );
  }

  Future<Territory> mergeAndSaveFromPolygon({
    required Map<String, dynamic> newPolygon,
    required double areaGainedM2,
  }) async {
    final existing = await fetchTerritory();
    final merged = _geometryService.mergeTerritory(
      existing: existing,
      userId: _userId,
      newPolygon: newPolygon,
      areaGainedM2: areaGainedM2,
    );
    await _repository.upsertTerritory(_userId, merged);
    _cached = merged;
    return merged;
  }
}
