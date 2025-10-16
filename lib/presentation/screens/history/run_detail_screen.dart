import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_providers.dart';
import '../../../core/map_styles.dart';
import '../../../core/widgets/glass_container.dart';

class RunDetailScreen extends ConsumerWidget {
  final String runId;
  const RunDetailScreen({super.key, required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRun = ref.watch(runDocProvider(runId));
    final theme = Theme.of(context);
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
                  final text = 'Mi carrera${date != null ? ' del ${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}' : ''}: ' 
                      '${(distanceM/1000).toStringAsFixed(2)} km en ' 
                      '${fmt(durationS)} (ritmo ${RunDetailScreen._pace(distanceM, durationS)} min/km)';
                  Share.share(text);
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncRun.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Carrera no encontrada'));
          }

          final route = _parseLineString(data['routeGeoJson']);
          final polygon = _parsePolygon(data['polygonGeoJson']);

          final markers = <Marker>{};
          if (route.isNotEmpty) {
            markers.add(Marker(markerId: const MarkerId('start'), position: route.first));
            markers.add(Marker(markerId: const MarkerId('end'), position: route.last));
          }

          final polylines = route.length > 1
              ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: route,
                    color: theme.colorScheme.primary,
                    width: 5,
                  ),
                }
              : <Polyline>{};

          final polygons = polygon.isNotEmpty
              ? {
                  Polygon(
                    polygonId: const PolygonId('area'),
                    points: polygon,
                    strokeWidth: 3,
                    strokeColor: theme.colorScheme.secondary,
                    fillColor: theme.colorScheme.secondary.withOpacity(0.25),
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
                mapType: MapType.normal,
                onMapCreated: (ctrl) async {
                  mapController = ctrl;
                  if (Theme.of(context).brightness == Brightness.dark) {
                    mapController?.setMapStyle(MapStyles.dark);
                  } else {
                    mapController?.setMapStyle(MapStyles.light);
                  }
                  if (bounds != null) {
                    await Future.delayed(const Duration(milliseconds: 100));
                    await mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                  }
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Info('Distancia', '${(distanceM / 1000).toStringAsFixed(2)} km', Icons.route),
                      _Info('Tiempo', fmt(durationS), Icons.timer),
                      _Info('Ritmo', _pace(distanceM, durationS), Icons.speed),
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

class _Info extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Info(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
