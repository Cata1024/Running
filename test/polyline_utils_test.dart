import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:running/shared/utils/geo_utils.dart';

void main() {
  test('encode/decode roundtrip', () {
    final points = [
      LatLng(37.4219983, -122.084),
      LatLng(37.422, -122.085),
      LatLng(37.423, -122.086),
    ];

    final encoded = GeoUtils.encodePolyline(points);
    expect(encoded, isNotEmpty);

    final decoded = GeoUtils.decodePolyline(encoded);
    expect(decoded.length, equals(points.length));

    for (var i = 0; i < points.length; i++) {
  expect(decoded[i].latitude, closeTo(points[i].latitude, 1e-5));
  expect(decoded[i].longitude, closeTo(points[i].longitude, 1e-5));
    }
  });

  test('calculate distance approx', () {
    final a = LatLng(0, 0);
    final b = LatLng(1, 0); // ~111 km apart

    final meters = GeoUtils.pathLengthMeters([a, b]);
    expect(meters / 1000, closeTo(110.574, 0.5));
  });
}
