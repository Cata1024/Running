import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/models/user_profile_dto.dart';
import '../../data/models/territory_dto.dart';
import '../../data/models/run_dto.dart';
import '../../core/map_icons.dart';
import '../../domain/services/storage_service.dart';

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

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();
  ref.onDispose(service.dispose);
  return service;
});

final apiHealthProvider = FutureProvider.autoDispose<bool>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.health();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Firebase Auth Service Provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FirebaseAuthService(apiService: apiService);
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

/// Métodos para cambiar estados (usaremos Consumer widgets en lugar de notifiers)
/// Estos proveedores servirán para lectura, y manejaremos los cambios directamente en los widgets

final userProfileDtoProvider = FutureProvider.autoDispose<UserProfileDto?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;
  final api = ref.watch(apiServiceProvider);
  return api.fetchUserProfileDto(user.uid);
});

/// Verifica si el usuario tiene un perfil completo
final hasCompleteProfileProvider = Provider<bool>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return false;

  final profileAsync = ref.watch(userProfileDtoProvider);
  return profileAsync.when(
    data: (dto) {
      if (dto == null) return false;
      final hasName = (dto.displayName ?? '').trim().isNotEmpty;
      final hasBirth = dto.birthDate != null;
      return hasName && hasBirth;
    },
    loading: () => false, // Devuelve false mientras carga para evitar falsos positivos
    error: (_, __) => false,
  );
});


final userTerritoryDtoProvider = FutureProvider.autoDispose<TerritoryDto?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;
  final api = ref.watch(apiServiceProvider);
  return api.fetchTerritoryDto(user.uid);
});

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
