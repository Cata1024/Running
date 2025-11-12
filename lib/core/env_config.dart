import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Runtime configuration sourced from `.env`.
class EnvConfig {
  const EnvConfig._();

  static final EnvConfig instance = const EnvConfig._();

  static String _get(String key) => dotenv.env[key] ?? '';

  /// Firebase Web
  String get firebaseApiKeyWeb => _get('FIREBASE_API_KEY_WEB');
  String get firebaseAppIdWeb => _get('FIREBASE_APP_ID_WEB');
  String get firebaseMessagingSenderIdWeb =>
      _get('FIREBASE_MESSAGING_SENDER_ID_WEB');
  String get firebaseProjectIdWeb => _get('FIREBASE_PROJECT_ID_WEB');
  String get firebaseAuthDomainWeb => _get('FIREBASE_AUTH_DOMAIN_WEB');
  String get firebaseStorageBucketWeb => _get('FIREBASE_STORAGE_BUCKET_WEB');
  String get firebaseMeasurementIdWeb => _get('FIREBASE_MEASUREMENT_ID_WEB');

  /// Firebase Android
  String get firebaseApiKeyAndroid => _get('FIREBASE_API_KEY_ANDROID');
  String get firebaseAppIdAndroid => _get('FIREBASE_APP_ID_ANDROID');
  String get firebaseMessagingSenderIdAndroid =>
      _get('FIREBASE_MESSAGING_SENDER_ID_ANDROID');
  String get firebaseProjectIdAndroid => _get('FIREBASE_PROJECT_ID_ANDROID');
  String get firebaseStorageBucketAndroid =>
      _get('FIREBASE_STORAGE_BUCKET_ANDROID');

  /// Google Maps
  String get googleMapsApiKey => _get('GOOGLE_MAPS_API_KEY');

  /// Backend REST API
  String get backendApiUrl => _get('BASE_API_URL');

  /// Returns Firebase options based on the current platform.
  FirebaseOptions firebaseOptions() {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: firebaseApiKeyWeb,
        appId: firebaseAppIdWeb,
        messagingSenderId: firebaseMessagingSenderIdWeb,
        projectId: firebaseProjectIdWeb,
        authDomain:
            firebaseAuthDomainWeb.isEmpty ? null : firebaseAuthDomainWeb,
        storageBucket:
            firebaseStorageBucketWeb.isEmpty ? null : firebaseStorageBucketWeb,
        measurementId:
            firebaseMeasurementIdWeb.isEmpty ? null : firebaseMeasurementIdWeb,
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return FirebaseOptions(
        apiKey: firebaseApiKeyAndroid,
        appId: firebaseAppIdAndroid,
        messagingSenderId: firebaseMessagingSenderIdAndroid,
        projectId: firebaseProjectIdAndroid,
        storageBucket: firebaseStorageBucketAndroid.isEmpty
            ? null
            : firebaseStorageBucketAndroid,
      );
    }

    throw UnsupportedError(
        'EnvConfig.firebaseOptions not configured for this platform.');
  }
}

Future<void> initFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    debugPrint('[EnvConfig] Firebase already initialized, skipping.');
    return;
  }

  final options = DefaultFirebaseOptions.currentPlatform;
  try {
    await Firebase.initializeApp(options: options);
    debugPrint('[EnvConfig] Firebase initialized with ${options.projectId}.');
    
    // App Check se inicializa durante el arranque de la app (ver _initializeApp)
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint(
          '[EnvConfig] Firebase default app already exists, continuing.');
    } else {
      rethrow;
    }
  }
}

/// Optionally configure Google Maps at runtime.
Future<void> configureGoogleMaps() async {
  if (kIsWeb) {
    final key = EnvConfig.instance.googleMapsApiKey;
    if (key.isEmpty) {
      debugPrint('[EnvConfig] GOOGLE_MAPS_API_KEY is missing in .env');
    } else {
      debugPrint('[EnvConfig] Google Maps API Key configured: ${key.substring(0, 8)}...');
    }
  }
}
