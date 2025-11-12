import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Widget para mostrar un mini mapa estático de una ruta
class MiniMap extends StatelessWidget {
  final List<dynamic> routeCoordinates; // [[lon, lat], [lon, lat], ...]
  final double width;
  final double height;
  final double borderRadius;
  final bool enableZoom;
  final bool showRoutePolyline;
  final BitmapDescriptor? startIcon;
  final BitmapDescriptor? endIcon;

  const MiniMap({
    super.key,
    required this.routeCoordinates,
    this.width = 80,
    this.height = 80,
    this.borderRadius = 12,
    this.enableZoom = false,
    this.showRoutePolyline = true,
    this.startIcon,
    this.endIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (routeCoordinates.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.map, color: Colors.grey),
      );
    }

    // Convertir coordenadas a LatLng
    final points = routeCoordinates
        .map((coord) {
          if (coord is List && coord.length >= 2) {
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }
          return null;
        })
        .whereType<LatLng>()
        .toList();

    if (points.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.map, color: Colors.grey),
      );
    }

    // Calcular bounds
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(centerLat, centerLng),
            zoom: 14,
          ),
          polylines: showRoutePolyline
              ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: points,
                    color: Colors.blue,
                    width: 3,
                  ),
                }
              : const <Polyline>{},
          markers: {
            Marker(
              markerId: const MarkerId('start'),
              position: points.first,
              icon: startIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
            Marker(
              markerId: const MarkerId('end'),
              position: points.last,
              icon: endIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          zoomControlsEnabled: false,
          scrollGesturesEnabled: enableZoom,
          zoomGesturesEnabled: enableZoom,
          rotateGesturesEnabled: enableZoom,
          tiltGesturesEnabled: enableZoom,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
}
