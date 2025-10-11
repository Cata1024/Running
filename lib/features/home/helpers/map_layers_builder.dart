import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants.dart';
import '../providers/run_state_provider.dart';

class HomeMapLayersBuilder {
  final RunState runState;
  final LatLng? currentUserLocation;
  final BitmapDescriptor? runnerIcon;
  final double heading;

  const HomeMapLayersBuilder({
    required this.runState,
    required this.currentUserLocation,
    required this.runnerIcon,
    required this.heading,
  });

  Set<Marker> buildMarkers() {
    final markers = <Marker>{};

    if (currentUserLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('userLocation'),
          position: currentUserLocation!,
          icon: runnerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          rotation: heading,
          flat: true,
          zIndexInt: 1,
        ),
      );
    }

    if (runState.startLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('startLocation'),
          position: runState.startLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> buildPolylines() {
    if (runState.routePoints.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: runState.routePoints,
        color: runState.isCircuitClosed ? Colors.green : Colors.blue,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  Set<Polygon> buildPolygons() {
    final meetsTime = runState.elapsed.inSeconds >= AppConstants.minRunDuration;
    final meetsDistance = runState.distance >= AppConstants.minRunDistance;
    final isClosed = runState.isCircuitClosed;

    if (!isClosed || !meetsTime || !meetsDistance) return {};
    if (runState.routePoints.length < 3) return {};

    return {
      Polygon(
        polygonId: const PolygonId('circuit'),
        points: runState.routePoints,
        strokeWidth: 3,
        strokeColor: Colors.green,
        fillColor: Colors.green.withAlpha(51),
      ),
    };
  }
}
