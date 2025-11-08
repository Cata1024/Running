import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/territory/territory_use_case.dart';
import '../../data/models/territory_dto.dart';
import '../../data/repositories/territory_repository.dart';
import '../../domain/entities/territory.dart';
import '../../domain/repositories/i_territory_repository.dart';
import 'app_providers.dart';

final territoryRepositoryProvider = Provider<ITerritoryRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return TerritoryRepository(apiService: api);
});

final territoryUseCaseProvider = FutureProvider.autoDispose<TerritoryUseCase>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) {
    throw StateError('Usuario no autenticado');
  }

  final repository = ref.watch(territoryRepositoryProvider);
  final useCase = TerritoryUseCase(
    userId: user.uid,
    repository: repository,
  );
  await useCase.fetchTerritory(forceRefresh: true);
  return useCase;
});

final userTerritoryProvider = FutureProvider.autoDispose<Territory?>((ref) async {
  final useCase = await ref.watch(territoryUseCaseProvider.future);
  return useCase.fetchTerritory();
});

final userTerritoryDtoProvider = FutureProvider.autoDispose<TerritoryDto?>((ref) async {
  final territory = await ref.watch(userTerritoryProvider.future);
  if (territory == null) return null;
  return mapTerritoryToDto(territory);
});

TerritoryDto mapTerritoryToDto(Territory territory) {
  return TerritoryDto(
    id: territory.id,
    unionGeoJson: territory.unionGeoJson,
    totalAreaM2: territory.totalAreaM2,
    lastAreaGainM2: territory.lastAreaGainM2,
    createdAt: territory.createdAt,
    updatedAt: territory.updatedAt,
  );
}
