import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants.dart';
import '../../../models/route_model.dart';

// -----------------------------
// Centralized Position Stream
// -----------------------------
final positionStreamProvider = StreamProvider<Position>((ref) async* {
  // Solicita permisos antes de exponer el stream para evitar errores
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!(permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse)) {
      throw Exception('Location permission not granted');
    }
  } catch (e) {
    // Re-lanzar para que el provider quede en error y los consumidores lo manejen
    throw Exception('Error requesting location permission: $e');
  }

  const settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  // Simplemente devolvemos el stream del Geolocator
  yield* Geolocator.getPositionStream(locationSettings: settings);
});

// Provider para el estado de la carrera refactorizado para recibir Ref
final runStateProvider =
    NotifierProvider<RunStateNotifier, RunState>(RunStateNotifier.new);

// Modelo del estado
class RunState {
  static const Object _plannedRouteSentinel = Object();

  final bool isRunning;
  final bool isPaused;
  final Duration elapsed;
  final double distance;
  final double averagePace;
  final List<LatLng> routePoints;
  final LatLng? startLocation;
  final LatLng? currentLocation;
  final bool isCircuitClosed;
  final bool locationPermissionGranted;
  final RouteModel? plannedRoute;
  final List<LatLng> plannedRoutePreview;

  const RunState({
    this.isRunning = false,
    this.isPaused = false,
    this.elapsed = Duration.zero,
    this.distance = 0.0,
    this.averagePace = 0.0,
    this.routePoints = const [],
    this.startLocation,
    this.currentLocation,
    this.isCircuitClosed = false,
    this.locationPermissionGranted = false,
    this.plannedRoute,
    this.plannedRoutePreview = const [],
  });

  RunState copyWith({
    bool? isRunning,
    bool? isPaused,
    Duration? elapsed,
    double? distance,
    double? averagePace,
    List<LatLng>? routePoints,
    LatLng? startLocation,
    LatLng? currentLocation,
    bool? isCircuitClosed,
    bool? locationPermissionGranted,
    Object? plannedRoute = _plannedRouteSentinel,
    List<LatLng>? plannedRoutePreview,
  }) {
    return RunState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      distance: distance ?? this.distance,
      averagePace: averagePace ?? this.averagePace,
      routePoints: routePoints ?? this.routePoints,
      startLocation: startLocation ?? this.startLocation,
      currentLocation: currentLocation ?? this.currentLocation,
      isCircuitClosed: isCircuitClosed ?? this.isCircuitClosed,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      plannedRoute: identical(plannedRoute, _plannedRouteSentinel)
          ? this.plannedRoute
          : plannedRoute as RouteModel?,
      plannedRoutePreview: plannedRoutePreview ?? this.plannedRoutePreview,
    );
  }
}

// StateNotifier que escucha el positionStreamProvider en lugar de crear su propio stream
class RunStateNotifier extends Notifier<RunState> {
  Timer? _timer;

  @override
  RunState build() {
    // Escucha el stream centralizado de posición.
    ref.listen<AsyncValue<Position>>(positionStreamProvider, (previous, next) {
      next.when(
        data: (pos) {
          // Solo procesamos actualizaciones cuando la carrera está activa
          if (state.isRunning && !state.isPaused) {
            _updateLocationFromPosition(pos);
          }
        },
        loading: () {},
        error: (e, st) {
          debugPrint('Position stream error in RunStateNotifier: $e');
        },
      );
    });

    _initializeLocation();
    ref.onDispose(_stopTimer);

    return const RunState();
  }

  // Inicializar ubicación al cargar (pide permisos y obtiene una posición inicial)
  Future<void> _initializeLocation() async {
    try {
      final permission = await _requestLocationPermission();
      state = state.copyWith(locationPermissionGranted: permission);

      if (permission) {
        final position = await _getCurrentPosition();
        if (position != null) {
          final currentLocation = LatLng(position.latitude, position.longitude);
          state = state.copyWith(currentLocation: currentLocation);
        }
      }
    } catch (e) {
      debugPrint('Error inicializando ubicación: $e');
    }
  }

