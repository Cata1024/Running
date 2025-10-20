import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/app_providers.dart';
import '../../utils/map_style_utils.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/theme/app_theme.dart';

class RunDetailScreen extends ConsumerWidget {
  final String runId;
  const RunDetailScreen({super.key, required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRun = ref.watch(runDocProvider(runId));
    final theme = Theme.of(context);
    final mapType = ref.watch(mapTypeProvider);
    final stylePref = ref.watch(mapStyleProvider);
    final styleString = resolveMapStyle(stylePref, theme.brightness);
    final iconsAsync = ref.watch(mapIconsProvider);
    GoogleMapController? mapController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de carrera'),
        centerTitle: true,
        actions: [
          asyncRun.maybeWhen(
            data: (data) {
              if (data == null) return const SizedBox.shrink();
              final distanceM = (data['distanceM'] as num?)?.toDouble() ?? 0.0;
              final durationS = (data['durationS'] as num?)?.toInt() ?? 0;
              final startedAtStr = data['startedAt'] as String?;
              final date = startedAtStr != null ? DateTime.tryParse(startedAtStr) : null;
              String fmt(int s) {
                final h = (s ~/ 3600).toString().padLeft(2, '0');
                final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
                final sec = (s % 60).toString().padLeft(2, '0');
                return '$h:$m:$sec';
              }
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final dateSuffix = date != null
                      ? ' del ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                      : '';
                  final text =
                      'Mi carrera$dateSuffix: ${(distanceM / 1000).toStringAsFixed(2)} km en ${fmt(durationS)} (ritmo ${RunDetailScreen._pace(distanceM, durationS)} min/km)';
                  SharePlus.instance.share(
                    ShareParams(text: text),
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncRun.when(
        loading: () => const LoadingState(message: 'Cargando detalles...'),
        error: (e, st) => ErrorState(
          message: 'No se pudo cargar la carrera',
          onRetry: () => ref.invalidate(runDocProvider(runId)),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Carrera no encontrada'));
          }

          final route = _parseLineString(data['routeGeoJson']);
          final polygon = _parsePolygon(data['polygonGeoJson']);

          final icons = iconsAsync.maybeWhen(
            data: (bundle) => bundle,
            orElse: () => null,
          );

          final markers = <Marker>{};
          if (route.isNotEmpty) {
            markers.add(
              Marker(
                markerId: const MarkerId('start'),
                position: route.first,
                infoWindow: const InfoWindow(title: 'Inicio de la carrera'),
                icon: icons?.start ?? BitmapDescriptor.defaultMarkerWithHue(110),
              ),
            );
            markers.add(
              Marker(
                markerId: const MarkerId('end'),
                position: route.last,
                infoWindow: const InfoWindow(title: 'Fin de la carrera'),
                icon: icons?.finish ?? BitmapDescriptor.defaultMarkerWithHue(0),
              ),
            );
          }

          final polylines = route.length > 1
              ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: route,
                    color: theme.colorScheme.primary,
                    width: 6,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                  ),
                }
              : const <Polyline>{};

          final polygons = polygon.isNotEmpty
              ? {
                  Polygon(
                    polygonId: const PolygonId('area'),
                    points: polygon,
                    strokeWidth: 3,
                    strokeColor: theme.colorScheme.secondary,
                    fillColor: theme.colorScheme.secondary.withValues(alpha: 0.25),
                  ),
                }
              : <Polygon>{};

          final bounds = _computeBounds(route.isNotEmpty ? route : polygon);
          final initialTarget = bounds == null
              ? (route.isNotEmpty ? route.first : const LatLng(4.6097, -74.0817))
              : LatLng(
                  (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                  (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                );

          final distanceM = (data['distanceM'] as num?)?.toDouble() ?? 0.0;
          final durationS = (data['durationS'] as num?)?.toInt() ?? 0;
          String fmt(int s) {
            final h = (s ~/ 3600).toString().padLeft(2, '0');
            final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
            final sec = (s % 60).toString().padLeft(2, '0');
            return '$h:$m:$sec';
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: initialTarget, zoom: 14),
                markers: markers,
                polylines: polylines,
                polygons: polygons,
                mapType: mapType,
                style: styleString,
                onMapCreated: (ctrl) async {
                  mapController = ctrl;
                  if (bounds != null) {
                    await Future.delayed(const Duration(milliseconds: 100));
                    await mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                  }
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              // Header con fecha y badge
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.95),
                  child: _buildHeader(data, theme),
                ),
              ),
              // Stats mejorados
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.95),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            icon: Icons.route,
                            value: (distanceM / 1000).toStringAsFixed(2),
                            unit: 'km',
                            label: 'Distancia',
                          ),
                          _StatItem(
                            icon: Icons.timer,
                            value: fmt(durationS),
                            unit: '',
                            label: 'Tiempo',
                          ),
                          _StatItem(
                            icon: Icons.speed,
                            value: _pace(distanceM, durationS),
                            unit: 'min/km',
                            label: 'Ritmo',
                          ),
                        ],
                      ),
                      if (data['isClosedCircuit'] == true && data['areaGainedM2'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.successColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Territorio ganado: ${((data['areaGainedM2'] as num) / 1000000).toStringAsFixed(3)} km²',
                                style: TextStyle(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.bold,
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
            ],
          );
        },
      ),
    );
  }

  static Widget _buildHeader(Map<String, dynamic> data, ThemeData theme) {
    final startedAtStr = data['startedAt'] as String?;
    final date = startedAtStr != null ? DateTime.tryParse(startedAtStr) : null;
    final isClosedCircuit = data['isClosedCircuit'] == true;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date != null
                    ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                    : 'Carrera',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (date != null)
                Text(
                  '${_getWeekday(date.weekday)} • ${_getTimeOfDay(date)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (isClosedCircuit)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Circuito Cerrado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _getWeekday(int weekday) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  static String _getTimeOfDay(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _pace(double distanceM, int durationS) {
    if (distanceM <= 0 || durationS <= 0) return '--:--';
    final km = distanceM / 1000.0;
    final paceSec = durationS / km;
    final m = (paceSec / 60).floor();
    final s = (paceSec % 60).round().toString().padLeft(2, '0');
    return '$m:$s';
  }

  static List<LatLng> _parseLineString(dynamic geojson) {
    // Si es un string, parsearlo primero
    if (geojson is String) {
      try {
        geojson = jsonDecode(geojson);
      } catch (e) {
        return const [];
      }
    }
    
    if (geojson is Map && geojson['type'] == 'LineString') {
      final coords = (geojson['coordinates'] as List?) ?? const [];
      return coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    }
    return const [];
  }

  static List<LatLng> _parsePolygon(dynamic geojson) {
    // Si es un string, parsearlo primero
    if (geojson is String) {
      try {
        geojson = jsonDecode(geojson);
      } catch (e) {
        return const [];
      }
    }
    
    if (geojson is Map && geojson['type'] == 'Polygon') {
      final rings = (geojson['coordinates'] as List?) ?? const [];
      if (rings.isEmpty) return const [];
      final outer = rings.first as List;
      return outer
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    }
    return const [];
  }

  static LatLngBounds? _computeBounds(List<LatLng> pts) {
    if (pts.isEmpty) return null;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  
  const _StatItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
