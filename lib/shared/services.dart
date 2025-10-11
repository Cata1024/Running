import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/auth/auth_service.dart';
export '../services/auth/auth_service.dart'
    show AuthService, authServiceProvider, authStateProvider, currentUserProvider;
export '../services/routes/routes_service.dart'
    show RoutesService, routesServiceProvider, userRoutesProvider, allRoutesProvider;

/// Servicio de Firestore para Territory Run
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear/actualizar perfil de usuario
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando perfil de usuario: $e');
      rethrow;
    }
  }

  /// Obtener perfil de usuario
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, userId);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo perfil de usuario: $e');
      rethrow;
    }
  }

  /// Stream del perfil de usuario
  Stream<UserModel?> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, userId);
      }
      return null;
    });
  }

  /// Guardar carrera
  Future<String> saveRun(RunModel run) async {
    try {
      final runData = run.toMap();

      if (run.id.isEmpty) {
        // Nueva carrera
        final docRef = await _firestore
            .collection('users')
            .doc(run.userId)
            .collection('runs')
            .add(runData);

        // Actualizar estadísticas del usuario
        await _updateUserStats(run.userId, run);

        return docRef.id;
      } else {
        // Actualizar carrera existente
        await _firestore
            .collection('users')
            .doc(run.userId)
            .collection('runs')
            .doc(run.id)
            .set(runData);
        return run.id;
      }
    } catch (e) {
      debugPrint('Error guardando carrera: $e');
      rethrow;
    }
  }

  /// Obtener carreras del usuario
  Future<List<RunModel>> getUserRuns(String userId, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => RunModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo carreras: $e');
      rethrow;
    }
  }

  /// Stream de carreras del usuario
  Stream<List<RunModel>> getUserRunsStream(String userId, {int limit = 10}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('runs')
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RunModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Obtener una carrera específica
  Future<RunModel?> getRun(String userId, String runId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .doc(runId)
          .get();

      if (doc.exists && doc.data() != null) {
        return RunModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo carrera: $e');
      rethrow;
    }
  }

  /// Eliminar carrera
  Future<void> deleteRun(String userId, String runId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .doc(runId)
          .delete();
    } catch (e) {
      debugPrint('Error eliminando carrera: $e');
      rethrow;
    }
  }

  /// Actualizar estadísticas del usuario después de una carrera
  Future<void> _updateUserStats(String userId, RunModel run) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final currentUser = UserModel.fromMap(userData, userId);

          // Calcular nuevas estadísticas
          final newTotalRuns = currentUser.totalRuns + 1;
          final newTotalDistance = currentUser.totalDistance + run.distance;
          final newTotalTime = currentUser.totalTime + run.duration;
          final newExperience = currentUser.experience + run.experienceGained;

          // Calcular nivel basado en experiencia
          final newLevel = (newExperience / 1000).floor() + 1;

          // Actualizar timestamp de actividad
          final updates = {
            'totalRuns': newTotalRuns,
            'totalDistance': newTotalDistance,
            'totalTime': newTotalTime,
            'experience': newExperience,
            'level': newLevel,
            'lastActivityAt': DateTime.now().toIso8601String(),
          };

          transaction.update(userRef, updates);
        }
      });
    } catch (e) {
      debugPrint('Error actualizando estadísticas del usuario: $e');
      rethrow;
    }
  }

  /// Obtener ranking de usuarios por distancia
  Future<List<UserModel>> getLeaderboard({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('users')
          .orderBy('totalDistance', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo ranking: $e');
      rethrow;
    }
  }

  /// Buscar usuarios por nombre
  Future<List<UserModel>> searchUsers(String query, {int limit = 10}) async {
    try {
      // Nota: Firestore no soporta búsqueda de texto completo nativamente
      // Esta es una implementación básica que busca por el inicio del displayName
      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '$query\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error buscando usuarios: $e');
      rethrow;
    }
  }
}

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// Provider para el perfil del usuario actual
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(null);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserProfileStream(currentUser.uid);
});

// Provider para las carreras del usuario actual
final userRunsProvider = StreamProvider<List<RunModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserRunsStream(currentUser.uid);
});
