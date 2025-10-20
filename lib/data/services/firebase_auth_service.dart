//firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/app_error.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

/// Servicio de autenticación optimizado con Firebase
class FirebaseAuthService {
  final FirebaseAuth _auth;
  final ApiService _api;
  
  FirebaseAuthService({
    FirebaseAuth? auth,
    required ApiService apiService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _api = apiService;

  /// Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actual
  User? get currentUser => _auth.currentUser;

  /// Iniciar sesión con email y contraseña
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw AppError(
          message: 'No se pudo iniciar sesión',
          code: 'login-failed',
        );
      }
      final user = credential.user!;
      await _ensureUserDocument(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error inesperado al iniciar sesión',
        code: 'unexpected-error',
      );
    }
  }

  /// Registrar nuevo usuario
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw AppError(
          message: 'No se pudo crear la cuenta',
          code: 'signup-failed',
        );
      }
      
      // Enviar email de verificación
      await credential.user!.sendEmailVerification();

      await _ensureUserDocument(credential.user!);

      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error inesperado al crear cuenta',
        code: 'unexpected-error',
      );
    }
  }

  /// Iniciar sesión con Google
  Future<User> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final cred = await _auth.signInWithPopup(GoogleAuthProvider());
        final user = cred.user;
        if (user == null) {
          throw AppError(message: 'No se pudo iniciar sesión con Google', code: 'google-signin-failed');
        }
        await _ensureUserDocument(user);
        return user;
      } else {
        // Flujo nativo con google_sign_in v6 (Android/iOS)
        final google = GoogleSignIn(scopes: const ['email']);
        final account = await google.signIn();
        if (account == null) {
          throw AppError(message: 'Inicio cancelado', code: 'google-signin-cancelled');
        }
        final tokens = await account.authentication; // idToken y accessToken
        final credential = GoogleAuthProvider.credential(
          idToken: tokens.idToken,
          accessToken: tokens.accessToken,
        );
        final cred = await _auth.signInWithCredential(credential);
        final user = cred.user;
        if (user == null) {
          throw AppError(message: 'No se pudo iniciar sesión con Google', code: 'google-signin-failed');
        }
        await _ensureUserDocument(user);
        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error inesperado al iniciar sesión con Google',
        code: 'google-unexpected-error',
      );
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppError(
        message: 'Error al cerrar sesión',
        code: 'signout-error',
      );
    }
  }

  /// Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error al enviar email de recuperación',
        code: 'reset-error',
      );
    }
  }

  /// Reautenticar con credenciales
  Future<void> reauthenticateWithCredential(AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError(
          message: 'No hay usuario autenticado',
          code: 'no-user',
        );
      }
      
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error al reautenticar',
        code: 'reauth-error',
      );
    }
  }

  /// Actualizar perfil del usuario
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError(
          message: 'No hay usuario autenticado',
          code: 'no-user',
        );
      }

      await user.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error al actualizar perfil',
        code: 'update-error',
      );
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError(
          message: 'No hay usuario autenticado',
          code: 'no-user',
        );
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AppError(
          message: 'Por seguridad, debes volver a iniciar sesión',
          code: 'requires-recent-login',
        );
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error al eliminar cuenta',
        code: 'delete-error',
      );
    }
  }

  /// Verificar email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError(
          message: 'No hay usuario autenticado',
          code: 'no-user',
        );
      }
      
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error al enviar email de verificación',
        code: 'verification-error',
      );
    }
  }

  /// Vincular cuenta de email/contraseña
  Future<void> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppError(
          message: 'No hay usuario autenticado',
          code: 'no-user',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await user.linkWithCredential(credential);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppError(
        message: 'Error al vincular cuenta',
        code: 'link-error',
      );
    }
  }

  /// Manejo centralizado de excepciones de Firebase Auth
  AppError _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AppError(
          message: 'No existe una cuenta con este email',
          code: e.code,
        );
      case 'wrong-password':
        return AppError(
          message: 'Contraseña incorrecta',
          code: e.code,
        );
      case 'invalid-email':
        return AppError(
          message: 'El email no es válido',
          code: e.code,
        );
      case 'email-already-in-use':
        return AppError(
          message: 'Ya existe una cuenta con este email',
          code: e.code,
        );
      case 'weak-password':
        return AppError(
          message: 'La contraseña debe tener al menos 6 caracteres',
          code: e.code,
        );
      case 'operation-not-allowed':
        return AppError(
          message: 'Esta operación no está permitida',
          code: e.code,
        );
      case 'user-disabled':
        return AppError(
          message: 'Esta cuenta ha sido deshabilitada',
          code: e.code,
        );
      case 'too-many-requests':
        return AppError(
          message: 'Demasiados intentos. Por favor, espera un momento',
          code: e.code,
        );
      case 'requires-recent-login':
        return AppError(
          message: 'Por seguridad, debes volver a iniciar sesión',
          code: e.code,
        );
      case 'network-request-failed':
        return AppError(
          message: 'Error de conexión. Verifica tu internet',
          code: e.code,
        );
      case 'invalid-credential':
        return AppError(
          message: 'Las credenciales son inválidas o han expirado',
          code: e.code,
        );
      default:
        debugPrint('Error de autenticación no manejado: ${e.code} - ${e.message}');
        return AppError(
          message: e.message ?? 'Error de autenticación',
          code: e.code,
        );
    }
  }

  /// Verificar si el usuario tiene proveedor de email/contraseña
  bool get hasEmailProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any(
      (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
    );
  }

  /// Verificar si el usuario tiene proveedor de Google
  bool get hasGoogleProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any(
      (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }
  
  /// Asegura que exista el documento de usuario en Firestore
  Future<void> _ensureUserDocument(User user) async {
    try {
      await _api.upsertUserProfile(user.uid, {
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'preferredUnits': 'metric',
        'level': 1,
        'experience': 0,
        'totalRuns': 0,
        'totalDistance': 0,
        'totalTime': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'lastActivityAt': null,
        'birthDate': null,
        'gender': null,
        'heightCm': null,
        'weightKg': null,
        'goalDescription': null,
      });
    } catch (_) {
      // No bloquear el login por fallo no crítico de perfil
    }
  }
}

// Los providers de este servicio están en app_providers.dart
