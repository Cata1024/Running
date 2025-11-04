import 'package:equatable/equatable.dart';

/// Clase base para todos los failures en la aplicación
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Failures específicos de autenticación
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });

  factory AuthFailure.serverError() => const AuthFailure(
    message: 'Error del servidor. Por favor, intenta más tarde.',
    code: 'server-error',
  );

  factory AuthFailure.networkError() => const AuthFailure(
    message: 'Error de conexión. Verifica tu conexión a internet.',
    code: 'network-error',
  );

  factory AuthFailure.userNotFound() => const AuthFailure(
    message: 'No existe una cuenta con este email.',
    code: 'user-not-found',
  );

  factory AuthFailure.wrongPassword() => const AuthFailure(
    message: 'Contraseña incorrecta.',
    code: 'wrong-password',
  );

  factory AuthFailure.invalidEmail() => const AuthFailure(
    message: 'El email ingresado no es válido.',
    code: 'invalid-email',
  );

  factory AuthFailure.emailAlreadyInUse() => const AuthFailure(
    message: 'Ya existe una cuenta con este email.',
    code: 'email-already-in-use',
  );

  factory AuthFailure.weakPassword() => const AuthFailure(
    message: 'La contraseña debe tener al menos 6 caracteres.',
    code: 'weak-password',
  );

  factory AuthFailure.operationNotAllowed() => const AuthFailure(
    message: 'Esta operación no está permitida.',
    code: 'operation-not-allowed',
  );

  factory AuthFailure.userDisabled() => const AuthFailure(
    message: 'Esta cuenta ha sido deshabilitada.',
    code: 'user-disabled',
  );

  factory AuthFailure.tooManyRequests() => const AuthFailure(
    message: 'Demasiados intentos. Por favor, intenta más tarde.',
    code: 'too-many-requests',
  );

  factory AuthFailure.requiresRecentLogin() => const AuthFailure(
    message: 'Por seguridad, debes volver a iniciar sesión.',
    code: 'requires-recent-login',
  );

  factory AuthFailure.noUserFound() => const AuthFailure(
    message: 'No se encontró usuario autenticado.',
    code: 'no-user',
  );

  factory AuthFailure.cancelledByUser() => const AuthFailure(
    message: 'Operación cancelada por el usuario.',
    code: 'cancelled',
  );

  factory AuthFailure.invalidCredential() => const AuthFailure(
    message: 'Las credenciales son inválidas o han expirado.',
    code: 'invalid-credential',
  );

  factory AuthFailure.invalidData() => const AuthFailure(
    message: 'Los datos proporcionados no son válidos.',
    code: 'invalid-data',
  );

  factory AuthFailure.notImplemented() => const AuthFailure(
    message: 'Esta funcionalidad aún no está implementada.',
    code: 'not-implemented',
  );
}

/// Failures de base de datos
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
  });

  factory DatabaseFailure.insufficientPermissions() => const DatabaseFailure(
    message: 'No tienes permisos para realizar esta acción.',
    code: 'insufficient-permissions',
  );

  factory DatabaseFailure.notFound() => const DatabaseFailure(
    message: 'El recurso solicitado no fue encontrado.',
    code: 'not-found',
  );

  factory DatabaseFailure.alreadyExists() => const DatabaseFailure(
    message: 'El recurso ya existe.',
    code: 'already-exists',
  );

  factory DatabaseFailure.timeout() => const DatabaseFailure(
    message: 'La operación tardó demasiado tiempo.',
    code: 'timeout',
  );

  factory DatabaseFailure.serverError() => const DatabaseFailure(
    message: 'Error del servidor de base de datos.',
    code: 'server-error',
  );
}

/// Failures de almacenamiento
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
  });

  factory StorageFailure.unauthorized() => const StorageFailure(
    message: 'No autorizado para acceder al almacenamiento.',
    code: 'unauthorized',
  );

  factory StorageFailure.objectNotFound() => const StorageFailure(
    message: 'El archivo no fue encontrado.',
    code: 'object-not-found',
  );

  factory StorageFailure.bucketNotFound() => const StorageFailure(
    message: 'El bucket de almacenamiento no existe.',
    code: 'bucket-not-found',
  );

  factory StorageFailure.quotaExceeded() => const StorageFailure(
    message: 'Se excedió la cuota de almacenamiento.',
    code: 'quota-exceeded',
  );

  factory StorageFailure.invalidFileFormat() => const StorageFailure(
    message: 'Formato de archivo no válido.',
    code: 'invalid-format',
  );

  factory StorageFailure.fileTooLarge() => const StorageFailure(
    message: 'El archivo es demasiado grande.',
    code: 'file-too-large',
  );
}

/// Failures de ubicación
class LocationFailure extends Failure {
  const LocationFailure({
    required super.message,
    super.code,
  });

  factory LocationFailure.serviceDisabled() => const LocationFailure(
    message: 'Los servicios de ubicación están deshabilitados.',
    code: 'service-disabled',
  );

  factory LocationFailure.permissionDenied() => const LocationFailure(
    message: 'Permisos de ubicación denegados.',
    code: 'permission-denied',
  );

  factory LocationFailure.permissionDeniedForever() => const LocationFailure(
    message: 'Permisos de ubicación denegados permanentemente.',
    code: 'permission-denied-forever',
  );

  factory LocationFailure.timeout() => const LocationFailure(
    message: 'No se pudo obtener la ubicación a tiempo.',
    code: 'timeout',
  );
}
