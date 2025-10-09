import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/polyline_utils.dart';

/// Modelo de ruta para polylines encoded
class RouteModel {
  final String id;
  final String ownerId;
  final String encodedPolyline;
  final double distanceKm;
  final int durationSec;
  final DateTime createdAt;
  final String? title;
  final String? notes;
  final double? averagePace;
  final double? averageSpeed;

  const RouteModel({
    required this.id,
    required this.ownerId,
    required this.encodedPolyline,
    required this.distanceKm,
    required this.durationSec,
    required this.createdAt,
    this.title,
    this.notes,
    this.averagePace,
    this.averageSpeed,
  });

  /// Crear desde mapa de Firestore
  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    return RouteModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      encodedPolyline: map['encodedPolyline'] ?? '',
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      durationSec: map['durationSec'] ?? 0,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(
              map['createdAt']?.millisecondsSinceEpoch ?? 0),
      title: map['title'],
      notes: map['notes'],
      averagePace: (map['averagePace'] ?? 0.0).toDouble(),
      averageSpeed: (map['averageSpeed'] ?? 0.0).toDouble(),
    );
  }

  /// Convertir a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'encodedPolyline': encodedPolyline,
      'distanceKm': distanceKm,
      'durationSec': durationSec,
      'createdAt': createdAt.toIso8601String(),
      if (title != null) 'title': title,
      if (averagePace != null) 'averagePace': averagePace,
      if (averageSpeed != null) 'averageSpeed': averageSpeed,
    };
  }

  /// Obtener puntos decodificados como `List<LatLng>`
  List<LatLng> get decodedPoints {
    if (encodedPolyline.isEmpty) return [];
    try {
      return PolylineUtils.decodePolyline(encodedPolyline);
    } catch (e) {
      // Manejar errores de decodificación
      return [];
    }
  }

  /// Crear copia con cambios
  RouteModel copyWith({
    String? id,
    String? ownerId,
    String? encodedPolyline,
    double? distanceKm,
    int? durationSec,
    DateTime? createdAt,
    String? title,
    String? notes,
    double? averagePace,
    double? averageSpeed,
  }) {
    return RouteModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSec: durationSec ?? this.durationSec,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      averagePace: averagePace ?? this.averagePace,
      averageSpeed: averageSpeed ?? this.averageSpeed,
    );
  }

  @override
  String toString() {
    return 'RouteModel(id: $id, distance: ${distanceKm.toStringAsFixed(1)}km, duration: $durationSec s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}