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

  const MapContainer({
    super.key,
    required this.initialPosition,
    required this.markers,
    required this.polylines,
    this.polygons = const {},
    this.mapType = MapType.normal,
    this.mapStyle,
    this.onMapCreated,
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
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      markers: widget.markers,
      polylines: widget.polylines,
      polygons: widget.polygons,
      mapType: widget.mapType,
      // NOTA: evitar usar una propiedad `style:` aquí para máxima compatibilidad.
      onMapCreated: (controller) {
        _controller = controller;

        // Aplicar estilo si viene uno (compatibilidad amplia).
        if (widget.mapStyle != null && widget.mapStyle!.isNotEmpty) {
          try {
            controller.setMapStyle(widget.mapStyle);
          } catch (e) {
            // setMapStyle puede lanzar si la versión del plugin no lo soporta
            debugPrint('setMapStyle failed: $e');
          }
        }

        widget.onMapCreated?.call(controller);

        assert(() {
          final key = EnvConfig.instance.googleMapsApiKey;
          debugPrint('Google Maps initialized with key (masked): ${key.isEmpty ? 'missing' : key.substring(0, 6)}***');
          return true;
        }());
      },
    );
  }
}
