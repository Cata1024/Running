import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación centralizado para la aplicación.
class AuthService {
  AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleSignInInitialized = false;

  /// Stream del estado de autenticación de Firebase.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actual autenticado o `null` si no hay sesión.
  User? get currentUser => _auth.currentUser;

  /// Registrar nuevo usuario con email y contraseña.
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Error en registro: ${e.message}');
      rethrow;
    }
  }

  /// Iniciar sesión con email y contraseña.
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Error en login: ${e.message}');
      rethrow;
    }
  }

  /// Iniciar sesión con Google.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        return await _auth.signInWithPopup(googleProvider);
      }

      await _ensureGoogleSignInInitialized();

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'No se recibió idToken de Google.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // Cancelaciones no deben considerarse errores graves.
      final code = e.code;
      if (code == GoogleSignInExceptionCode.canceled ||
          code == GoogleSignInExceptionCode.interrupted ||
          code == GoogleSignInExceptionCode.uiUnavailable) {
        debugPrint('Inicio de sesión con Google cancelado/interrumpido: $code');
        return null;
      }
      debugPrint('Error en login con Google (plugin): ${e.code} - ${e.description}');
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error en login con Google: ${e.message}');
      rethrow;
    }
  }

  /// Vincular credenciales de email/contraseña a la cuenta actual.
  Future<UserCredential?> linkEmailPassword(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No hay un usuario autenticado para vincular credenciales.');
    }

    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      final result = await user.linkWithCredential(credential);
      await user.reload();
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error vinculando email/contraseña: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Forzar recarga del usuario actual para obtener datos actualizados.
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error recargando usuario: $e');
    }
  }

  /// Indica si la cuenta actual tiene proveedor de email/contraseña.
  bool get hasEmailPasswordProvider {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    return user.providerData.any((info) => info.providerId == EmailAuthProvider.PROVIDER_ID);
  }

  /// Cerrar sesión incluyendo Google cuando aplique.
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await _ensureGoogleSignInInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Error cerrando sesión de Google: $e');
      }
    }
  }

  /// Restablecer contraseña a través de email.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al restablecer contraseña: ${e.message}');
      rethrow;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) {
      return;
    }

    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }
}

// Riverpod providers --------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
