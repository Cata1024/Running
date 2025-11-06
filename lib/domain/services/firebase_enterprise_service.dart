import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para funcionalidades de Firebase Enterprise
class FirebaseEnterpriseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'southamerica-west1');

  /// Exporta todos los datos del usuario usando Cloud Function
  /// Retorna un Map con 'downloadUrl' y 'fileSize'
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final callable = _functions.httpsCallable('exportUserData');
      
      final result = await callable.call({
        'userId': userId,
      });
      
      return {
        'downloadUrl': result.data['downloadUrl'] as String,
        'fileSize': result.data['fileSize'] as String? ?? 'Desconocido',
        'expiresAt': result.data['expiresAt'] as String? ?? '24 horas',
      };
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseEnterpriseException(
        'Error al exportar datos: ${e.message ?? e.code}',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseEnterpriseException('Error inesperado: $e');
    }
  }

  /// Elimina todos los datos del usuario de Firestore
  /// Esto se ejecuta ANTES de eliminar la cuenta de Auth
  Future<void> deleteUserDataFromFirestore(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Eliminar runs del usuario
      final runsQuery = await _firestore
          .collection('runs')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in runsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar documento de perfil de usuario
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Eliminar sub-colecciones del usuario
      final subCollections = [
        'achievements',
        'level_history',
        'notifications',
        'settings',
      ];
      
      for (final collectionName in subCollections) {
        final subDocs = await _firestore
            .collection('users')
            .doc(userId)
            .collection(collectionName)
            .get();
        
        for (final doc in subDocs.docs) {
          batch.delete(doc.reference);
        }
      }
      
      // Ejecutar todas las eliminaciones
      await batch.commit();
      
    } catch (e) {
      throw FirebaseEnterpriseException(
        'Error al eliminar datos de Firestore: $e',
      );
    }
  }

  /// Elimina la cuenta del usuario de Firebase Auth
  /// Esto dispara la Firebase Extension "delete-user-data" si está configurada
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseEnterpriseException('Usuario no autenticado');
      }
      
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw FirebaseEnterpriseException(
          'Se requiere re-autenticación para esta acción sensible',
          code: 'requires-recent-login',
        );
      }
      throw FirebaseEnterpriseException(
        'Error al eliminar cuenta: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseEnterpriseException('Error inesperado: $e');
    }
  }

  /// Re-autentica al usuario con sus credenciales
  Future<void> reauthenticateUser(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseEnterpriseException('Usuario no autenticado');
      }
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw FirebaseEnterpriseException(
          'Contraseña incorrecta',
          code: 'wrong-password',
        );
      }
      throw FirebaseEnterpriseException(
        'Error al re-autenticar: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseEnterpriseException('Error inesperado: $e');
    }
  }
}

/// Excepción personalizada para errores de Firebase Enterprise
class FirebaseEnterpriseException implements Exception {
  final String message;
  final String? code;

  FirebaseEnterpriseException(this.message, {this.code});

  @override
  String toString() => message;
}
