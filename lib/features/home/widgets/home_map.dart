import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map_widget.dart';

class HomeMap extends StatelessWidget {
  final GlobalKey<MapContainerState> mapKey;
  final LatLng initialTarget;
  final MapType mapType;
  final String? mapStyle;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final void Function(GoogleMapController controller) onMapCreated;

  const HomeMap({
    super.key,
    required this.mapKey,
    required this.initialTarget,
    required this.mapType,
    required this.mapStyle,
    required this.markers,
    required this.polylines,
    required this.polygons,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return MapContainer(
      key: mapKey,
      mapStyle: mapStyle,
      initialPosition: CameraPosition(target: initialTarget, zoom: 14),
      markers: markers,
      polylines: polylines,
      polygons: polygons,
      mapType: mapType,
      onMapCreated: onMapCreated,
    );
  }
}
