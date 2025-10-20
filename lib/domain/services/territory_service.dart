import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:turf/turf.dart' as turf;

class TerritoryService {
  const TerritoryService();

  Map<String, dynamic> buildPolygonFromRoute(List<LatLng> routePoints) {
    // Deduplicate consecutive points
    final List<List<double>> coords = [];
    for (final p in routePoints) {
      final c = [p.longitude, p.latitude];
      if (coords.isEmpty || coords.last[0] != c[0] || coords.last[1] != c[1]) {
        coords.add(c);
      }
    }
    if (coords.length < 3) {
      return {
        'type': 'Polygon',
        'coordinates': []
      };
    }
    // Ensure closed ring
    if (coords.first[0] != coords.last[0] || coords.first[1] != coords.last[1]) {
      coords.add([coords.first[0], coords.first[1]]);
    }

    // Enforce CCW orientation for outer ring
    try {
      final positions = coords.map((c) => turf.Position(c[0], c[1])).toList();
      final ls = turf.LineString(coordinates: positions);
      final isClockwise = turf.booleanClockwise(ls);
      if (isClockwise) {
        // Reverse without duplicating the first/last
        final ring = positions.sublist(0, positions.length - 1).reversed
            .map((p) => [p.lng, p.lat]).toList();
        ring.add(ring.first);
        return {
          'type': 'Polygon',
          'coordinates': [ring],
        };
      }
    } catch (_) {}

    return {
      'type': 'Polygon',
      'coordinates': [coords],
    };
  }

  double polygonAreaM2(Map<String, dynamic> polygonGeoJson) {
    try {
      final rings = (polygonGeoJson['coordinates'] as List?) ?? const [];
      if (rings.isEmpty) return 0.0;
      final List<turf.Position> positions = (rings.first as List)
          .map<turf.Position>((c) => turf.Position((c[0] as num).toDouble(), (c[1] as num).toDouble()))
          .toList();
      final poly = turf.Polygon(coordinates: [positions]);
      final feature = turf.Feature<turf.Polygon>(geometry: poly);
      final a = turf.area(feature);
      return (a ?? 0).toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  Map<String, dynamic> mergeTerritory({
    Map<String, dynamic>? existing,
    required Map<String, dynamic> newPolygon,
    required double areaGainedM2,
  }) {
    Map<String, dynamic>? existingGeoJson = existing?['unionGeoJson'];
    Map<String, dynamic> unionGeoJson;

    if (existingGeoJson == null) {
      unionGeoJson = newPolygon;
    } else if (existingGeoJson['type'] == 'Polygon') {
      unionGeoJson = {
        'type': 'MultiPolygon',
        'coordinates': [existingGeoJson['coordinates'], newPolygon['coordinates']],
      };
    } else if (existingGeoJson['type'] == 'MultiPolygon') {
      final List<dynamic> coords = List<dynamic>.from(existingGeoJson['coordinates']);
      coords.add(newPolygon['coordinates']);
      unionGeoJson = {
        'type': 'MultiPolygon',
        'coordinates': coords,
      };
    } else {
      unionGeoJson = newPolygon;
    }

    final totalArea = _geoJsonArea(unionGeoJson);

    final updated = <String, dynamic>{
      if (existing?['createdAt'] != null) 'createdAt': existing!['createdAt'],
      'unionGeoJson': unionGeoJson,
      'totalAreaM2': totalArea,
      'updatedAt': DateTime.now().toIso8601String(),
      'lastAreaGainM2': areaGainedM2,
    };

    return updated;
  }

  double _geoJsonArea(Map<String, dynamic> geojson) {
    try {
      final type = geojson['type'];
      if (type == 'Polygon') {
        return polygonAreaM2(geojson);
      } else if (type == 'MultiPolygon') {
        final List polys = geojson['coordinates'] as List? ?? const [];
        double sum = 0.0;
        for (final polyCoords in polys) {
          final poly = {
            'type': 'Polygon',
            'coordinates': polyCoords,
          };
          sum += polygonAreaM2(poly);
        }
        return sum;
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
