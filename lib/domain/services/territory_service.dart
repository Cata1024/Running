import 'package:turf/turf.dart' as turf;

import '../entities/territory.dart';
import '../track_processing/track_processing.dart';

class TerritoryService {
  const TerritoryService();

  Map<String, dynamic> buildLineStringFromTrack(List<TrackPoint> track) {
    final coordinates = track
        .map((point) => [point.lon, point.lat])
        .toList(growable: false);
    return {
      'type': 'LineString',
      'coordinates': coordinates,
    };
  }

  Map<String, dynamic> buildPolygonFromTrack(List<TrackPoint> track) {
    final coordinates = <List<double>>[];
    for (final point in track) {
      final coord = [point.lon, point.lat];
      if (coordinates.isEmpty ||
          coordinates.last[0] != coord[0] ||
          coordinates.last[1] != coord[1]) {
        coordinates.add(coord);
      }
    }

    if (coordinates.length < 3) {
      return {
        'type': 'Polygon',
        'coordinates': [],
      };
    }

    if (coordinates.first[0] != coordinates.last[0] ||
        coordinates.first[1] != coordinates.last[1]) {
      coordinates.add([coordinates.first[0], coordinates.first[1]]);
    }

    try {
      final positions =
          coordinates.map((c) => turf.Position(c[0], c[1])).toList();
      final lineString = turf.LineString(coordinates: positions);
      final isClockwise = turf.booleanClockwise(lineString);
      if (isClockwise) {
        final reversed = positions
            .sublist(0, positions.length - 1)
            .reversed
            .map((p) => [p.lng, p.lat])
            .toList();
        reversed.add(reversed.first);
        return {
          'type': 'Polygon',
          'coordinates': [reversed],
        };
      }
    } catch (_) {}

    return {
      'type': 'Polygon',
      'coordinates': [coordinates],
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

  Territory mergeTerritory({
    Territory? existing,
    required String userId,
    required Map<String, dynamic> newPolygon,
    required double areaGainedM2,
  }) {
    final unionGeoJson = _mergeGeoJson(existing?.unionGeoJson, newPolygon);
    final totalArea = _geoJsonArea(unionGeoJson);

    return Territory(
      id: existing?.id ?? userId,
      unionGeoJson: unionGeoJson,
      totalAreaM2: totalArea,
      lastAreaGainM2: areaGainedM2,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _mergeGeoJson(
    Map<String, dynamic>? existingGeoJson,
    Map<String, dynamic> newPolygon,
  ) {
    if (existingGeoJson == null || existingGeoJson.isEmpty) {
      return newPolygon;
    }

    if (existingGeoJson['type'] == 'Polygon') {
      return {
        'type': 'MultiPolygon',
        'coordinates': [existingGeoJson['coordinates'], newPolygon['coordinates']],
      };
    }

    if (existingGeoJson['type'] == 'MultiPolygon') {
      final List<dynamic> coords = List<dynamic>.from(existingGeoJson['coordinates']);
      coords.add(newPolygon['coordinates']);
      return {
        'type': 'MultiPolygon',
        'coordinates': coords,
      };
    }

    return newPolygon;
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
