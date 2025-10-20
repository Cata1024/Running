//google_sign_in_service.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio simplificado para Google Sign In
class GoogleSignInService {
  /// Iniciar sesión con Google - manejado directamente por FirebaseAuthService
  static Future<void> signIn() async {
    throw UnimplementedError('Usar FirebaseAuth.signInWithProvider/Popup');
  }

  /// Cerrar sesión - no requerido cuando se usa FirebaseAuth.signOut
  static Future<void> signOut() async {}

  /// Obtener credenciales - no requerido con signInWithProvider
  static Future<AuthCredential> getFirebaseCredential(dynamic account) async {
    throw UnimplementedError('No requerido con signInWithProvider');
  }
}
