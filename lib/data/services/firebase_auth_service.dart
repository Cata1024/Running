//firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/app_error.dart';
import '../../domain/entities/registration_data.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

/// Servicio de autenticación optimizado con Firebase
class FirebaseAuthService {
  final FirebaseAuth _auth;
  final ApiService _api;
  static Future<void>? _googleInitialization;
  static const String _googleServerClientId =
      '28475506464-fak9o969p6igi6mp1l8et45ru6usrm1p.apps.googleusercontent.com';
  
  FirebaseAuthService({
    FirebaseAuth? auth,
    required ApiService apiService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _api = apiService;

  Future<void> _ensureGoogleInitialized() {
    final existing = _googleInitialization;
    if (existing != null) {
      return existing;
    }
    final initialization = GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialization = initialization;
    return initialization;
  }

  Future<GoogleSignInAccount?> _authenticateWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      return await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

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
    String? displayName,
    String? goalType,
    double? weeklyDistanceGoal,
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

      await _ensureUserDocument(
        credential.user!,
        displayName: displayName,
        goalType: goalType,
        weeklyDistanceGoal: weeklyDistanceGoal,
      );

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

  /// Registrar con datos completos del onboarding
  Future<User> registerWithCompleteData(RegistrationData data) async {
    try {
      User? user;
      
      // Crear cuenta según el método de autenticación
      switch (data.authMethod) {
        case AuthMethod.emailPassword:
          if (data.email == null || data.password == null) {
            throw AppError(
              message: 'Email y contraseña requeridos',
              code: 'invalid-data',
            );
          }
          final credential = await _auth.createUserWithEmailAndPassword(
            email: data.email!,
            password: data.password!,
          );
          user = credential.user;
          
          // Enviar email de verificación
          if (user != null) {
            await user.sendEmailVerification();
          }
          break;
          
        case AuthMethod.google:
          if (kIsWeb) {
            final cred = await _auth.signInWithPopup(GoogleAuthProvider());
            user = cred.user;
          } else {
            final GoogleSignInAccount? account = await _authenticateWithGoogle();
            if (account == null) {
              throw AppError(message: 'Inicio cancelado', code: 'google-signin-cancelled');
            }
            final GoogleSignInAuthentication tokens = account.authentication;
            final credential = GoogleAuthProvider.credential(
              idToken: tokens.idToken,
            );
            final cred = await _auth.signInWithCredential(credential);
            user = cred.user;
          }
          break;
          
        case AuthMethod.apple:
        case AuthMethod.facebook:
          throw AppError(
            message: '${data.authMethod.displayName} no está implementado aún',
            code: 'not-implemented',
          );
      }
      
      if (user == null) {
        throw AppError(
          message: 'No se pudo crear la cuenta',
          code: 'signup-failed',
        );
      }
      
      // Crear perfil completo con todos los datos del onboarding
      await _createCompleteUserProfile(user, data);
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Error inesperado al crear cuenta',
        code: 'unexpected-error',
      );
    }
  }
  
  /// Crear perfil completo con datos del onboarding
  Future<void> _createCompleteUserProfile(User user, RegistrationData data) async {
    try {
      final profileData = data.toProfileData();
      profileData['email'] = user.email;
      profileData['photoUrl'] = user.photoURL;
      
      await _api.upsertUserProfile(user.uid, profileData);
    } catch (e) {
      // Log error pero no bloquear el registro
      debugPrint('Error creating complete profile: $e');
      // Intentar crear perfil básico como fallback
      await _ensureUserDocument(user);
    }
  }

  /// Iniciar sesión con Google
  Future<User> signInWithGoogle({
    String? displayName,
    String? goalType,
    double? weeklyDistanceGoal,
  }) async {
    try {
      if (kIsWeb) {
        final cred = await _auth.signInWithPopup(GoogleAuthProvider());
        final user = cred.user;
        if (user == null) {
          throw AppError(message: 'No se pudo iniciar sesión con Google', code: 'google-signin-failed');
        }
        await _ensureUserDocument(
          user,
          displayName: displayName,
          goalType: goalType,
          weeklyDistanceGoal: weeklyDistanceGoal,
        );
        return user;
      } else {
        final GoogleSignInAccount? account = await _authenticateWithGoogle();
        if (account == null) {
          throw AppError(message: 'Inicio cancelado', code: 'google-signin-cancelled');
        }
        final GoogleSignInAuthentication tokens = account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: tokens.idToken,
        );
        final cred = await _auth.signInWithCredential(credential);
        final user = cred.user;
        if (user == null) {
          throw AppError(message: 'No se pudo iniciar sesión con Google', code: 'google-signin-failed');
        }
        
        // Asegurar que el documento de usuario exista, especialmente para logins recurrentes
        await _ensureUserDocument(
          user,
          displayName: displayName,
          goalType: goalType,
          weeklyDistanceGoal: weeklyDistanceGoal,
        );
        
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
  Future<void> _ensureUserDocument(
    User user, {
    String? displayName,
    String? goalType,
    double? weeklyDistanceGoal,
  }) async {
    try {
      await _api.upsertUserProfile(user.uid, {
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? 'Runner',
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
        if (goalType != null) 'goalType': goalType,
        if (weeklyDistanceGoal != null) 'weeklyDistanceGoal': weeklyDistanceGoal,
      });
    } catch (_) {
      // No bloquear el login por fallo no crítico de perfil
    }
  }
}

// Los providers de este servicio están en app_providers.dart
