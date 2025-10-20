import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/api_service.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../core/map_icons.dart';

/// Providers básicos que funcionan con Riverpod 3.0+

// Enums
enum AppThemeMode { system, light, dark }

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() => AppThemeMode.system;

  void setTheme(AppThemeMode mode) => state = mode;
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

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();
  ref.onDispose(service.dispose);
  return service;
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
final runStateProvider = Provider<RunState>((ref) => const RunState());

final mapIconsProvider = FutureProvider<MapIconsBundle>((ref) async {
  return MapIcons.load();
});

/// Métodos para cambiar estados (usaremos Consumer widgets en lugar de notifiers)
/// Estos proveedores servirán para lectura, y manejaremos los cambios directamente en los widgets

/// Perfil de usuario (Firestore: users/{uid})
final userProfileDocProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;
  final api = ref.watch(apiServiceProvider);
  return api.fetchUserProfile(user.uid);
});

/// Territorio del usuario (Firestore: territory/{uid})
final userTerritoryDocProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;
  final api = ref.watch(apiServiceProvider);
  return api.fetchTerritory(user.uid);
});

/// Últimas carreras del usuario (Firestore: runs, filtrado por userId)
final userRunsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return const [];
  final api = ref.watch(apiServiceProvider);
  return api.fetchRuns(limit: 50);
});

/// Documento de run por id (Firestore: runs/{id})
final runDocProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchRun(id);
});

class MapTypeNotifier extends Notifier<MapType> {
  @override
  MapType build() => MapType.normal;

  void setMapType(MapType type) => state = type;
}

final mapTypeProvider = NotifierProvider<MapTypeNotifier, MapType>(
  MapTypeNotifier.new,
);
