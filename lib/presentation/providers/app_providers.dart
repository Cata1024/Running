import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/legal_constants.dart';
import '../../data/repositories/level_progress_repository.dart';
import '../../data/repositories/achievements_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/play_integrity_service.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../core/services/audit_logger.dart';
import '../../data/models/user_profile_dto.dart';
import '../../data/models/run_dto.dart';
import '../../core/map_icons.dart';
import '../../domain/entities/legal_consent.dart';
import '../../domain/repositories/i_level_progress_repository.dart';
import '../../domain/repositories/i_achievements_repository.dart';
import '../../domain/repositories/i_storage_repository.dart';

export 'settings_provider.dart' show settingsProvider;

/// Providers básicos que funcionan con Riverpod 3.0+

// Enums
enum AppThemeMode { system, light, dark }

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  static const String _storageKey = 'app_theme_mode';
  
  @override
  AppThemeMode build() {
    // Cargar tema guardado
    _loadTheme();
    return AppThemeMode.system;
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_storageKey);
      
      if (themeString != null) {
        final theme = AppThemeMode.values.firstWhere(
          (e) => e.name == themeString,
          orElse: () => AppThemeMode.system,
        );
        state = theme;
      }
    } catch (e) {
      // Si falla, mantener default
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    
    // Guardar en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, mode.name);
    } catch (e) {
      // Error saving theme
    }
  }
}

enum MapVisualStyle { automatic, light, dark, off }

class MapStyleNotifier extends Notifier<MapVisualStyle> {
  @override
  MapVisualStyle build() => MapVisualStyle.automatic;

  void setStyle(MapVisualStyle style) => state = style;
}

/// Filtros del historial
class HistoryFilter {
  final DateTime? start; // inicio (inclusive)
  final DateTime? end;   // fin (inclusive)
  final bool onlyClosed;
  final double minKm;
  final double maxKm;

  const HistoryFilter({
    this.start,
    this.end,
    this.onlyClosed = false,
    this.minKm = 0.0,
    this.maxKm = 50.0,
  });

  HistoryFilter copyWith({
    DateTime? start,
    DateTime? end,
    bool? onlyClosed,
    double? minKm,
    double? maxKm,
  }) {
    return HistoryFilter(
      start: start ?? this.start,
      end: end ?? this.end,
      onlyClosed: onlyClosed ?? this.onlyClosed,
      minKm: minKm ?? this.minKm,
      maxKm: maxKm ?? this.maxKm,
    );
  }
}

class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => const HistoryFilter();

  void set(HistoryFilter next) => state = next;

  void update({
    DateTime? start,
    DateTime? end,
    bool? onlyClosed,
    double? minKm,
    double? maxKm,
  }) {
    state = state.copyWith(
      start: start,
      end: end,
      onlyClosed: onlyClosed,
      minKm: minKm,
      maxKm: maxKm,
    );
  }

  void reset() => state = const HistoryFilter();
}

final historyFilterProvider = NotifierProvider<HistoryFilterNotifier, HistoryFilter>(HistoryFilterNotifier.new);

// Estados simples
class RunState {
  final bool isRunning;
  final bool isPaused;
  final Duration duration;
  final double distance;

  const RunState({
    this.isRunning = false,
    this.isPaused = false,
    this.duration = Duration.zero,
    this.distance = 0.0,
  });

  RunState copyWith({
    bool? isRunning,
    bool? isPaused,
    Duration? duration,
    double? distance,
  }) {
    return RunState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
    );
  }
}

class RunStateNotifier extends Notifier<RunState> {
  @override
  RunState build() => const RunState();

  void setRunning({required bool isRunning, bool? isPaused}) {
    state = state.copyWith(
      isRunning: isRunning,
      isPaused: isPaused ?? (isRunning ? state.isPaused : false),
    );
  }

  void setPaused(bool isPaused) {
    state = state.copyWith(isPaused: isPaused);
  }

  void reset() => state = const RunState();
}

final playIntegrityServiceProvider = Provider<PlayIntegrityService>((ref) {
  return PlayIntegrityService();
});

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final playIntegrityService = ref.watch(playIntegrityServiceProvider);
  final service = ApiService(playIntegrityService: playIntegrityService);
  ref.onDispose(service.dispose);
  return service;
});

final apiHealthProvider = FutureProvider.autoDispose<bool>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.health();
});

final levelProgressRepositoryProvider = Provider<ILevelProgressRepository>((ref) {
  return LevelProgressRepository(
    api: ref.watch(apiServiceProvider),
  );
});

final achievementsRepositoryProvider = Provider<IAchievementsRepository>((ref) {
  return AchievementsRepository(
    api: ref.watch(apiServiceProvider),
  );
});

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return FirebaseStorageRepository();
});

/// Headers autenticados para peticiones directas (e.g. imágenes protegidas)
final apiAuthHeadersProvider = FutureProvider<Map<String, String>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.authHeaders;
});


/// Firebase Auth Service Provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final auditLogger = ref.watch(auditLoggerProvider);
  return FirebaseAuthService(
    apiService: apiService,
    auditLogger: auditLogger,
  );
});

/// Auth State Stream Provider
final authStateStreamProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current Firebase User Provider
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Simple state providers usando Provider + ref.read/ref.watch
final navigationIndexProvider = Provider<int>((ref) => 0);
final appLoadingProvider = Provider<bool>((ref) => false);
final themeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);
final mapStyleProvider = NotifierProvider<MapStyleNotifier, MapVisualStyle>(
  MapStyleNotifier.new,
);
final runStateProvider = NotifierProvider<RunStateNotifier, RunState>(
  RunStateNotifier.new,
);

