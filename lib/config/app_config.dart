import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Firebase Web
  String get firebaseWebApiKey => _getOrThrow('FIREBASE_API_KEY_WEB');
  String get firebaseWebAppId => _getOrThrow('FIREBASE_APP_ID_WEB');
  String get firebaseWebMessagingSenderId => _getOrThrow('FIREBASE_MESSAGING_SENDER_ID_WEB');
  String get firebaseWebProjectId => _getOrThrow('FIREBASE_PROJECT_ID_WEB');
  String get firebaseWebAuthDomain => _getOrThrow('FIREBASE_AUTH_DOMAIN_WEB');
  String get firebaseWebStorageBucket => _getOrThrow('FIREBASE_STORAGE_BUCKET_WEB');
  String get firebaseWebMeasurementId => _getOrThrow('FIREBASE_MEASUREMENT_ID_WEB');

  // Firebase Android
  String get firebaseAndroidApiKey => _getOrThrow('FIREBASE_API_KEY_ANDROID');
  String get firebaseAndroidAppId => _getOrThrow('FIREBASE_APP_ID_ANDROID');
  String get firebaseAndroidMessagingSenderId => _getOrThrow('FIREBASE_MESSAGING_SENDER_ID_ANDROID');
  String get firebaseAndroidProjectId => _getOrThrow('FIREBASE_PROJECT_ID_ANDROID');

  // Google Maps
  String? get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'];

  // Método privado para obtener variables de entorno con manejo de errores
  String _getOrThrow(String key) {
    final value = dotenv.env[key];
    if (value == null) {
      if (kDebugMode) {
        print('⚠️ Variable de entorno no encontrada: $key');
      }
      return ''; // O lanzar una excepción si es crítico
    }
    return value;
  }

  // Validar configuraciones requeridas
  bool validateConfig() {
    try {
      // Valida solo las configuraciones necesarias según la plataforma
      if (kIsWeb) {
        return firebaseWebApiKey.isNotEmpty &&
            firebaseWebAppId.isNotEmpty &&
            firebaseWebProjectId.isNotEmpty;
      } else {
        return firebaseAndroidApiKey.isNotEmpty &&
            firebaseAndroidAppId.isNotEmpty &&
            firebaseAndroidProjectId.isNotEmpty;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validando configuración: $e');
      }
      return false;
    }
  }
}
