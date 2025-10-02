import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../shared/services.dart' as shared_services;
import '../services/territory_service.dart';
import '../core/constants.dart';
import 'map_widget.dart'; // Importa el nuevo widget de mapa
import '../core/marker_utils.dart';
import '../core/map_styles.dart';

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
    if (!(permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
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
final runStateProvider = StateNotifierProvider<RunStateNotifier, RunState>((ref) {
  return RunStateNotifier(ref);
});

// Modelo del estado (sin cambios)
class RunState {
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
      locationPermissionGranted: locationPermissionGranted ?? this.locationPermissionGranted,
    );
  }
}

// StateNotifier refactorizado: escucha el positionStreamProvider en lugar de crear su propio stream
class RunStateNotifier extends StateNotifier<RunState> {
  final Ref ref;
  Timer? _timer;
  final _auth = AuthService();

  RunStateNotifier(this.ref) : super(const RunState()) {
    _initializeLocation();

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
        return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
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
    // Antes: start location tracking aquí; ahora el notifier confía en el positionStreamProvider
  }

  // Pausar carrera
  void pauseRun() {
    state = state.copyWith(isPaused: true);
    _stopTimer();
    // Notifier no cancela el stream—el listener ignora actualizaciones cuando isPaused == true
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
      final user = _auth.currentUser;
      if (user != null) {
        final territoryService = TerritoryService();
        final tiles = await territoryService.computeTilesFromTrack(track: state.routePoints);
        await territoryService.applyTiles(userId: user.uid, tiles: tiles, capture: true);
      }
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

// -----------------------------
// HomePage refactorizada para consumir positionStreamProvider
// -----------------------------
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<MapContainerState> _mapContainerKey = GlobalKey<MapContainerState>();
  GoogleMapController? _mapController;
  bool _showOnlyMine = true; // toggle de visualización de territorio

  // Ubicación del usuario (punto azul), separada del estado de la carrera.
  LatLng? _currentUserLocation;
  // Preferencias y control de cámara
  bool _followUser = true;
  MapType _mapType = MapType.normal;
  DateTime? _lastCameraUpdate;
  // Íconos personalizados
  BitmapDescriptor? _runnerIconBlue;
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_mapController != null && mounted) {
      if (_mapStyle != null) {
        _mapController!.setMapStyle(_mapStyle!);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get _mapStyle {
    if (!mounted) return null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? MapStyles.dark : MapStyles.light;
  }

  Future<void> _loadMarkerIcons() async {
    try {
      final blue = await MarkerUtils.runnerMarker(size: 72, bg: const Color(0xFF1E88E5));
      if (mounted) {
        setState(() {
          _runnerIconBlue = blue;
        });
      }
    } catch (e) {
      debugPrint('Error creando íconos de marcador: $e');
    }
  }

  Set<Marker> _buildMarkers(RunState runState) {
    final markers = <Marker>{};

    // Add user location marker
    if (_currentUserLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('userLocation'),
        position: _currentUserLocation!,
        icon: _runnerIconBlue ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        rotation: _heading,
        flat: true,
        zIndexInt: 1,
      ));
    }

    // Add start location marker if available
    if (runState.startLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('startLocation'),
        position: runState.startLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(RunState runState) {
    if (runState.routePoints.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: runState.routePoints,
        color: runState.isCircuitClosed ? Colors.green : Colors.blue,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  Set<Polygon> _buildPolygons(RunState runState) {
    final meetsTime = runState.elapsed.inSeconds >= AppConstants.minRunDuration;
    final meetsDistance = runState.distance >= AppConstants.minRunDistance;
    final isClosed = runState.isCircuitClosed;

    if (!isClosed || !meetsTime || !meetsDistance) return {};
    if (runState.routePoints.length < 3) return {};

    return {
      Polygon(
        polygonId: const PolygonId('circuit'),
        points: runState.routePoints,
        strokeWidth: 3,
        strokeColor: Colors.green,
        fillColor: Colors.green.withAlpha(51),
      )
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Position>>(positionStreamProvider, (previous, next) {
      next.when(
        data: (position) {
          if (!mounted) return;
          setState(() {
            _currentUserLocation = LatLng(position.latitude, position.longitude);
            if (position.heading.isFinite) {
              _heading = position.heading;
            }
          });

          if (_followUser) {
            final now = DateTime.now();
            if (_lastCameraUpdate == null || now.difference(_lastCameraUpdate!) > const Duration(milliseconds: 500)) {
              _lastCameraUpdate = now;
              final camPos = CameraPosition(
                target: _currentUserLocation!,
                zoom: 17,
                bearing: position.heading.isFinite ? position.heading : 0,
              );
              _mapContainerKey.currentState?.moveCamera(CameraUpdate.newCameraPosition(camPos));
            }
          }
        },
        loading: () {},
        error: (e, st) {
          debugPrint('Position stream error in HomePage: $e');
        },
      );
    });

    final runState = ref.watch(runStateProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_outlined),
            tooltip: 'Personalización',
            onPressed: _openPreferencesSheet,
          ),
          IconButton(
            tooltip: _showOnlyMine ? 'Ver territorio de todos' : 'Ver solo mi territorio',
            icon: Icon(_showOnlyMine ? Icons.public : Icons.person_pin_circle),
            onPressed: () => setState(() { _showOnlyMine = !_showOnlyMine; }),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap(runState)),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _buildMetricsRow(runState),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFab(context, runState),
    );
  }

  Widget _buildMap(RunState runState) {
    final markers = _buildMarkers(runState);
    final polylines = _buildPolylines(runState);
    final polygons = _buildPolygons(runState)..addAll(_buildTerritoryPolygons());

    return MapContainer(
      key: _mapContainerKey,
      mapStyle: _mapStyle,
      initialPosition: CameraPosition(
        target: _currentUserLocation ?? const LatLng(4.7110, -74.0721),
        zoom: 14,
      ),
      markers: markers,
      polylines: polylines,
      polygons: polygons,
      mapType: _mapType,
      onMapCreated: (controller) {
        _mapController = controller;
        if (mounted) {
          controller.setMapStyle(_mapStyle);
        }
        if (_currentUserLocation != null) {
          controller.animateCamera(CameraUpdate.newLatLng(_currentUserLocation!));
        }
      },
    );
  }

  Set<Polygon> _buildTerritoryPolygons() {
    final currentUser = ref.read(shared_services.currentUserProvider);
    final myTiles = currentUser != null
        ? ref.read(myTerritoryTilesProvider(currentUser.uid)).maybeWhen(
            data: (d) => d,
            orElse: () => const [])
        : const [];

    final allTiles = ref.read(allTerritoryTilesProvider).maybeWhen(
      data: (d) => d,
      orElse: () => const []);

    final tiles = _showOnlyMine ? myTiles : allTiles;
    final color = _showOnlyMine ? Colors.blue : Colors.purple;
    final polygons = <Polygon>{};

    for (final tile in tiles) {
      try {
        final corners = tile.toPolygonCorners();
        polygons.add(Polygon(
          polygonId: PolygonId('tile_${tile.key}'),
          points: corners,
          strokeWidth: 1,
          strokeColor: color.withAlpha(179),
          fillColor: color.withAlpha(38),
          consumeTapEvents: false,
        ));
      } catch (e) {
        debugPrint('Error creating territory polygon: $e');
      }
    }

    return polygons;
  }

  Widget _buildMetricsRow(RunState runState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricChip(Icons.timer, _formatDuration(runState.elapsed), 'Tiempo'),
        _buildMetricChip(Icons.straighten, '${runState.distance.toStringAsFixed(2)} km', 'Distancia'),
        _buildMetricChip(Icons.speed, runState.averagePace > 0 ? '${runState.averagePace.toStringAsFixed(1)} min/km' : '--:--', 'Ritmo'),
      ],
    );
  }

  Widget _buildMetricChip(IconData icon, String value, String label) {
    final cs = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cs.primary, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Tooltip(message: label, child: content);
  }

  Widget _buildFab(BuildContext context, RunState runState) {
    final runNotifier = ref.read(runStateProvider.notifier);

    if (!runState.locationPermissionGranted) {
      return Tooltip(
        message: 'Permisos de ubicación requeridos',
        child: FloatingActionButton(
          onPressed: () => runNotifier.startRun(),
          child: const Icon(Icons.location_searching),
        ),
      );
    }

    if (!runState.isRunning) {
      return FloatingActionButton.extended(
        onPressed: () => runNotifier.startRun(),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar'),
      );
    }

    if (runState.isPaused) {
      return Wrap(
        spacing: 12,
        children: [
          FloatingActionButton.extended(
            onPressed: () => runNotifier.resumeRun(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Reanudar'),
          ),
          FloatingActionButton(
            heroTag: 'fab-stop',
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            onPressed: () => runNotifier.stopRun(),
            child: const Icon(Icons.stop),
          ),
          FloatingActionButton(
            heroTag: 'fab-reset',
            onPressed: () => runNotifier.resetRun(),
            child: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      children: [
        FloatingActionButton.extended(
          onPressed: () => runNotifier.pauseRun(),
          icon: const Icon(Icons.pause),
          label: const Text('Pausar'),
        ),
        FloatingActionButton(
          heroTag: 'fab-stop',
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          onPressed: () => runNotifier.stopRun(),
          child: const Icon(Icons.stop),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AuthService().signOut();
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _openPreferencesSheet() async {
    final result = await showModalBottomSheet<_PrefsResult>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        bool follow = _followUser;
        MapType mapType = _mapType;
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 8),
                    Text('Personalización', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: follow,
                  onChanged: (v) => setModalState(() => follow = v),
                  title: const Text('Seguir usuario'),
                  secondary: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.map_outlined),
                    const SizedBox(width: 8),
                    const Text('Tipo de mapa'),
                    const Spacer(),
                    DropdownButton<MapType>(
                      value: mapType,
                      onChanged: (v) => setModalState(() => mapType = v ?? MapType.normal),
                      items: const [
                        DropdownMenuItem(value: MapType.normal, child: Text('Normal')),
                        DropdownMenuItem(value: MapType.terrain, child: Text('Terreno')),
                        DropdownMenuItem(value: MapType.satellite, child: Text('Satélite')),
                        DropdownMenuItem(value: MapType.hybrid, child: Text('Híbrido')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, _PrefsResult(follow: follow, mapType: mapType)),
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );
    if (result != null) {
      setState(() {
        _followUser = result.follow;
        _mapType = result.mapType;
      });
    }
  }
}

class _PrefsResult {
  final bool follow;
  final MapType mapType;
  _PrefsResult({required this.follow, required this.mapType});
}
