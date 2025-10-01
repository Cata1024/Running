/// Constantes de la aplicación Territory Run
class AppConstants {
  // Configuración de la aplicación
  static const String appName = 'Territory Run';
  static const String appVersion = '1.0.0';
  
  // Google Maps API Keys por plataforma
  static const String googleMapsApiKeyWeb = 'AIzaSyD7p9SqQYqJ87vWdBXa_lJKUIxL91h79s4';
  static const String googleMapsApiKeyAndroid = 'AIzaSyBQEbVWObXD0xD5W-qRwQoG2bAGelIjl7M';
  static const String googleMapsApiKeyIOS = 'AIzaSyBWPwVrCaxrIwm8rAYTqtVqKWUe5x18h4A';
  
  // API Key genérica (usa la de web por defecto)
  static const String googleMapsApiKey = googleMapsApiKeyWeb;
  
  // Configuración de territorio
  static const double circuitCloseRadius = 50.0; // metros
  static const int minRunDuration = 300; // 5 minutos en segundos
  static const double minRunDistance = 0.5; // km mínimos
  
  // Configuración GPS
  static const int gpsUpdateInterval = 1000; // milisegundos
  static const double gpsAccuracyThreshold = 20.0; // metros
  
  // Configuración de tiles
  static const double tileSize = 250.0; // metros por tile
  static const int maxZoomLevel = 18;
  
  // Configuración de privacidad
  static const double defaultHomeRadius = 300.0; // metros
  
  // Colores del tema
  static const int primaryColorValue = 0xFF2E7D32;
  static const int accentColorValue = 0xFF4CAF50;
  
  // URLs y endpoints
  static const String termsUrl = 'https://territory-run.web.app/terms';
  static const String privacyUrl = 'https://territory-run.web.app/privacy';
  
  // Límites y validaciones
  static const double maxSpeedKmh = 30.0; // Velocidad máxima para detección de fraude
  static const int maxRunDurationHours = 6; // Máximo 6 horas de carrera
  static const double minDistanceBetweenPoints = 5.0; // metros mínimos entre puntos GPS
}

/// Enums para diferentes estados de la aplicación
enum RunStatus {
  notStarted,
  running,
  paused,
  completed,
  error
}

enum CircuitStatus {
  open,
  closed,
  invalid
}

enum PrivacyLevel {
  private,
  linkOnly,
  public
}

enum Units {
  metric,
  imperial
}