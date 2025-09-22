import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';

// Provider para el estado de la carrera
final runStateProvider = StateNotifierProvider<RunStateNotifier, RunState>((ref) {
  return RunStateNotifier();
});

// Modelo del estado
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

// StateNotifier para manejar el estado
class RunStateNotifier extends StateNotifier<RunState> {
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  RunStateNotifier() : super(const RunState()) {
    _initializeLocation();
  }

  // Inicializar ubicación al cargar
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
      print('Error inicializando ubicación: $e');
    }
  }

  // Solicitar permisos de ubicación
  Future<bool> _requestLocationPermission() async {
    try {
      if (kIsWeb) {
        // En web, usar Geolocator directamente
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        return permission == LocationPermission.whileInUse || 
               permission == LocationPermission.always;
      } else {
        // En móvil, usar permission_handler
        final permission = await Permission.location.request();
        return permission.isGranted;
      }
    } catch (e) {
      print('Error solicitando permisos: $e');
      return false;
    }
  }

  // Iniciar carrera
  Future<void> startRun() async {
    if (!state.locationPermissionGranted) {
      final permission = await _requestLocationPermission();
      if (!permission) {
        print('Permisos de ubicación denegados');
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
    _startLocationTracking();
  }

  // Pausar carrera
  void pauseRun() {
    state = state.copyWith(isPaused: true);
    _stopTimer();
    _stopLocationTracking();
  }

  // Reanudar carrera
  void resumeRun() {
    state = state.copyWith(isPaused: false);
    _startTimer();
    _startLocationTracking();
  }

  // Finalizar carrera
  void stopRun() {
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
    );
    _stopTimer();
    _stopLocationTracking();
    _checkCircuitClosed();
  }

  // Resetear carrera
  void resetRun() {
    _stopTimer();
    _stopLocationTracking();
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

  // Tracking de ubicación
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!state.isPaused && state.isRunning) {
        _updateLocation(position);
      }
    });
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _updateLocation(Position position) {
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
      print('Error obteniendo ubicación: $e');
      // Ubicación por defecto (Bogotá) si falla
      return null;
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _stopLocationTracking();
    super.dispose();
  }
}

// Página principal
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;

  LatLng _initialCenter = const LatLng(4.7110, -74.0721);
  LatLng? _myLatLng;
  bool _centeredOnce = false;

  StreamSubscription<Position>? _posSub;
  DateTime _lastCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initLocationStream();
  }

  Future<void> _initLocationStream() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      p = await Geolocator.requestPermission();
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _initialCenter = LatLng(pos.latitude, pos.longitude);
      _myLatLng = _initialCenter;
      _centeredOnce = true;
      _mapController?.moveCamera(CameraUpdate.newLatLng(_initialCenter));
      setState(() {});
    } catch (_) {}

    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      final now = DateTime.now();
      if (now.difference(_lastCameraUpdate).inMilliseconds < 700) return; // throttle
      _lastCameraUpdate = now;

      final next = LatLng(pos.latitude, pos.longitude);
      _myLatLng = next;
      _mapController?.animateCamera(CameraUpdate.newLatLng(next));
      setState(() {}); // solo actualiza overlays (marker/circle)
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // requerido por AutomaticKeepAliveClientMixin
    final runState = ref.watch(runStateProvider);
    final runNotifier = ref.read(runStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Territory Run')),
      body: Column(
        children: [
          _buildMetricsPanel(runState),
          Expanded(flex: 3, child: _buildMap(runState)),
          _buildControlPanel(runState, runNotifier),
        ],
      ),
    );
  }

  Widget _buildMap(RunState runState) {
    final Set<Marker> markers = {
      if (runState.startLocation != null)
        Marker(
          markerId: const MarkerId('start'),
          position: runState.startLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Inicio'),
        ),
      if (runState.currentLocation != null && runState.isRunning)
        Marker(
          markerId: const MarkerId('current'),
          position: runState.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Posición Actual'),
        ),
      if (_myLatLng != null)
        Marker(
          markerId: const MarkerId('me'),
          position: _myLatLng!,
          zIndex: 9999,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
        ),
    };

    final Set<Circle> circles = {
      if (_myLatLng != null)
        Circle(
          circleId: const CircleId('me-accuracy'),
          center: _myLatLng!,
          radius: 15, // visual
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue.withOpacity(0.4),
          strokeWidth: 1,
          zIndex: 9998,
        ),
    };

    return GoogleMap(
      key: const ValueKey('main-map'), // clave estable
      onMapCreated: (c) {
        _mapController = c;
        if (_centeredOnce) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _mapController?.moveCamera(CameraUpdate.newLatLng(_initialCenter));
          });
        }
      },
      initialCameraPosition: CameraPosition(target: _initialCenter, zoom: 16),
      myLocationEnabled: false,          // en Web no siempre muestra el dot nativo
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      markers: markers,
      circles: circles,
      // polylines: _buildPolylines(runState), // si las usas
    );
  }

  Widget _buildMetricsPanel(RunState runState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricCard(
            'Tiempo',
            _formatDuration(runState.elapsed),
            Icons.timer,
          ),
          _buildMetricCard(
            'Distancia',
            '${runState.distance.toStringAsFixed(2)} km',
            Icons.straighten,
          ),
          _buildMetricCard(
            'Ritmo',
            runState.averagePace > 0 
                ? '${runState.averagePace.toStringAsFixed(1)} min/km'
                : '--:--',
            Icons.speed,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Set<Polyline> _buildPolylines(RunState runState) {
    if (runState.routePoints.length < 2) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: runState.routePoints,
        color: runState.isCircuitClosed ? Colors.green : Colors.blue,
        width: 4,
        patterns: [],
      ),
    };
  }

  Widget _buildControlPanel(RunState runState, RunStateNotifier runNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Estado de permisos
          if (!runState.locationPermissionGranted)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Permisos de ubicación necesarios para el tracking',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          
          // Botones de control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!runState.isRunning) ...[
                ElevatedButton.icon(
                  onPressed: () => runNotifier.startRun(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ] else ...[
                if (!runState.isPaused) ...[
                  ElevatedButton.icon(
                    onPressed: () => runNotifier.pauseRun(),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pausar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => runNotifier.resumeRun(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reanudar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: () => runNotifier.stopRun(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Finalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              if (runState.isRunning || runState.elapsed.inSeconds > 0) ...[
                ElevatedButton.icon(
                  onPressed: () => runNotifier.resetRun(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
}