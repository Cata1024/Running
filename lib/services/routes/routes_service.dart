import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/route_model.dart';

/// Servicio responsable de persistir y consultar rutas en Firestore usando
/// `RouteModel` como contrato principal.
class RoutesService {
  RoutesService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda una ruta nueva o actualiza una existente.
  Future<String> saveRoute(RouteModel route) async {
    final data = route.toMap();
    if (route.id.isEmpty) {
      final docRef = await _firestore.collection('routes').add(data);
      return docRef.id;
    }

    await _firestore.collection('routes').doc(route.id).set(data);
    return route.id;
  }

  /// Obtiene rutas de un usuario ordenadas por fecha de creación (desc).
  Future<List<RouteModel>> fetchUserRoutes(String userId, {int limit = 20}) async {
    final snapshot = await _firestore
        .collection('routes')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => RouteModel.fromMap(doc.data(), doc.id)).toList();
  }

  /// Obtiene rutas globales ordenadas por fecha de creación (desc).
  Future<List<RouteModel>> fetchAllRoutes({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('routes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => RouteModel.fromMap(doc.data(), doc.id)).toList();
  }

  /// Observa rutas de un usuario en tiempo real.
  Stream<List<RouteModel>> watchUserRoutes(String userId, {int limit = 20}) {
    return _firestore
        .collection('routes')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Observa todas las rutas en tiempo real.
  Stream<List<RouteModel>> watchAllRoutes({int limit = 50}) {
    return _firestore
        .collection('routes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Elimina una ruta por id.
  Future<void> deleteRoute(String routeId) async {
    await _firestore.collection('routes').doc(routeId).delete();
  }
}

// Riverpod providers --------------------------------------------------------

final routesServiceProvider = Provider<RoutesService>((ref) => RoutesService());

final userRoutesProvider =
    StreamProvider.family<List<RouteModel>, String>((ref, userId) {
  final service = ref.watch(routesServiceProvider);
  return service.watchUserRoutes(userId);
});

final allRoutesProvider = StreamProvider<List<RouteModel>>((ref) {
  final service = ref.watch(routesServiceProvider);
  return service.watchAllRoutes();
});
