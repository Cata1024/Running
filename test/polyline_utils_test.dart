import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:running/core/polyline_utils.dart';

void main() {
  test('encode/decode roundtrip', () {
    final points = [
      LatLng(37.4219983, -122.084),
      LatLng(37.422, -122.085),
      LatLng(37.423, -122.086),
    ];

    final encoded = PolylineUtils.encodePolyline(points);
    expect(encoded, isNotEmpty);

    final decoded = PolylineUtils.decodePolyline(encoded);
    expect(decoded.length, equals(points.length));

    for (var i = 0; i < points.length; i++) {
  expect(decoded[i].latitude, closeTo(points[i].latitude, 1e-5));
  expect(decoded[i].longitude, closeTo(points[i].longitude, 1e-5));
    }
  });

  test('calculate distance approx', () {
    final a = LatLng(0, 0);
    final b = LatLng(1, 0); // ~111 km apart

    final km = PolylineUtils.calculateDistance([a, b]);
    expect(km, closeTo(111.195, 0.5));
  });
}
