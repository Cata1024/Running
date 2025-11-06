import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/design_system/territory_tokens.dart';
import '../../providers/app_providers.dart';
import '../../../data/models/territory_dto.dart';

/// Pantalla para visualizar el territorio conquistado en un mapa
class TerritoryMapScreen extends ConsumerStatefulWidget {
  const TerritoryMapScreen({super.key});

  @override
  ConsumerState<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends ConsumerState<TerritoryMapScreen> {
  GoogleMapController? _mapController;
  Set<Polygon> _territoryPolygons = {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final territoryAsync = ref.watch(userTerritoryDtoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Territorio'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userTerritoryDtoProvider);
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: territoryAsync.when(
        data: (territory) {
          if (territory == null || territory.unionGeoJson == null) {
            return _buildEmptyState(theme);
          }

          // Parsear territorio y crear polígonos
          _territoryPolygons = _parseTerritoryPolygons(territory, theme);

          // Calcular bounds para centrar el mapa
          final bounds = _calculateBounds(_territoryPolygons);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: bounds.center,
                  zoom: 14,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Ajustar cámara a los bounds del territorio
                  if (_territoryPolygons.isNotEmpty) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds.latLngBounds, 50),
                    );
                  }
                },
                polygons: _territoryPolygons,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              // Stats overlay
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildStatsCard(territory, theme),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Cargando territorio...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar territorio',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustración con gradiente
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    theme.colorScheme.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    Positioned(
                      top: 40,
                      right: 50,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      left: 60,
                      child: Icon(
                        Icons.flag,
                        size: 35,
                        color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '🗺️',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Aún no has conquistado territorio!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completa un circuito cerrado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Corre en círculo y vuelve al punto de inicio para conquistar tu primer territorio.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.directions_run),
              label: const Text('¡Empezar a conquistar!'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(TerritoryDto territory, ThemeData theme) {
    final totalAreaM2 = territory.totalAreaM2 ?? 0.0;
    final totalAreaKm2 = totalAreaM2 / 1e6;
    final lastGainM2 = territory.lastAreaGainM2 ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.95),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.terrain,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Territorio Total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${totalAreaKm2.toStringAsFixed(3)} km²',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lastGainM2 > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${(lastGainM2 / 1e6).toStringAsFixed(4)} km² última carrera',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
          ),
        ),
      ),
    );
  }

  Set<Polygon> _parseTerritoryPolygons(
    TerritoryDto territory,
    ThemeData theme,
  ) {
    final dynamic geoDyn = territory.unionGeoJson;
    if (geoDyn is! Map<String, dynamic>) return <Polygon>{};
    final Map<String, dynamic> geo = geoDyn;

    final stroke = theme.colorScheme.primary;
    final fill = theme.colorScheme.primary.withValues(alpha: 0.25);

    final Set<Polygon> out = {};
    final type = geo['type'];

    if (type == 'Polygon') {
      final coords = (geo['coordinates'] as List?) ?? const [];
      if (coords.isEmpty) return out;
      final outer = coords.first as List;
      final pts = outer
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      if (pts.length >= 3) {
        out.add(Polygon(
          polygonId: const PolygonId('territory-0'),
          points: pts,
          strokeWidth: 3,
          strokeColor: stroke,
          fillColor: fill,
        ));
      }
    } else if (type == 'MultiPolygon') {
      final polys = (geo['coordinates'] as List?) ?? const [];
      for (int i = 0; i < polys.length; i++) {
        final poly = polys[i] as List;
        if (poly.isEmpty) continue;
        final outer = poly.first as List;
        final pts = outer
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        if (pts.length >= 3) {
          out.add(Polygon(
            polygonId: PolygonId('territory-$i'),
            points: pts,
            strokeWidth: 3,
            strokeColor: stroke,
            fillColor: fill,
          ));
        }
      }
    }
    return out;
  }

  _MapBounds _calculateBounds(Set<Polygon> polygons) {
    if (polygons.isEmpty) {
      return _MapBounds(
        center: const LatLng(4.6097, -74.0817), // Bogotá por defecto
        latLngBounds: LatLngBounds(
          southwest: const LatLng(4.5, -74.2),
          northeast: const LatLng(4.7, -74.0),
        ),
      );
    }

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final polygon in polygons) {
      for (final point in polygon.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    return _MapBounds(
      center: center,
      latLngBounds: LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
    );
  }
}

class _MapBounds {
  final LatLng center;
  final LatLngBounds latLngBounds;

  _MapBounds({required this.center, required this.latLngBounds});
}
