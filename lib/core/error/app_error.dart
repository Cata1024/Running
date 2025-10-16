/// Clase base para manejo de errores en la aplicación
class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppError({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppError: $message${code != null ? ' (code: $code)' : ''}';

  /// Crear error desde excepción genérica
  factory AppError.fromException(dynamic error) {
    if (error is AppError) return error;
    
    return AppError(
      message: error.toString(),
      originalError: error,
    );
  }

  /// Verificar si es un error de red
  bool get isNetworkError => 
      code == 'network-error' || 
      code == 'network-request-failed';

  /// Verificar si es un error de autenticación
  bool get isAuthError => 
      code?.contains('auth') == true || 
      code?.contains('user') == true ||
      code?.contains('password') == true ||
      code?.contains('email') == true;

  /// Verificar si el usuario canceló la operación
  bool get isCancelledByUser => 
      code == 'cancelled' || 
      code == 'user-cancelled';
}
