import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/territory_models.dart';

class TerritoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Convierte un track (lista de puntos) en un conjunto de tiles reclamados
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
          ownerId: '', // se completa al guardar
          centerLat: _tileCenterLat(key),
          centerLng: _tileCenterLng(key),
          tileSizeMeters: tileSizeMeters,
          updatedAt: DateTime.now(),
        ),
      );
    }
    return tiles.values.toSet();
  }

  // Guarda tiles para un usuario: suma (captura) o resta (cede) según parámetro
  Future<void> applyTiles({
    required String userId,
    required Set<TerritoryTile> tiles,
    required bool capture, // true suma (user reclama), false resta (cede)
  }) async {
    final batch = _db.batch();
    final col = _db.collection('territory');

    for (final t in tiles) {
      final docRef = col.doc(t.key);
      if (capture) {
        // Captura: el tile pasa a ser del usuario; si era de otro, lo reemplaza
        batch.set(docRef, {
          'ownerId': userId,
          'centerLat': t.centerLat,
          'centerLng': t.centerLng,
          'tileSizeMeters': t.tileSizeMeters,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Resta: si el usuario es el dueño, se libera (borra); si no, no hace nada
        batch.update(docRef, {
          'ownerId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  // Consulta tiles de un usuario
  Stream<List<TerritoryTile>> userTilesStream(String userId) {
    return _db
        .collection('territory')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TerritoryTile.fromMap(d.id, d.data()))
            .toList());
  }

  // Consulta tiles de todos los usuarios (para mapa global)
  Stream<List<TerritoryTile>> allTilesStream() {
    return _db
        .collection('territory')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TerritoryTile.fromMap(d.id, d.data()))
            .toList());
  }

  // Utilidades de tiles
  String tileKeyForLatLng(double lat, double lng, double tileSizeMeters) {
    final m = _mercatorFromLatLng(lat, lng);
    final x = (m.x / tileSizeMeters).floor();
    final y = (m.y / tileSizeMeters).floor();
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
    return g.lat;
  }

  double _tileCenterLng(String key) {
    final parts = key.split('_');
    final mSize = double.parse(parts[1]);
    final x = int.parse(parts[2]);
    final y = int.parse(parts[3]);
    final cx = (x + 0.5) * mSize;
    final cy = (y + 0.5) * mSize;
    final g = _latLngFromMercator(cx, cy);
    return g.lng;
  }
}

// Providers
final territoryServiceProvider = Provider<TerritoryService>((ref) => TerritoryService());

final myTerritoryTilesProvider = StreamProvider.family<List<TerritoryTile>, String>((ref, userId) {
  return ref.read(territoryServiceProvider).userTilesStream(userId);
});

final allTerritoryTilesProvider = StreamProvider<List<TerritoryTile>>((ref) {
  return ref.read(territoryServiceProvider).allTilesStream();
});

// Utils Mercator (EPSG:3857) duplicadas localmente para encapsular
const double _earthRadiusMeters = 6378137.0;

class _MetersPoint { final double x; final double y; const _MetersPoint(this.x, this.y); }
class _GeoPoint { final double lat; final double lng; const _GeoPoint(this.lat, this.lng); }

_MetersPoint _mercatorFromLatLng(double lat, double lng) {
  final x = _earthRadiusMeters * _degToRad(lng);
  final y = _earthRadiusMeters * math.log(math.tan(math.pi / 4 + _degToRad(lat) / 2));
  return _MetersPoint(x, y);
}

_GeoPoint _latLngFromMercator(double x, double y) {
  final lng = _radToDeg(x / _earthRadiusMeters);
  final lat = _radToDeg(2 * math.atan(math.exp(y / _earthRadiusMeters)) - math.pi / 2);
  return _GeoPoint(lat, lng);
}

double _degToRad(double deg) => deg * math.pi / 180.0;
double _radToDeg(double rad) => rad * 180.0 / math.pi;