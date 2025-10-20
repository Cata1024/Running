import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/map_icons.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../domain/services/circuit_closure_validator.dart';
import '../../../domain/services/territory_service.dart';
import '../../providers/app_providers.dart';
import '../../utils/map_style_utils.dart';

class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

Set<Polygon> _parseTerritoryPolygons(
    Map<String, dynamic>? doc, ThemeData theme) {
  if (doc == null) return <Polygon>{};
  final geo = doc['unionGeoJson'];
  if (geo is! Map) return <Polygon>{};

  final stroke = theme.colorScheme.secondary;
  final fill = theme.colorScheme.secondary.withValues(alpha: 0.20);

  final Set<Polygon> out = {};
  final type = geo['type'];
  if (type == 'Polygon') {
    final coords = (geo['coordinates'] as List?) ?? const [];
    if (coords.isEmpty) return out;
    final outer = coords.first as List;
    final pts = outer
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    if (pts.length >= 3) {
      out.add(Polygon(
        polygonId: const PolygonId('territory-0'),
        points: pts,
        strokeWidth: 2,
        strokeColor: stroke,
        fillColor: fill,
      ));
    }
  } else if (type == 'MultiPolygon') {
    final polys = (geo['coordinates'] as List?) ?? const [];
    for (int i = 0; i < polys.length; i++) {
      final poly = polys[i] as List; // rings
      if (poly.isEmpty) continue;
      final outer = poly.first as List;
      final pts = outer
          .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      if (pts.length >= 3) {
        out.add(Polygon(
          polygonId: PolygonId('territory-$i'),
          points: pts,
          strokeWidth: 2,
          strokeColor: stroke,
          fillColor: fill,
        ));
      }
    }
  }
  return out;
}

class _RunScreenState extends ConsumerState<RunScreen> {
  // Tracking variables
  StreamSubscription<Position>? _positionStream;

  // Estado del tracking
  bool _isRunning = false;
  bool _isPaused = false;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;

  // Stats
  Duration _elapsedTime = Duration.zero;
  double _totalDistance = 0.0;
  DateTime? _startedAt;

  // Ubicación inicial
  LatLng _currentLocation = const LatLng(4.6097, -74.0817);
  Timer? _timer;
  MapIconsBundle? _iconBundle;

  Set<Marker> _buildMarkers([MapIconsBundle? bundle]) {
    final icons = bundle ?? _iconBundle;
    if (_routePoints.isEmpty) {
      return {
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Ubicación actual'),
          icon: icons?.runner ?? BitmapDescriptor.defaultMarker,
        ),
      };
    }

    final start = _routePoints.first;
    final end = _routePoints.last;
    final bool isActive = _isRunning && !_isPaused;

