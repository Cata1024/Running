import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Servicio para aplicar filtro de hogar (privacidad de ubicación)
class HomeFilterService {
  const HomeFilterService();

  /// Filtra una lista de puntos, enmascarando los que están dentro del radio de hogar
  List<LatLng> filterRoute({
    required List<LatLng> route,
    required LatLng homeLocation,
    required double radiusMeters,
  }) {
    if (route.isEmpty) return route;

    final filtered = <LatLng>[];
    bool insideHomeZone = false;
    LatLng? lastPointBeforeHome;

    for (int i = 0; i < route.length; i++) {
      final point = route[i];
      final distanceToHome = _calculateDistance(point, homeLocation);
      final isInsideHome = distanceToHome <= radiusMeters;

      if (isInsideHome) {
        // Punto dentro de la zona de hogar
        if (!insideHomeZone) {
          // Primera vez entrando a la zona
          insideHomeZone = true;
          lastPointBeforeHome = i > 0 ? route[i - 1] : null;
        }
        // No agregar puntos dentro de la zona
      } else {
        // Punto fuera de la zona de hogar
        if (insideHomeZone) {
          // Saliendo de la zona de hogar
          insideHomeZone = false;
          
          // Agregar punto de conexión si existe
          if (lastPointBeforeHome != null) {
            // Calcular punto en el borde del círculo
            final edgePoint = _calculateEdgePoint(
              lastPointBeforeHome,
              homeLocation,
              radiusMeters,
            );
            filtered.add(edgePoint);
          }
        }
        filtered.add(point);
      }
    }

    return filtered;
  }

  /// Verifica si un punto está dentro del radio de hogar
  bool isInsideHomeZone({
    required LatLng point,
    required LatLng homeLocation,
    required double radiusMeters,
  }) {
    final distance = _calculateDistance(point, homeLocation);
    return distance <= radiusMeters;
  }

  /// Calcula la distancia entre dos puntos en metros (fórmula de Haversine)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000.0; // metros

    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLon = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calcula un punto en el borde del círculo de hogar
  LatLng _calculateEdgePoint(
    LatLng fromPoint,
    LatLng homeCenter,
    double radiusMeters,
  ) {
    final distance = _calculateDistance(fromPoint, homeCenter);
    if (distance == 0) return homeCenter;

    // Calcular dirección
    final bearing = _calculateBearing(homeCenter, fromPoint);

    // Calcular punto en el borde
    return _calculateDestinationPoint(homeCenter, radiusMeters, bearing);
  }

  /// Calcula el bearing (dirección) entre dos puntos
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return math.atan2(y, x);
  }

  /// Calcula un punto destino dada una distancia y bearing
  LatLng _calculateDestinationPoint(
    LatLng start,
    double distanceMeters,
    double bearing,
  ) {
    const earthRadius = 6371000.0; // metros

    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final angularDistance = distanceMeters / earthRadius;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angularDistance) +
          math.cos(lat1) * math.sin(angularDistance) * math.cos(bearing),
    );

    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(lat1),
          math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(
      lat2 * 180 / math.pi,
      lon2 * 180 / math.pi,
    );
  }

  /// Crea un polígono circular para visualizar la zona de hogar
  List<LatLng> createHomeZonePolygon({
    required LatLng center,
    required double radiusMeters,
    int points = 32,
  }) {
    final polygon = <LatLng>[];

    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final point = _calculateDestinationPoint(center, radiusMeters, angle);
      polygon.add(point);
    }

    // Cerrar el polígono
    if (polygon.isNotEmpty) {
      polygon.add(polygon.first);
    }

    return polygon;
  }

  /// Enmascara una ruta completa si el filtro está habilitado
  List<LatLng> applyHomeFilter({
    required List<LatLng> route,
    required bool filterEnabled,
    LatLng? homeLocation,
    double? radiusMeters,
  }) {
    if (!filterEnabled || homeLocation == null || radiusMeters == null) {
      return route;
    }

    return filterRoute(
      route: route,
      homeLocation: homeLocation,
      radiusMeters: radiusMeters,
    );
  }
}
