import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route_model.dart';

/// Servicio para manejar rutas encoded en Firestore
class RoutesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guardar o actualizar ruta
  Future<String> saveRoute(RouteModel route) async {
    try {
      final routeData = route.toMap();
      if (route.id.isEmpty) {
        // Nueva ruta
        final docRef = await _firestore.collection('routes').add(routeData);
        return docRef.id;
      } else {
        // Actualizar ruta existente
        await _firestore.collection('routes').doc(route.id).set(routeData);
        return route.id;
      }
    } catch (e) {
      throw Exception('Error saving route: $e');
    }
  }

  /// Obtener rutas de un usuario
  Future<List<RouteModel>> fetchUserRoutes(String userId, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('routes')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching user routes: $e');
    }
  }

  /// Obtener todas las rutas (opcionalmente limitadas)
  Future<List<RouteModel>> fetchAllRoutes({int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('routes')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching all routes: $e');
    }
  }

  /// Stream de rutas de un usuario
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

  /// Stream de todas las rutas
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

  /// Eliminar ruta
  Future<void> deleteRoute(String routeId) async {
    try {
      await _firestore.collection('routes').doc(routeId).delete();
    } catch (e) {
      throw Exception('Error deleting route: $e');
    }
  }
}

// Providers
final routesServiceProvider = Provider<RoutesService>((ref) => RoutesService());

final userRoutesProvider = StreamProvider.family<List<RouteModel>, String>((ref, userId) {
  final routesService = ref.watch(routesServiceProvider);
  return routesService.watchUserRoutes(userId);
});

final allRoutesProvider = StreamProvider<List<RouteModel>>((ref) {
  final routesService = ref.watch(routesServiceProvider);
  return routesService.watchAllRoutes();
});