/// Provider para iconos del mapa (cacheado permanentemente)
final mapIconsProvider = FutureProvider<MapIconsBundle>((ref) async {
  // Los iconos son estáticos, mantenerlos en cache permanentemente
  ref.keepAlive();
  return MapIcons.load();
});

class LegalConsentNotifier extends Notifier<LegalConsent> {
  static const String _storageKey = 'legal_consent_v1';

  @override
  LegalConsent build() {
    Future.microtask(() => _loadConsent());
    return LegalConsent.initial();
  }

  Future<void> _loadConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      
      if (json != null) {
        final consent = LegalConsent.fromEncodedJson(json);
        // Verificar que las versiones sean válidas
        if (consent.termsVersion.isNotEmpty && 
            consent.privacyVersion.isNotEmpty) {
          state = consent;
          if (kDebugMode) {
            debugPrint('Cargado consentimiento legal: ${consent.toJson()}');
          }
          return;
        }
      }
      
      // Si no hay datos válidos, establecer estado inicial
      state = LegalConsent.initial();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cargando consentimiento legal: $e');
      }
      state = LegalConsent.initial();
    }
  }

  Future<void> saveConsent(LegalConsent consent) async {
    try {
      // Asegurarse de que las versiones estén establecidas
      final consentToSave = consent.copyWith(
        termsVersion: LegalConstants.termsVersion,
        privacyVersion: LegalConstants.privacyVersion,
      );
      
      // Guardar en el estado
      state = consentToSave;
      
      // Persistir en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final json = consentToSave.toEncodedJson();
      final saved = await prefs.setString(_storageKey, json);
      
      if (kDebugMode) {
        debugPrint('Consentimiento guardado: $saved - $json');
      }
      
      // Registrar en analytics
      await ref.read(auditLoggerProvider).log('compliance.legal_consent', {
        'termsVersion': consentToSave.termsVersion,
        'privacyVersion': consentToSave.privacyVersion,
        'locationConsent': consentToSave.locationConsent,
        'analyticsConsent': consentToSave.analyticsConsent,
        'marketingConsent': consentToSave.marketingConsent,
        'ageConfirmed': consentToSave.ageConfirmed,
        'saved': saved,
      });
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error guardando consentimiento legal: $e');
      }
      // Re-lanzar el error para que el llamador pueda manejarlo
      rethrow;
    }
  }

  Future<void> clearConsent() async {
    state = LegalConsent.initial();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

final legalConsentProvider = NotifierProvider<LegalConsentNotifier, LegalConsent>(
  LegalConsentNotifier.new,
);

/// Métodos para cambiar estados (usaremos Consumer widgets en lugar de notifiers)
/// Estos proveedores servirán para lectura, y manejaremos los cambios directamente en los widgets

final userProfileDtoProvider = FutureProvider.autoDispose<UserProfileDto?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;
  final api = ref.watch(apiServiceProvider);
  return api.fetchUserProfileDto(user.uid);
});

/// Verifica si el usuario tiene un perfil completo
final hasCompleteProfileProvider = Provider<AsyncValue<bool>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) {
    return const AsyncValue.data(false);
  }

  final profileAsync = ref.watch(userProfileDtoProvider);

  return profileAsync.when(
    data: (dto) {
      if (dto == null) {
        return const AsyncValue<bool>.data(false);
      }

      final hasName = (dto.displayName ?? '').trim().isNotEmpty;
      final hasBirth = dto.birthDate != null;
      final completed = dto.completedOnboarding ?? (hasName && hasBirth);
      return AsyncValue<bool>.data(completed && hasName && hasBirth);
    },
    loading: () => const AsyncValue<bool>.loading(),
    error: (error, stackTrace) {
      Future.microtask(() {
        ref.read(auditLoggerProvider).log('auth.profile_fetch_error', {
          'uid': user.uid,
          'error': error.toString(),
        });
      });

      if (_hasMinimalProfile(user)) {
        if (kDebugMode) {
          debugPrint('hasCompleteProfileProvider fallback (minimal profile) due to error: $error');
        }
        return const AsyncValue<bool>.data(true);
      }
      return AsyncValue<bool>.error(error, stackTrace);
    },
  );
});

bool _hasMinimalProfile(User user) {
  final fallbackName = (user.displayName ?? user.email ?? '').trim();
  return fallbackName.isNotEmpty;
}


final userRunsDtoProvider = FutureProvider.autoDispose<List<RunDto>>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return const <RunDto>[];
  final api = ref.watch(apiServiceProvider);
  return api.fetchRunsDto(limit: 50);
});

final runDocDtoProvider = FutureProvider.family<RunDto?, String>((ref, id) async {
  // Mantener en cache para evitar recargas
  ref.keepAlive();
  final api = ref.watch(apiServiceProvider);
  return api.fetchRunDto(id);
});

class MapTypeNotifier extends Notifier<MapType> {
  @override
  MapType build() => MapType.normal;

  void setMapType(MapType type) => state = type;
}

final mapTypeProvider = NotifierProvider<MapTypeNotifier, MapType>(
  MapTypeNotifier.new,
);

class NavBarHeightNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void setHeight(double height) {
    if (height != state) {
      state = height;
    }
  }
}

final navBarHeightProvider = NotifierProvider<NavBarHeightNotifier, double>(
  NavBarHeightNotifier.new,
);
