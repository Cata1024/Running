// lib/features/map_widget.dart (ARCHIVO MODIFICADO)
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Un contenedor de mapa optimizado que evita reconstrucciones innecesarias.
/// Usa `AutomaticKeepAliveClientMixin` para mantener el estado del mapa.
class MapContainer extends StatefulWidget {
  final CameraPosition initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final MapType mapType;
  final Function(GoogleMapController)? onMapCreated;

  const MapContainer({
    super.key,
    required this.initialPosition,
    required this.markers,
    required this.polylines,
    this.polygons = const {},
    this.mapType = MapType.normal,
    this.onMapCreated,
  });

  @override
  State<MapContainer> createState() => MapContainerState();
}

class MapContainerState extends State<MapContainer> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;

  // Mantiene el estado del widget vivo, crucial para el mapa.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  // Método público para que el widget padre pueda mover la cámara.
  void moveCamera(dynamic target, {bool animated = true}) {
    if (_controller == null) return;
    final update = target is CameraUpdate
        ? target
        : target is LatLng
            ? CameraUpdate.newLatLng(target)
            : null;
    if (update == null) return;
    if (animated) {
      _controller!.animateCamera(update);
    } else {
      _controller!.moveCamera(update);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por el mixin.
    
    return GoogleMap(
      // Una clave estable es VITAL para evitar que Flutter lo reconstruya.
      key: const ValueKey('stable-google-map'),
      initialCameraPosition: widget.initialPosition,
      myLocationEnabled: false, // Desactivamos el punto azul nativo para usar el nuestro.
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      markers: widget.markers,
      polylines: widget.polylines,
      polygons: widget.polygons,
      mapType: widget.mapType,
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
    );
  }
}