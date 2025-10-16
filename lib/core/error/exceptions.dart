/// Clase base para excepciones personalizadas
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Excepciones de autenticación
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
  });
}

/// Excepciones de base de datos
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
  });
}

/// Excepciones de almacenamiento
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
  });
}

/// Excepciones de ubicación
class LocationException extends AppException {
  const LocationException({
    required super.message,
    super.code,
  });
}

/// Excepciones de red
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
  });
}
