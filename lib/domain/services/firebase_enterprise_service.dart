import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/services/api_service.dart';
import '../repositories/i_auth_repository.dart';

/// Servicio para funcionalidades de Firebase Enterprise
class FirebaseEnterpriseService {
  FirebaseEnterpriseService({
    required IAuthRepository authRepository,
    FirebaseFunctions? functions,
    ApiService? apiService,
  })  : _authRepository = authRepository,
        _apiService = apiService ?? ApiService(),
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'southamerica-west1');

  final IAuthRepository _authRepository;
  final ApiService _apiService;
  final FirebaseFunctions _functions;

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
      final callable = _functions.httpsCallable('deleteUserData');
      await callable.call({'userId': userId});
      await _apiService.deleteUserRuns(userId);
      await _apiService.deleteUserProfile(userId);
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
      final result = await _authRepository.deleteAccount();
      result.fold(
        (failure) {
          if (failure.code == 'requires-recent-login') {
            throw FirebaseEnterpriseException(
              failure.message,
              code: failure.code,
            );
          }
          throw FirebaseEnterpriseException(
            failure.message,
            code: failure.code,
          );
        },
        (_) {},
      );
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
      final result = await _authRepository.reauthenticateWithPassword(password);
      result.fold(
        (failure) {
          if (failure.code == 'wrong-password') {
            throw FirebaseEnterpriseException(
              failure.message,
              code: 'wrong-password',
            );
          }
          throw FirebaseEnterpriseException(
            failure.message,
            code: failure.code,
          );
        },
        (_) {},
      );
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
