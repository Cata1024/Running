import 'dart:collection';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants.dart';
import '../../models/territory_models.dart';

class TerritoryRegion {
  final String id;
  final String ownerId;
  final List<String> tileKeys;
  final LatLng sw;
  final LatLng ne;

  const TerritoryRegion({
    required this.id,
    required this.ownerId,
    required this.tileKeys,
    required this.sw,
    required this.ne,
  });

  factory TerritoryRegion.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>; // ignore: cast_nullable_to_non_nullable
    final swMap = (data['bounds']?['sw'] ?? {}) as Map<String, dynamic>;
    final neMap = (data['bounds']?['ne'] ?? {}) as Map<String, dynamic>;
    return TerritoryRegion(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      tileKeys: List<String>.from(data['tileKeys'] ?? const []),
      sw: LatLng(
        (swMap['lat'] ?? 0.0).toDouble(),
        (swMap['lng'] ?? 0.0).toDouble(),
      ),
      ne: LatLng(
        (neMap['lat'] ?? 0.0).toDouble(),
        (neMap['lng'] ?? 0.0).toDouble(),
      ),
    );
  }
}

/// Servicio centralizado para gestionar la captura de territorio y sus vistas
/// derivadas (tiles y regiones) en Firestore.
class TerritoryService {
  TerritoryService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calcula un polígono utilizable y el área que encierra a partir de un polyline.
  TerritoryPolygonResult? deriveTerritoryFromPolyline({
    required List<LatLng> polyline,
    bool closePathIfNeeded = true,
  }) {
    if (polyline.length < 3) return null;

    final polygon = <LatLng>[...polyline];
    if (closePathIfNeeded && !_pointsApproximatelyEqual(polygon.first, polygon.last)) {
      polygon.add(polygon.first);
    }

    final area = _computePolygonAreaSquareMeters(polygon);
    if (area <= 0) return null;

    return TerritoryPolygonResult(
      polygon: List<LatLng>.unmodifiable(polygon),
      areaSquareMeters: area,
    );
  }

  /// Convierte un track en un conjunto de tiles reclamados.
  Future<Set<TerritoryTile>> computeTilesFromTrack({
    required List<LatLng> track,
    double tileSizeMeters = AppConstants.tileSize,
  }) async {
    if (track.length < 2) return {};

    final tiles = <String, TerritoryTile>{};
    for (final point in track) {
      final key = tileKeyForLatLng(point.latitude, point.longitude, tileSizeMeters);
      tiles.putIfAbsent(
        key,
        () => TerritoryTile(
          key: key,
          ownerId: '',
          centerLat: _tileCenterLat(key),
          centerLng: _tileCenterLng(key),
          tileSizeMeters: tileSizeMeters,
          updatedAt: DateTime.now(),
        ),
      );
    }
    return tiles.values.toSet();
  }

