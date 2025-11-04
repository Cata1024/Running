import 'package:dartz/dartz.dart';
import '../entities/app_user.dart';
import '../entities/registration_data.dart';
import '../../core/error/failures.dart';

/// Contrato para el repositorio de autenticación
abstract class IAuthRepository {
  /// Stream que emite cambios en el estado de autenticación
  Stream<AppUser?> get authStateChanges;
  
  /// Usuario actual autenticado
  AppUser? get currentUser;
  
  /// Iniciar sesión con email y contraseña
  Future<Either<AuthFailure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });
  
  /// Registrar nuevo usuario con email y contraseña (legacy - usar registerWithCompleteData)
  @Deprecated('Use registerWithCompleteData instead')
  Future<Either<AuthFailure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  });
  
  /// Registrar nuevo usuario con datos completos del onboarding
  Future<Either<AuthFailure, AppUser>> registerWithCompleteData(
    RegistrationData data,
  );
  
  /// Iniciar sesión con Google
  Future<Either<AuthFailure, AppUser>> signInWithGoogle();
  
  /// Cerrar sesión
  Future<Either<AuthFailure, Unit>> signOut();
  
  /// Restablecer contraseña
  Future<Either<AuthFailure, Unit>> resetPassword(String email);
  
  /// Verificar email
  Future<Either<AuthFailure, Unit>> verifyEmail();
  
  /// Actualizar perfil del usuario
  Future<Either<AuthFailure, Unit>> updateProfile({
    String? displayName,
    String? photoUrl,
  });
  
  /// Eliminar cuenta
  Future<Either<AuthFailure, Unit>> deleteAccount();
  
  /// Vincular email y contraseña a cuenta existente
  Future<Either<AuthFailure, Unit>> linkEmailPassword({
    required String email,
    required String password,
  });
}
