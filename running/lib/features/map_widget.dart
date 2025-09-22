// lib/features/map_widget.dart (ARCHIVO MODIFICADO)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Un contenedor de mapa optimizado que evita reconstrucciones innecesarias.
/// Usa `AutomaticKeepAliveClientMixin` para mantener el estado del mapa.
class MapContainer extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;

  const MapContainer({
    super.key,
    required this.initialPosition,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
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
  void moveCamera(LatLng position) {
    _controller?.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por el mixin.
    
    return GoogleMap(
      // Una clave estable es VITAL para evitar que Flutter lo reconstruya.
      key: const ValueKey('stable-google-map'),
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: 16,
      ),
      myLocationEnabled: false, // Desactivamos el punto azul nativo para usar el nuestro.
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      markers: widget.markers,
      polylines: widget.polylines,
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated(controller);
      },
    );
  }
}