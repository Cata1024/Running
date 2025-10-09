import 'dart:collection';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/territory_models.dart';
import '../core/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TerritoryRegion {
  final String id;
  final String ownerId;
  final List<String> tileKeys;
  final LatLng sw;
  final LatLng ne;

  TerritoryRegion({required this.id, required this.ownerId, required this.tileKeys, required this.sw, required this.ne});

  factory TerritoryRegion.fromDoc(DocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;
    final swMap = (data['bounds']?['sw'] ?? {}) as Map<String, dynamic>;
    final neMap = (data['bounds']?['ne'] ?? {}) as Map<String, dynamic>;
    return TerritoryRegion(
      id: d.id,
      ownerId: data['ownerId'] ?? '',
      tileKeys: List<String>.from(data['tileKeys'] ?? []),
      sw: LatLng((swMap['lat'] ?? 0.0).toDouble(), (swMap['lng'] ?? 0.0).toDouble()),
      ne: LatLng((neMap['lat'] ?? 0.0).toDouble(), (neMap['lng'] ?? 0.0).toDouble()),
    );
  }
}

/// Nuevo manager de territorio que aplica tiles y los agrupa en documentos
/// de 'territories' para representar regiones unidas por propietario.
class TerritoryManager {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Convierte un track (lista de puntos) en un conjunto de tiles reclamados
  Future<Set<TerritoryTile>> computeTilesFromTrack({
    required List<LatLng> track,
    double tileSizeMeters = AppConstants.tileSize,
  }) async {
    final tiles = <String, TerritoryTile>{};
    if (track.length < 2) return tiles.values.toSet();

    for (int i = 0; i < track.length; i++) {
      final p = track[i];
      final key = tileKeyForLatLng(p.latitude, p.longitude, tileSizeMeters);
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

  /// Aplica tiles: marca los tiles en collection 'territory' y recalcula
  /// agrupaciones por usuario en collection 'territories'.
  Future<void> applyTilesWithMerge({
    required String userId,
    required Set<TerritoryTile> tiles,
    required bool capture,
  }) async {
    final batch = _db.batch();
    final tileCol = _db.collection('territory');

    for (final t in tiles) {
      final docRef = tileCol.doc(t.key);
      if (capture) {
        batch.set(docRef, {
          'ownerId': userId,
          'centerLat': t.centerLat,
          'centerLng': t.centerLng,
          'tileSizeMeters': t.tileSizeMeters,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        batch.update(docRef, {
          'ownerId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();

    // Después de aplicar, recomputar agrupaciones del usuario (solo si capture)
    if (capture) {
      await _recomputeUserTerritories(userId);
    }
  }

  /// Recalcula las agrupaciones de tiles del usuario y escribe documentos
  /// en collection 'territories' con bounding boxes y lista de keys.
  Future<void> _recomputeUserTerritories(String userId) async {
    final tileDocs = await _db.collection('territory').where('ownerId', isEqualTo: userId).get();
    if (tileDocs.docs.isEmpty) {
      // limpiar territories del usuario
      final existing = await _db.collection('territories').where('ownerId', isEqualTo: userId).get();
      for (final d in existing.docs) {
        await d.reference.delete();
      }
      return;
    }

    // Mapear keys a coordenadas (usamos centerLat/centerLng)
    final Map<String, LatLng> keyToCenter = {};
    final Map<String, double> keyToSize = {};
    for (final d in tileDocs.docs) {
      final data = d.data();
      final key = d.id;
      final lat = (data['centerLat'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['centerLng'] as num?)?.toDouble() ?? 0.0;
      final size = (data['tileSizeMeters'] as num?)?.toDouble() ?? AppConstants.tileSize;
      keyToCenter[key] = LatLng(lat, lng);
      keyToSize[key] = size;
    }

    // Agrupar keys por contigüidad en la cuadrícula (4-neighbors). Para ello
    // extraemos x,y de la key que tiene formato: m_<size>_<x>_<y>
    final Map<String, List<String>> groups = {};
    final visited = <String>{};

    String? getSizeFromKey(String k) => k.split('_')[1];
    int getX(String k) => int.parse(k.split('_')[2]);
    int getY(String k) => int.parse(k.split('_')[3]);

    for (final key in keyToCenter.keys) {
      if (visited.contains(key)) continue;
      final q = Queue<String>();
      q.add(key);
      visited.add(key);
      final group = <String>[];
      final sizeStr = getSizeFromKey(key);

      while (q.isNotEmpty) {
        final cur = q.removeFirst();
        group.add(cur);
        final cx = getX(cur);
        final cy = getY(cur);

        // vecinos 4-direcciones
        final neighbors = [
          'm_${sizeStr}_${cx - 1}_$cy',
          'm_${sizeStr}_${cx + 1}_$cy',
          'm_${sizeStr}_${cx}_${cy - 1}',
          'm_${sizeStr}_${cx}_${cy + 1}',
        ];

        for (final n in neighbors) {
          if (!visited.contains(n) && keyToCenter.containsKey(n)) {
            visited.add(n);
            q.add(n);
          }
        }
      }

      groups[key] = group;
    }

    // Ahora escribimos/updateamos documentos en collection 'territories'
    final batch = _db.batch();
    final territoriesCol = _db.collection('territories');

    // Limpiar todas las territories del usuario antes de re-crear
    final existing = await territoriesCol.where('ownerId', isEqualTo: userId).get();
    for (final d in existing.docs) {
      batch.delete(d.reference);
    }

    for (final entry in groups.entries) {
      final keys = entry.value;
      // calcular bounding box
      double minLat = double.infinity, minLng = double.infinity, maxLat = -double.infinity, maxLng = -double.infinity;
      for (final k in keys) {
        final c = keyToCenter[k]!;
        if (c.latitude < minLat) minLat = c.latitude;
        if (c.longitude < minLng) minLng = c.longitude;
        if (c.latitude > maxLat) maxLat = c.latitude;
        if (c.longitude > maxLng) maxLng = c.longitude;
      }

      final doc = territoriesCol.doc();
      batch.set(doc, {
        'ownerId': userId,
        'tileKeys': keys,
        'bounds': {
          'sw': {'lat': minLat, 'lng': minLng},
          'ne': {'lat': maxLat, 'lng': maxLng},
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Utils de tiles (idénticos al anterior)
  String tileKeyForLatLng(double lat, double lng, double tileSizeMeters) {
    final m = _mercatorFromLatLng(lat, lng);
    final x = (m[0] / tileSizeMeters).floor();
    final y = (m[1] / tileSizeMeters).floor();
    return 'm_${tileSizeMeters.toStringAsFixed(0)}_${x}_$y';
  }

  double _tileCenterLat(String key) {
    final parts = key.split('_');
    final mSize = double.parse(parts[1]);
    final x = int.parse(parts[2]);
    final y = int.parse(parts[3]);
    final cx = (x + 0.5) * mSize;
    final cy = (y + 0.5) * mSize;
    final g = _latLngFromMercator(cx, cy);
    return g[0];
  }

  double _tileCenterLng(String key) {
    final parts = key.split('_');
    final mSize = double.parse(parts[1]);
    final x = int.parse(parts[2]);
    final y = int.parse(parts[3]);
    final cx = (x + 0.5) * mSize;
    final cy = (y + 0.5) * mSize;
    final g = _latLngFromMercator(cx, cy);
    return g[1];
  }

  // Implementación del método _mercatorFromLatLng
  List<double> _mercatorFromLatLng(double lat, double lng) {
    const double radius = 6378137.0; // Radio de la Tierra en metros
    final double x = radius * lng * (math.pi / 180);
    final double y = radius * math.log(math.tan((math.pi / 4) + (lat * (math.pi / 360))));
    return [x, y];
  }

  // Implementación del método _latLngFromMercator
  List<double> _latLngFromMercator(double x, double y) {
    const double radius = 6378137.0; // Radio de la Tierra en metros
    final double lng = (x / radius) * (180 / math.pi);
    final double lat = (2 * math.atan(math.exp(y / radius)) - (math.pi / 2)) * (180 / math.pi);
    return [lat, lng];
  }
}

final territoryManager = TerritoryManager();

final territoryManagerProvider = Provider<TerritoryManager>((ref) => territoryManager);

final userTerritoriesProvider = StreamProvider.family<List<TerritoryRegion>, String>((ref, userId) {
  return territoryManager._db.collection('territories').where('ownerId', isEqualTo: userId).snapshots().map((snap) =>
      snap.docs.map((d) => TerritoryRegion.fromDoc(d)).toList());
});

final allTerritoriesProvider = StreamProvider<List<TerritoryRegion>>((ref) {
  return territoryManager._db.collection('territories').snapshots().map((snap) => snap.docs.map((d) => TerritoryRegion.fromDoc(d)).toList());
});
