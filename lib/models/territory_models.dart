import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class TerritoryTile {
  final String key; // unique tile key
  final String ownerId;
  final double centerLat;
  final double centerLng;
  final double tileSizeMeters;
  final DateTime updatedAt;

  const TerritoryTile({
    required this.key,
    required this.ownerId,
    required this.centerLat,
    required this.centerLng,
    required this.tileSizeMeters,
    required this.updatedAt,
  });

  factory TerritoryTile.fromMap(String id, Map<String, dynamic> map) {
    return TerritoryTile(
      key: id,
      ownerId: map['ownerId'] ?? '',
      centerLat: (map['centerLat'] ?? 0.0).toDouble(),
      centerLng: (map['centerLng'] ?? 0.0).toDouble(),
      tileSizeMeters: (map['tileSizeMeters'] ?? 250.0).toDouble(),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : DateTime.fromMillisecondsSinceEpoch(
              map['updatedAt']?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
            ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'centerLat': centerLat,
      'centerLng': centerLng,
      'tileSizeMeters': tileSizeMeters,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Devuelve los 4 vértices del tile (en sentido horario), dado el tamaño en metros
  List<LatLng> toPolygonCorners() {
    final half = tileSizeMeters / 2.0;
    // Convertimos el centro a mercator, desplazamos +/- half y volvemos a lat/lng
    final m = _mercatorFromLatLng(centerLat, centerLng);
    final tl = _latLngFromMercator(m.x - half, m.y + half);
    final tr = _latLngFromMercator(m.x + half, m.y + half);
    final br = _latLngFromMercator(m.x + half, m.y - half);
    final bl = _latLngFromMercator(m.x - half, m.y - half);
    return [
      LatLng(tl.lat, tl.lng),
      LatLng(tr.lat, tr.lng),
      LatLng(br.lat, br.lng),
      LatLng(bl.lat, bl.lng),
    ];
  }
}

// Utilidades Mercator (EPSG:3857)
const double _earthRadiusMeters = 6378137.0; // radio WGS84

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