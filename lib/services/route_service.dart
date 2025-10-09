import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/polyline_utils.dart';

class RouteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveRoute({
    required String ownerId,
    required List<LatLng> points,
    required double distanceKm,
    required int durationSec,
    String? title,
  }) async {
    final encoded = PolylineUtils.encodePolyline(points);
    final doc = _db.collection('routes').doc();
    await doc.set({
      'ownerId': ownerId,
      'encodedPolyline': encoded,
      'distance': distanceKm,
      'duration': durationSec,
      'createdAt': FieldValue.serverTimestamp(),
      if (title != null) 'title': title,
    });
  }

  Stream<List<Map<String, dynamic>>> fetchAllRoutes() {
    return _db.collection('routes').orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> fetchRoutesByUser(String userId) {
    return _db
        .collection('routes')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }
}

final routeService = RouteService();