  // Solicitar permisos de ubicación. NOTA: el stream provider también los solicita, pero
  // mantenemos esta función para flujos explícitos (ej. botón iniciar)
  Future<bool> _requestLocationPermission() async {
    try {
      if (kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        return permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
      } else {
        final permission = await Permission.location.request();
        return permission.isGranted;
      }
    } catch (e) {
      debugPrint('Error solicitando permisos: $e');
      return false;
    }
  }

  // Iniciar carrera
  Future<void> startRun() async {
    if (!state.locationPermissionGranted) {
      final permission = await _requestLocationPermission();
      if (!permission) {
        debugPrint('Permisos de ubicación denegados');
        return;
      }
      state = state.copyWith(locationPermissionGranted: true);
    }

    final position = await _getCurrentPosition();
    if (position == null) return;

    final startLocation = LatLng(position.latitude, position.longitude);

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      startLocation: startLocation,
      currentLocation: startLocation,
      routePoints: [startLocation],
      elapsed: Duration.zero,
      distance: 0.0,
      isCircuitClosed: false,
    );

    _startTimer();
  }

  // Pausar carrera
  void pauseRun() {
    state = state.copyWith(isPaused: true);
    _stopTimer();
  }

  // Reanudar carrera
  void resumeRun() {
    state = state.copyWith(isPaused: false);
    _startTimer();
  }

  // Finalizar carrera
  Future<void> stopRun() async {
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
    );
    _stopTimer();
    _checkCircuitClosed();

    // Si se cerró circuito y se cumplieron mínimos, calcular y aplicar tiles
    final meetsTime = state.elapsed.inSeconds >= AppConstants.minRunDuration;
    final meetsDistance = state.distance >= AppConstants.minRunDistance;
    if (state.isCircuitClosed && meetsTime && meetsDistance) {
      // TODO: Replace with polyline-based achievements/analytics.
    }
  }

  // Resetear carrera
  void resetRun() {
    _stopTimer();
    state = RunState(
      locationPermissionGranted: state.locationPermissionGranted,
      currentLocation: state.currentLocation,
    );
  }

  void selectPlannedRoute(RouteModel route) {
    final preview = route.decodedPoints;
    state = state.copyWith(
      plannedRoute: route,
      plannedRoutePreview: preview,
    );
  }

  void clearPlannedRoute() {
    state = state.copyWith(
      plannedRoute: null,
      plannedRoutePreview: const [],
    );
  }

  // Timer para el cronómetro
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPaused && state.isRunning) {
        final newElapsed = Duration(seconds: state.elapsed.inSeconds + 1);
        final newPace = _calculateAveragePace(state.distance, newElapsed);

        state = state.copyWith(
          elapsed: newElapsed,
          averagePace: newPace,
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Actualiza la ubicación basada en Position (llamado desde el listener del provider)
  void _updateLocationFromPosition(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    final updatedRoute = [...state.routePoints, newLocation];

    final newDistance = _calculateTotalDistance(updatedRoute);
    final newPace = _calculateAveragePace(newDistance, state.elapsed);

    state = state.copyWith(
      currentLocation: newLocation,
      routePoints: updatedRoute,
      distance: newDistance,
      averagePace: newPace,
    );

    // Revisa en vivo si ya se cerró el circuito
    _checkCircuitClosed();
  }

  // Verificar si el circuito está cerrado
  void _checkCircuitClosed() {
    if (state.startLocation != null && state.currentLocation != null) {
      final distance = Geolocator.distanceBetween(
        state.startLocation!.latitude,
        state.startLocation!.longitude,
        state.currentLocation!.latitude,
        state.currentLocation!.longitude,
      );

      final isClosed = distance <= AppConstants.circuitCloseRadius;
      state = state.copyWith(isCircuitClosed: isClosed);
    }
  }

  // Calcular distancia total
  double _calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return totalDistance / 1000; // Convertir a km
  }

  // Calcular pace promedio
  double _calculateAveragePace(double distanceKm, Duration elapsed) {
    if (distanceKm == 0) return 0.0;
    return elapsed.inSeconds / 60 / distanceKm; // min/km
  }

  // Obtener posición actual
  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      return null;
    }
  }
}