  /// Aplica tiles capturando o liberando territorio.
  Future<void> applyTiles({
    required String userId,
    required Set<TerritoryTile> tiles,
    required bool capture,
  }) async {
    final batch = _db.batch();
    final collection = _db.collection('territory');

    for (final tile in tiles) {
      final docRef = collection.doc(tile.key);
      if (capture) {
        batch.set(
          docRef,
          {
            'ownerId': userId,
            'centerLat': tile.centerLat,
            'centerLng': tile.centerLng,
            'tileSizeMeters': tile.tileSizeMeters,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.update(docRef, {
          'ownerId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    if (capture) {
      await _recomputeUserTerritories(userId);
    }
  }

  /// Stream de tiles capturados por un usuario.
  Stream<List<TerritoryTile>> watchUserTiles(String userId) {
    return _db
        .collection('territory')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TerritoryTile.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Stream de todos los tiles.
  Stream<List<TerritoryTile>> watchAllTiles() {
    return _db.collection('territory').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TerritoryTile.fromMap(doc.id, doc.data())).toList());
  }

  /// Stream de regiones agrupadas por usuario.
  Stream<List<TerritoryRegion>> watchUserRegions(String userId) {
    return _db
        .collection('territories')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TerritoryRegion.fromDoc).toList());
  }

  /// Stream de todas las regiones.
  Stream<List<TerritoryRegion>> watchAllRegions() {
    return _db
        .collection('territories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TerritoryRegion.fromDoc).toList());
  }

  /// Recalcula las agrupaciones de tiles por usuario y actualiza collection `territories`.
  Future<void> _recomputeUserTerritories(String userId) async {
    final tileDocs = await _db
        .collection('territory')
        .where('ownerId', isEqualTo: userId)
        .get();

    final territoriesCol = _db.collection('territories');

    if (tileDocs.docs.isEmpty) {
      final existing = await territoriesCol.where('ownerId', isEqualTo: userId).get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      return;
    }

    final keyToCenter = <String, LatLng>{};
    for (final doc in tileDocs.docs) {
      final key = doc.id;
      final data = doc.data();
      keyToCenter[key] = LatLng(
        (data['centerLat'] as num?)?.toDouble() ?? 0.0,
        (data['centerLng'] as num?)?.toDouble() ?? 0.0,
      );
    }

    final groups = _groupContiguousKeys(keyToCenter.keys);

    final batch = _db.batch();
    final existing = await territoriesCol.where('ownerId', isEqualTo: userId).get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final keys in groups) {
      final bounds = _computeBounds(keys, keyToCenter);
      final doc = territoriesCol.doc();
      batch.set(doc, {
        'ownerId': userId,
        'tileKeys': keys,
        'bounds': {
          'sw': {'lat': bounds.sw.latitude, 'lng': bounds.sw.longitude},
          'ne': {'lat': bounds.ne.latitude, 'lng': bounds.ne.longitude},
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // -------------------------------------------------------------------------
  // Helpers de tiles y geometría

  String tileKeyForLatLng(double lat, double lng, double tileSizeMeters) {
    final mercator = _mercatorFromLatLng(lat, lng);
    final x = (mercator.x / tileSizeMeters).floor();
    final y = (mercator.y / tileSizeMeters).floor();
    return 'm_${tileSizeMeters.toStringAsFixed(0)}_${x}_$y';
  }

  double _tileCenterLat(String key) {
    final parts = key.split('_');
    final size = double.parse(parts[1]);
    final x = int.parse(parts[2]);
    final y = int.parse(parts[3]);
    final mercatorX = (x + 0.5) * size;
    final mercatorY = (y + 0.5) * size;
    return _latLngFromMercator(mercatorX, mercatorY).lat;
  }

  double _tileCenterLng(String key) {
    final parts = key.split('_');
    final size = double.parse(parts[1]);
    final x = int.parse(parts[2]);
    final y = int.parse(parts[3]);
    final mercatorX = (x + 0.5) * size;
    final mercatorY = (y + 0.5) * size;
    return _latLngFromMercator(mercatorX, mercatorY).lng;
  }

  List<List<String>> _groupContiguousKeys(Iterable<String> keysIterable) {
    final keys = keysIterable.toSet();
    final visited = <String>{};
    final groups = <List<String>>[];

    int getX(String key) => int.parse(key.split('_')[2]);
    int getY(String key) => int.parse(key.split('_')[3]);

    for (final key in keys) {
      if (visited.contains(key)) continue;
      final queue = Queue<String>()..add(key);
      final group = <String>[];
      visited.add(key);

      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        group.add(current);

        final parts = current.split('_');
        final sizeStr = parts[1];
        final cx = getX(current);
        final cy = getY(current);

        final neighbors = [
          'm_${sizeStr}_${cx - 1}_$cy',
          'm_${sizeStr}_${cx + 1}_$cy',
          'm_${sizeStr}_${cx}_${cy - 1}',
          'm_${sizeStr}_${cx}_${cy + 1}',
        ];

        for (final neighbor in neighbors) {
          if (!visited.contains(neighbor) && keys.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }

      groups.add(group);
    }

    return groups;
  }

  _Bounds _computeBounds(List<String> keys, Map<String, LatLng> keyToCenter) {
    double minLat = double.infinity;
    double minLng = double.infinity;
    double maxLat = -double.infinity;
    double maxLng = -double.infinity;

    for (final key in keys) {
      final center = keyToCenter[key]!;
      minLat = math.min(minLat, center.latitude);
      minLng = math.min(minLng, center.longitude);
      maxLat = math.max(maxLat, center.latitude);
      maxLng = math.max(maxLng, center.longitude);
    }

    return _Bounds(
      sw: LatLng(minLat, minLng),
      ne: LatLng(maxLat, maxLng),
    );
  }

  _MetersPoint _mercatorFromLatLng(double lat, double lng) {
    const radius = 6378137.0;
    final x = radius * _degToRad(lng);
    final y = radius * math.log(math.tan(math.pi / 4 + _degToRad(lat) / 2));
    return _MetersPoint(x, y);
  }

  _GeoPoint _latLngFromMercator(double x, double y) {
    const radius = 6378137.0;
    final lng = _radToDeg(x / radius);
    final lat = _radToDeg(2 * math.atan(math.exp(y / radius)) - math.pi / 2);
    return _GeoPoint(lat, lng);
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  double _radToDeg(double rad) => rad * 180.0 / math.pi;

  double _computePolygonAreaSquareMeters(List<LatLng> polygon) {
    if (polygon.length < 3) return 0;

    final projected =
        polygon.map((p) => _mercatorFromLatLng(p.latitude, p.longitude)).toList();
    double sum = 0;

    for (var i = 0; i < projected.length; i++) {
      final nextIndex = (i + 1) % projected.length;
      final current = projected[i];
      final next = projected[nextIndex];
      sum += (current.x * next.y) - (next.x * current.y);
    }

    return sum.abs() * 0.5;
  }

  bool _pointsApproximatelyEqual(LatLng a, LatLng b, {double tolerance = 1e-6}) {
    return (a.latitude - b.latitude).abs() <= tolerance &&
        (a.longitude - b.longitude).abs() <= tolerance;
  }
}

// Riverpod providers --------------------------------------------------------

final territoryServiceProvider = Provider<TerritoryService>((ref) => TerritoryService());

final myTerritoryTilesProvider =
    StreamProvider.family<List<TerritoryTile>, String>((ref, userId) {
  final service = ref.watch(territoryServiceProvider);
  return service.watchUserTiles(userId);
});

final allTerritoryTilesProvider = StreamProvider<List<TerritoryTile>>((ref) {
  final service = ref.watch(territoryServiceProvider);
  return service.watchAllTiles();
});

final userTerritoriesProvider =
    StreamProvider.family<List<TerritoryRegion>, String>((ref, userId) {
  final service = ref.watch(territoryServiceProvider);
  return service.watchUserRegions(userId);
});

final allTerritoriesProvider = StreamProvider<List<TerritoryRegion>>((ref) {
  final service = ref.watch(territoryServiceProvider);
  return service.watchAllRegions();
});

// ---------------------------------------------------------------------------
// Helpers value types

class TerritoryPolygonResult {
  final List<LatLng> polygon;
  final double areaSquareMeters;

  const TerritoryPolygonResult({
    required this.polygon,
    required this.areaSquareMeters,
  });
}

class _MetersPoint {
  final double x;
  final double y;
  const _MetersPoint(this.x, this.y);
}

class _GeoPoint {
  final double lat;
  final double lng;
  const _GeoPoint(this.lat, this.lng);
}

class _Bounds {
  final LatLng sw;
  final LatLng ne;
  const _Bounds({required this.sw, required this.ne});
}
