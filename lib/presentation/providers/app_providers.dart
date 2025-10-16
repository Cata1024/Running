import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/firebase_auth_service.dart';

/// Providers básicos que funcionan con Riverpod 3.0+

// Enums
enum AppThemeMode { system, light, dark }

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

/// Firebase Auth Service Provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
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
final themeProvider = Provider<AppThemeMode>((ref) => AppThemeMode.system);
final runStateProvider = Provider<RunState>((ref) => const RunState());

/// Métodos para cambiar estados (usaremos Consumer widgets en lugar de notifiers)
/// Estos proveedores servirán para lectura, y manejaremos los cambios directamente en los widgets

/// Perfil de usuario (Firestore: users/{uid})
final userProfileDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return const Stream.empty();
  final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  return doc.snapshots().map((s) => s.data());
});

/// Territorio del usuario (Firestore: territory/{uid})
final userTerritoryDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return const Stream.empty();
  final doc = FirebaseFirestore.instance.collection('territory').doc(user.uid);
  return doc.snapshots().map((s) => s.data());
});

/// Últimas carreras del usuario (Firestore: runs, filtrado por userId)
final userRunsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return const Stream.empty();
  final query = FirebaseFirestore.instance
      .collection('runs')
      .where('userId', isEqualTo: user.uid)
      .orderBy('startedAt', descending: true)
      .limit(20);
  return query.snapshots().map((snap) =>
      snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

/// Documento de run por id (Firestore: runs/{id})
final runDocProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, id) {
  final doc = FirebaseFirestore.instance.collection('runs').doc(id);
  return doc.snapshots().map((s) => s.data());
});