    return {
      Marker(
        markerId: const MarkerId('start'),
        position: start,
        infoWindow: const InfoWindow(title: 'Inicio de la carrera'),
        icon: icons?.start ?? BitmapDescriptor.defaultMarkerWithHue(110),
      ),
      Marker(
        markerId: const MarkerId('current_location'),
        position: end,
        infoWindow: InfoWindow(
          title: isActive
              ? (_isPaused ? 'Pausado' : 'Corriendo...')
              : 'Fin de la carrera',
        ),
        icon: isActive
            ? (icons?.runner ?? BitmapDescriptor.defaultMarker)
            : (icons?.finish ?? BitmapDescriptor.defaultMarkerWithHue(0)),
      ),
    };
  }

  Set<Polyline> _buildPolylines(ThemeData theme) {
    if (_routePoints.length < 2) return const <Polyline>{};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: theme.colorScheme.primary,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    ref.read(mapIconsProvider.future).then((bundle) {
      if (!mounted) return;
      setState(() {
        _iconBundle = bundle;
        _markers = _buildMarkers(bundle);
      });
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _markers = _buildMarkers();
      });

      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 17));
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  void _startTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!mounted) return;
      final newLocation = LatLng(position.latitude, position.longitude);

      if (_routePoints.isNotEmpty) {
        final lastPoint = _routePoints.last;
        final distance = Geolocator.distanceBetween(
          lastPoint.latitude,
          lastPoint.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );

        _totalDistance += distance / 1000; // Convert to km
      }

      final theme = Theme.of(context);
      setState(() {
        _currentLocation = newLocation;
        _routePoints.add(newLocation);
        _markers = _buildMarkers();
        _polylines = _buildPolylines(theme);
      });

      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 17));
    });

    // Timer para el cronómetro
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && !_isPaused) {
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _toggleRun() async {
    if (_isRunning) {
      // Stop run: detener streams y guardar en Firestore
      _positionStream?.cancel();
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        _isPaused = false;
        _markers = _buildMarkers();
      });
      await _saveRunToBackend();
    } else {
      // Start run: resetear estado y comenzar tracking
      setState(() {
        _isRunning = true;
        _isPaused = false;
        _elapsedTime = Duration.zero;
        _totalDistance = 0.0;
        _routePoints = [];
        _startedAt = DateTime.now();
        _markers = _buildMarkers();
        _polylines = const <Polyline>{};
      });
      _startTracking();
    }
  }

  void _pauseRun() {
    if (_isRunning) {
      setState(() {
        _isPaused = !_isPaused;
        _markers = _buildMarkers();
      });

      // no-op for animation removed
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _saveRunToBackend() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      if (_startedAt == null) return;
      final endedAt = DateTime.now();

      final coords = _routePoints
          .map((p) => [p.longitude, p.latitude])
          .toList(growable: false);

      // Validar cierre de circuito y preparar polígono/área
      final isClosed = const CircuitClosureValidator().isClosedCircuit(
        routePoints: _routePoints,
        duration: _elapsedTime,
      );

      Map<String, dynamic>? polygonGeoJson;
      double? areaGainedM2;
      Map<String, dynamic>? updatedTerritory;
      if (isClosed && _routePoints.length >= 3) {
        final territoryService = const TerritoryService();
        polygonGeoJson = territoryService.buildPolygonFromRoute(_routePoints);
        areaGainedM2 = territoryService.polygonAreaM2(polygonGeoJson);
        final existingTerritory =
            await ref.read(userTerritoryDocProvider.future);
        updatedTerritory = territoryService.mergeTerritory(
          existing: existingTerritory,
          newPolygon: polygonGeoJson,
          areaGainedM2: areaGainedM2,
        );
      }

      final runData = {
        'userId': uid,
        'startedAt': _startedAt!.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'distanceM': (_totalDistance * 1000).round(),
        'durationS': _elapsedTime.inSeconds,
        'avgPaceSecPerKm': _totalDistance > 0
            ? (_elapsedTime.inSeconds / _totalDistance)
            : null,
        'isClosedCircuit': isClosed,
        'startLat': _routePoints.isNotEmpty
            ? _routePoints.first.latitude
            : _currentLocation.latitude,
        'startLon': _routePoints.isNotEmpty
            ? _routePoints.first.longitude
            : _currentLocation.longitude,
        'endLat': _routePoints.isNotEmpty
            ? _routePoints.last.latitude
            : _currentLocation.latitude,
        'endLon': _routePoints.isNotEmpty
            ? _routePoints.last.longitude
            : _currentLocation.longitude,
        'routeGeoJson': {
          'type': 'LineString',
          'coordinates': coords,
        },
        if (polygonGeoJson != null) 'polygonGeoJson': polygonGeoJson,
        if (areaGainedM2 != null) 'areaGainedM2': areaGainedM2,
        'synced': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final api = ref.read(apiServiceProvider);

      if (updatedTerritory != null) {
        await api.upsertTerritory(uid, updatedTerritory);
      }

      final runId = await api.createRun(runData);

      final profile = await ref.read(userProfileDocProvider.future);
      final currentTotalRuns = (profile?['totalRuns'] as num?)?.toInt() ?? 0;
      final currentTotalDistance =
          (profile?['totalDistance'] as num?)?.toDouble() ?? 0.0;
      final currentTotalTime = (profile?['totalTime'] as num?)?.toInt() ?? 0;

      await api.patchUserProfile(uid, {
        'totalRuns': currentTotalRuns + 1,
        'totalDistance': currentTotalDistance + _totalDistance,
        'totalTime': currentTotalTime + _elapsedTime.inSeconds,
        'lastActivityAt': endedAt.toIso8601String(),
      });

      ref.invalidate(userRunsProvider);
      ref.invalidate(runDocProvider(runId));
      ref.invalidate(userProfileDocProvider);
      ref.invalidate(userTerritoryDocProvider);
    } catch (e) {
      debugPrint('Error guardando run: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final territoryAsync = ref.watch(userTerritoryDocProvider);
    final mapType = ref.watch(mapTypeProvider);
    final mapStyle = ref.watch(mapStyleProvider);
    final styleString = resolveMapStyle(mapStyle, theme.brightness);
    final Set<Polygon> territoryPolygons = territoryAsync.maybeWhen(
      data: (doc) => _parseTerritoryPolygons(doc, theme),
      orElse: () => <Polygon>{},
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Mapa a pantalla completa
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 17,
                ),
                markers: _markers,
                polylines: _polylines,
                polygons: territoryPolygons,
                mapType: mapType,
                style: styleString,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),

            // Stats overlay - Tamaño optimizado con mejor contraste
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tiempo
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_elapsedTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Tiempo',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Distancia
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _totalDistance.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'km',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ritmo
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _totalDistance > 0
                                ? (() {
                                    final paceSecPerKm =
                                        _elapsedTime.inSeconds / _totalDistance;
                                    final m = (paceSecPerKm / 60).floor();
                                    final s = (paceSecPerKm % 60)
                                        .round()
                                        .toString()
                                        .padLeft(2, '0');
                                    return '$m:$s';
                                  })()
                                : '--:--',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'min/km',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Indicador de estado
            if (_isRunning || _isPaused)
              Positioned(
                top: 80,
                left: 16,
                child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPaused ? Colors.orange : Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: (_isPaused ? Colors.orange : Colors.green)
                                  .withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPaused ? 'PAUSADO' : 'CORRIENDO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Barra de control
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón Centrar
                    _ControlButton(
                      icon: Icons.my_location,
                      label: 'Centrar',
                      onTap: () => _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(_currentLocation, 17)),
                      isPrimary: false,
                    ),
                    const SizedBox(width: 12),
                    // Botón Principal (Iniciar/Detener)
                    _ControlButton(
                      icon: _isRunning
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      label: _isRunning ? 'Detener' : 'Iniciar',
                      onTap: _toggleRun,
                      isPrimary: true,
                      color: _isRunning ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    // Botón Pausa
                    if (_isRunning)
                      IconButton(
                        icon: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                        ),
                        onPressed: _pauseRun,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget mejorado para botones de control
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPrimary ? 48 : 44,
            height: isPrimary ? 48 : 44,
            decoration: BoxDecoration(
              color: isPrimary
                  ? effectiveColor
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(isPrimary ? 24 : 14),
              border: isPrimary
                  ? null
                  : Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.black.withValues(alpha: 0.8),
              size: isPrimary ? 24 : 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              color: Colors.black,
              shadows: const [
                Shadow(
                  color: Colors.white,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
