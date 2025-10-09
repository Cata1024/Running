// lib/features/map_widget.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/env_config.dart';

/// Un contenedor de mapa optimizado que evita reconstrucciones innecesarias.
/// Usa `AutomaticKeepAliveClientMixin` para mantener el estado del mapa.
class MapContainer extends StatefulWidget {
  final CameraPosition initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final MapType mapType;
  final String? mapStyle;
  final ValueChanged<GoogleMapController>? onMapCreated;
  final ValueChanged<CameraPosition>? onCameraMove;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;

  const MapContainer({
    super.key,
    required this.initialPosition,
    required this.markers,
    required this.polylines,
    this.polygons = const {},
    this.mapType = MapType.normal,
    this.mapStyle,
    this.onMapCreated,
    this.onCameraMove,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
  });

  @override
  State<MapContainer> createState() => MapContainerState();
}

class MapContainerState extends State<MapContainer> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // Está bien llamar dispose en el controller si lo has creado.
    _controller?.dispose();
    super.dispose();
  }
  
  /// Mueve la cámara usando un [CameraUpdate]. devuelve Future para poder await.
  Future<void> moveCamera(CameraUpdate update, {bool animated = true}) async {
    if (_controller == null) return;
    try {
      if (animated) {
        await _controller!.animateCamera(update);
      } else {
        await _controller!.moveCamera(update);
      }
    } catch (e) {
      debugPrint('Error moving camera: $e');
    }
  }

  /// Ajusta la cámara para mostrar los bounds dados con padding (en píxeles)
  Future<void> moveCameraToBounds(LatLngBounds bounds, {double padding = 50}) async {
    if (_controller == null) return;
    try {
      await _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
    } catch (e) {
      // Algunas plataformas pueden lanzar si los bounds son inválidos; intentar centrado simple
      try {
        final center = LatLng((bounds.northeast.latitude + bounds.southwest.latitude) / 2,
            (bounds.northeast.longitude + bounds.southwest.longitude) / 2);
        await _controller!.animateCamera(CameraUpdate.newLatLng(center));
      } catch (e) {
        debugPrint('Error moving camera to bounds: $e');
      }
    }
  }

  /// Helper para mover la cámara a una LatLng con zoom/bearing opcional.
  Future<void> moveCameraToLatLng(
    LatLng target, {
    double zoom = 17,
    double bearing = 0,
    bool animated = true,
  }) =>
      moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom, bearing: bearing),
        ),
        animated: animated,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GoogleMap(
      key: const ValueKey('stable-google-map'),
      initialCameraPosition: widget.initialPosition,
      myLocationEnabled: false,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      mapToolbarEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      markers: widget.markers,
      polylines: widget.polylines,
      polygons: widget.polygons,
      mapType: widget.mapType,
      // NOTA: evitar usar una propiedad `style:` aquí para máxima compatibilidad.
      onMapCreated: (controller) {
        _controller = controller;

        if (widget.mapStyle != null && widget.mapStyle!.isNotEmpty) {
          // ignore: deprecated_member_use
          controller.setMapStyle(widget.mapStyle);
        }

        widget.onMapCreated?.call(controller);

        assert(() {
          final key = EnvConfig.instance.googleMapsApiKey;
          debugPrint('Google Maps initialized with key (masked): ${key.isEmpty ? 'missing' : key.substring(0, 6)}***');
          return true;
        }());
      },
      onCameraMove: (position) {
        widget.onCameraMove?.call(position);
      },
    );
  }
}
