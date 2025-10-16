import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../core/widgets/glass_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/map_styles.dart';
import '../../../domain/services/circuit_closure_validator.dart';
import '../../../domain/services/territory_service.dart';
import '../../providers/app_providers.dart';

class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

Set<Polygon> _parseTerritoryPolygons(Map<String, dynamic>? doc, ThemeData theme) {
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
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
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
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  
  // Estado del tracking
  bool _isRunning = false;
  bool _isPaused = false;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Stats
  Duration _elapsedTime = Duration.zero;
  double _totalDistance = 0.0;
  DateTime? _startedAt;
  
  // Ubicación inicial
  LatLng _currentLocation = const LatLng(4.6097, -74.0817);
  Timer? _timer;
  

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation,
            infoWindow: const InfoWindow(title: 'Ubicación actual'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        };
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 17));
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

      setState(() {
        _currentLocation = newLocation;
        _routePoints.add(newLocation);
        
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: newLocation,
            infoWindow: const InfoWindow(title: 'Corriendo...'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        };

        if (_routePoints.length > 1) {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routePoints,
              color: Colors.blue,
              width: 4,
            ),
          };
        }
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 17));
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
      });
      await _saveRunToFirestore();
    } else {
      // Start run: resetear estado y comenzar tracking
      setState(() {
        _isRunning = true;
        _isPaused = false;
        _elapsedTime = Duration.zero;
        _totalDistance = 0.0;
        _routePoints = [];
        _startedAt = DateTime.now();
      });
      _startTracking();
    }
  }

  void _pauseRun() {
    if (_isRunning) {
      setState(() {
        _isPaused = !_isPaused;
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

  Future<void> _saveRunToFirestore() async {
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
      if (isClosed && _routePoints.length >= 3) {
        final territory = const TerritoryService();
        polygonGeoJson = territory.buildPolygonFromRoute(_routePoints);
        areaGainedM2 = territory.polygonAreaM2(polygonGeoJson);
        await territory.updateUserTerritory(
          uid: uid,
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
        'avgPaceSecPerKm': _totalDistance > 0 ? (_elapsedTime.inSeconds / _totalDistance) : null,
        'isClosedCircuit': isClosed,
        'startLat': _routePoints.isNotEmpty ? _routePoints.first.latitude : _currentLocation.latitude,
        'startLon': _routePoints.isNotEmpty ? _routePoints.first.longitude : _currentLocation.longitude,
        'endLat': _routePoints.isNotEmpty ? _routePoints.last.latitude : _currentLocation.latitude,
        'endLon': _routePoints.isNotEmpty ? _routePoints.last.longitude : _currentLocation.longitude,
        'routeGeoJson': {
          'type': 'LineString',
          'coordinates': coords,
        },
        if (polygonGeoJson != null) 'polygonGeoJson': polygonGeoJson,
        if (areaGainedM2 != null) 'areaGainedM2': areaGainedM2,
        'synced': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('runs').add(runData);

      // Actualizar agregados del perfil de usuario
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'totalRuns': FieldValue.increment(1),
        'totalDistance': FieldValue.increment(_totalDistance),
        'totalTime': FieldValue.increment(_elapsedTime.inSeconds),
        'lastActivityAt': endedAt.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando run: $e');
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final territoryAsync = ref.watch(userTerritoryDocProvider);
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
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (isDark) {
                    _mapController?.setMapStyle(MapStyles.dark);
                  } else {
                    _mapController?.setMapStyle(MapStyles.light);
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
            
            // Stats overlay en el mapa
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_elapsedTime),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tiempo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '${_totalDistance.toStringAsFixed(2)} km',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Distancia',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            _totalDistance > 0
                                ? (() {
                                    final paceSecPerKm = _elapsedTime.inSeconds / _totalDistance;
                                    final m = (paceSecPerKm / 60).floor();
                                    final s = (paceSecPerKm % 60).round().toString().padLeft(2, '0');
                                    return '$m:$s';
                                  }())
                                : '--:--',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Ritmo (min/km)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicador de estado
            if (_isRunning || _isPaused)
              Positioned(
                top: 80,
                left: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPaused ? Colors.orange : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPaused ? 'Pausado' : 'Corriendo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Barra de control compacta inferior
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SecondaryButton(
                      icon: Icons.center_focus_strong,
                      label: 'Centrar',
                      onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 17)),
                    ),
                    _SecondaryButton(
                      icon: _isRunning ? Icons.stop : Icons.play_arrow,
                      label: _isRunning ? 'Detener' : 'Iniciar',
                      onTap: _toggleRun,
                    ),
                    _SecondaryButton(
                      icon: _isPaused ? Icons.play_arrow : Icons.pause,
                      label: _isPaused ? 'Reanudar' : 'Pausar',
                      onTap: _pauseRun,
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

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
