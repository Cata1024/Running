import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/design_system/territory_tokens.dart';
import '../../../core/map_icons.dart';
import '../../../core/widgets/aero_surface.dart';
import '../../../core/services/route_processor.dart';
import '../../../domain/services/circuit_closure_validator.dart';
import '../../../domain/services/territory_service.dart';
import '../../../domain/track_processing/track_processing.dart';
import '../../providers/app_providers.dart';
import '../../providers/achievements_provider.dart';
import '../../utils/map_style_utils.dart';
import '../../widgets/level_up_notification.dart';
import '../../../domain/entities/run.dart' as models;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/services/level_service.dart';
import 'widgets/run_calculations.dart';

class RunScreen extends ConsumerStatefulWidget {
  // ✅ Callback para notificar cambios de estado sin usar provider
  final void Function(bool isRunning, bool isPaused)? onRunStateChanged;
  
  const RunScreen({
    super.key,
    this.onRunStateChanged,
  });

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

enum _GpsStatus { initial, strong, medium, weak }

class _RunScreenState extends ConsumerState<RunScreen> {
  // Tracking variables
  StreamSubscription<Position>? _positionStream;

  // Estado del tracking
  bool _isRunning = false;
  bool _isPaused = false;
  List<LatLng> _routePoints = []; // Raw GPS points
  List<LatLng> _smoothedRoute = []; // Processed smooth route
  List<TrackPoint> _rawTrack = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;
  bool _isHudCollapsed = false;
  _GpsStatus _gpsStatus = _GpsStatus.initial;
  double? _lastAccuracy;
  bool _followUser = true;
  
  // 🌊 ROUTE PROCESSOR - Filtrado GPS + Suavizado profesional
  final RouteProcessor _routeProcessor = RouteProcessor();

  final List<String> _terrainOptions = const [
    'urbano',
    'trail',
    'mixto',
    'pista',
  ];

  final List<String> _moodOptions = const [
    'motivado',
    'relajado',
    'enfocado',
    'competitivo',
    'cansado',
  ];

  // Stats
  Duration _elapsedTime = Duration.zero;
  double _totalDistance = 0.0;
  DateTime? _startedAt;

  // Ubicación inicial
  LatLng _currentLocation = const LatLng(4.6097, -74.0817);
  Timer? _timer;
  MapIconsBundle? _iconBundle;
  
  // Flag para prevenir guardado múltiple
  bool _isSaving = false;

  void _toggleHud() {
    setState(() {
      _isHudCollapsed = !_isHudCollapsed;
    });
  }

  String _formattedPace() {
    final paceSecPerKm = RunCalculations.calculatePaceSecPerKm(_totalDistance, _elapsedTime);
    return RunCalculations.formatPace(paceSecPerKm);
  }

  String _formattedSpeed() {
    final speedKmh = RunCalculations.calculateSpeedKmh(_totalDistance, _elapsedTime);
    return RunCalculations.formatSpeed(speedKmh);
  }

  _GpsStatus _deriveGpsStatus(double? accuracy) {
    if (accuracy == null) return _GpsStatus.initial;
    if (accuracy <= 10) return _GpsStatus.strong;
    if (accuracy <= 25) return _GpsStatus.medium;
    return _GpsStatus.weak;
  }

  /// Helper para notificar cambios de estado
  /// Usa callback directo en lugar de provider (más seguro)
  void _notifyRunStateChanged() {
    // ✅ Notificar via callback (sin provider)
    widget.onRunStateChanged?.call(_isRunning, _isPaused);
  }

  /// 🔬 Procesar ruta en background con filtro Kalman + suavizado
  /// Se ejecuta cada 10 puntos GPS para mantener visualización suave
  Future<void> _processRouteInBackground() async {
    if (_routePoints.length < 20) return;

    try {
      // Usar config suave para visualización en tiempo real
      final result = await _routeProcessor.processRoute(
        rawPoints: _routePoints,
        config: const RouteProcessingConfig.smooth(),
      );

      if (mounted) {
        setState(() {
          _smoothedRoute = result.smoothedPoints;
          // Rebuild polylines con ruta suavizada
          _polylines = _buildPolylines(Theme.of(context));
        });
      }
    } catch (e) {
      // Si hay error, continuar con ruta cruda
      debugPrint('Error procesando ruta: $e');
    }
  }

  Color _gpsStatusColor(ThemeData theme) {
    switch (_gpsStatus) {
      case _GpsStatus.strong:
        return theme.colorScheme.primary;
      case _GpsStatus.medium:
        return theme.colorScheme.tertiary;
      case _GpsStatus.weak:
        return theme.colorScheme.error;
      case _GpsStatus.initial:
        return theme.colorScheme.outlineVariant;
    }
  }

  String _gpsStatusLabel() {
    switch (_gpsStatus) {
      case _GpsStatus.strong:
        return 'GPS fuerte';
      case _GpsStatus.medium:
        return 'GPS medio';
      case _GpsStatus.weak:
        return 'GPS débil';
      case _GpsStatus.initial:
        return 'GPS iniciando';
    }
  }

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
    // 🌊 USAR RUTA SUAVIZADA si está disponible (calidad Strava/Nike RC)
    final displayPoints = _smoothedRoute.isNotEmpty ? _smoothedRoute : _routePoints;
    
    if (displayPoints.length < 2) return const <Polyline>{};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: displayPoints,
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
    
    // ✅ Obtener ubicación y cargar iconos DESPUÉS del build inicial
    // Delay adicional para evitar conflictos con provider
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _getCurrentLocation();
        ref.read(mapIconsProvider.future).then((bundle) {
          if (!mounted) return;
          setState(() {
            _iconBundle = bundle;
            _markers = _buildMarkers(bundle);
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ubicación desactivada'),
            content: const Text('Activa el servicio de ubicación para continuar.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Abrir ajustes'),
              ),
            ],
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (permission == LocationPermission.deniedForever && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permiso requerido'),
              content: const Text('Otorga permisos de ubicación en Ajustes para usar el mapa.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
                FilledButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Abrir ajustes'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _lastAccuracy = position.accuracy.isFinite ? position.accuracy : null;
        _gpsStatus = _deriveGpsStatus(_lastAccuracy);
        _markers = _buildMarkers();
      });

      if (_followUser) {
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 17));
      }
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
      final sample = TrackPoint(
        lat: position.latitude,
        lon: position.longitude,
        ele: position.altitude.isFinite ? position.altitude : null,
        timestamp: DateTime.now(),
        hdop: position.accuracy.isFinite ? position.accuracy : null,
      );

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
        _rawTrack.add(sample);
        _lastAccuracy = position.accuracy.isFinite ? position.accuracy : null;
        _gpsStatus = _deriveGpsStatus(_lastAccuracy);
        _markers = _buildMarkers();
        _polylines = _buildPolylines(theme);
      });

      // 🌊 PROCESAR RUTA cada 10 puntos para suavizado en tiempo real
      if (_routePoints.length % 10 == 0 && _routePoints.length >= 20) {
        _processRouteInBackground();
      }

      if (_followUser) {
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 17));
      }
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

  void _toggleRun() {
    // ✅ NO USAR async/await en el handler directo del botón
    // Programar después del frame actual para evitar "during build"
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      if (_isRunning) {
        // DETENER carrera
        _positionStream?.cancel();
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isPaused = false;
          _markers = _buildMarkers();
        });
        
        // Notificar cambio de estado
        _notifyRunStateChanged();

        // Esperar un frame adicional para que el callback de navegación termine
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        try {
          final conditions = await _promptRunConditions();
          await _saveRunToBackend(conditions: conditions);
          if (!mounted) return;
          if (conditions != null) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Carrera guardada exitosamente')),
            );
          }
        } catch (e) {
          debugPrint('Error finalizando la carrera: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo guardar la carrera: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        // INICIAR carrera
        setState(() {
          _isRunning = true;
          _isPaused = false;
          _elapsedTime = Duration.zero;
          _totalDistance = 0.0;
          _routePoints = [];
          _smoothedRoute = [];
          _rawTrack = [];
          _markers = _buildMarkers();
          _polylines = {};
          _startedAt = DateTime.now();
        });
        
        // Notificar cambio de estado
        _notifyRunStateChanged();
        
        _startTracking();
      }
    });
  }

  void _pauseRun() {
    // ✅ Programar después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isRunning) return;
      
      setState(() {
        _isPaused = !_isPaused;
        _markers = _buildMarkers();
      });
      
      // Notificar cambio de estado
      _notifyRunStateChanged();
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  List<Map<String, dynamic>> _trackPointsToJsonList(List<TrackPoint> points) {
    return points
        .map((p) => {
              'lat': p.lat,
              'lon': p.lon,
              if (p.ele != null) 'ele': p.ele,
              'timestamp': p.timestamp.toIso8601String(),
              if (p.hdop != null) 'hdop': p.hdop,
              if (p.hr != null) 'hr': p.hr,
            })
        .toList();
  }

  String _buildRawGpx(List<TrackPoint> points) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
          '<gpx version="1.1" creator="TerritoryRun" xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <trk>');
    final name =
        _startedAt?.toIso8601String() ?? DateTime.now().toIso8601String();
    buffer
      ..writeln('    <name>$name</name>')
      ..writeln('    <trkseg>');
    for (final point in points) {
      buffer.writeln(
          '      <trkpt lat="${point.lat}" lon="${point.lon}">${point.ele != null ? '<ele>${point.ele}</ele>' : ''}<time>${point.timestamp.toUtc().toIso8601String()}</time></trkpt>');
    }
    buffer
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');
    return buffer.toString();
  }

  Future<Map<String, dynamic>> _uploadTrackArtifacts(
    String uid,
    TrackProcessingResult processing,
  ) async {
    if (_rawTrack.isEmpty) {
      return const {
        'rawTrackPath': null,
        'rawTrackUrl': null,
        'detailedTrackPath': null,
        'detailedTrackUrl': null,
      };
    }

    final storage = ref.read(storageServiceProvider);
    final timestampKey = _startedAt?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final basePath = 'runs/$uid/$timestampKey';
    final info = <String, dynamic>{
      'rawTrackPath': null,
      'rawTrackUrl': null,
      'detailedTrackPath': null,
      'detailedTrackUrl': null,
      'samples': {
        'raw': _rawTrack.length,
        'smoothed': processing.smoothedTrack.length,
        'resampled': processing.resampledTrack.length,
        'simplified': processing.simplifiedTrack.length,
      },
    };

    try {
      final gpx = _buildRawGpx(_rawTrack);
      final rawPath = '$basePath/raw.gpx';
      final rawBytes = Uint8List.fromList(utf8.encode(gpx));
      final rawUrl = await storage.uploadBytes(
        path: rawPath,
        data: rawBytes,
        contentType: 'application/gpx+xml',
      );
      info['rawTrackPath'] = rawPath;
      info['rawTrackUrl'] = rawUrl;
    } catch (e) {
      debugPrint('Error uploading raw GPX: $e');
    }

    try {
      final detailedPayload = {
        'generatedAt': DateTime.now().toIso8601String(),
        'simplification': processing.simplificationMetadata,
        'smoothedTrack': _trackPointsToJsonList(processing.smoothedTrack),
        'resampledTrack': _trackPointsToJsonList(processing.resampledTrack),
        'simplifiedTrack': _trackPointsToJsonList(processing.simplifiedTrack),
      };
      final detailedPath = '$basePath/detailed.json';
      final detailedBytes =
          Uint8List.fromList(utf8.encode(jsonEncode(detailedPayload)));
      final detailedUrl = await storage.uploadBytes(
        path: detailedPath,
        data: detailedBytes,
        contentType: 'application/json',
      );
      info['detailedTrackPath'] = detailedPath;
      info['detailedTrackUrl'] = detailedUrl;
    } catch (e) {
      debugPrint('Error uploading detailed track JSON: $e');
    }

    return info;
  }

  Future<Map<String, dynamic>?> _promptRunConditions() async {
    if (!mounted) return null;

    String? selectedTerrain = _terrainOptions.first;
    String? selectedMood = _moodOptions.first;

    Map<String, dynamic>? result;
    try {
      result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalles de la carrera',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El clima se obtendrá automáticamente de tu ubicación',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTerrain,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de terreno',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.terrain),
                      ),
                      items: _terrainOptions
                          .map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedTerrain = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMood,
                      decoration: const InputDecoration(
                        labelText: '¿Cómo te sentiste?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sentiment_satisfied_alt),
                      ),
                      items: _moodOptions
                          .map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedMood = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'terrain': selectedTerrain,
                            'mood': selectedMood,
                          });
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Guardar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Omitir'),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing details modal: $e');
      return null;
    }

    return result;
  }

  Future<void> _saveRunToBackend({Map<String, dynamic>? conditions}) async {
    // Prevenir ejecuciones múltiples (race condition)
    if (_isSaving) return;
    _isSaving = true;
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      if (_startedAt == null) return;
      final endedAt = DateTime.now();

      // 🌊 PROCESAR RUTA FINAL con config de almacenamiento (máxima compresión)
      final finalResult = await _routeProcessor.processRoute(
        rawPoints: _routePoints,
        config: const RouteProcessingConfig.storage(),
      );

      // Legacy processing para compatibilidad con backend
      final processing = await processTrackPipeline(_rawTrack);
      final processedTrack = processing.simplifiedTrack.isNotEmpty
          ? processing.simplifiedTrack
          : _rawTrack;

      if (mounted && finalResult.smoothedPoints.isNotEmpty) {
        final theme = Theme.of(context);
        setState(() {
          // Usar ruta suavizada para visualización final
          _smoothedRoute = finalResult.smoothedPoints;
          _routePoints = finalResult.simplifiedPoints;
          _currentLocation = _routePoints.last;
          _markers = _buildMarkers();
          _polylines = _buildPolylines(theme);
        });
      }

      final isClosed = const CircuitClosureValidator().isClosedCircuit(
        routePoints: processedTrack,
        duration: _elapsedTime,
      );

      Map<String, dynamic>? polygonGeoJson;
      double? areaGainedM2;
      Map<String, dynamic>? updatedTerritory;
      final territoryService = const TerritoryService();
      if (isClosed && processedTrack.length >= 3) {
        polygonGeoJson = territoryService.buildPolygonFromTrack(processedTrack);
        areaGainedM2 = territoryService.polygonAreaM2(polygonGeoJson);
        final existingTerritory =
            await ref.read(userTerritoryDocProvider.future);
        updatedTerritory = territoryService.mergeTerritory(
          existing: existingTerritory,
          newPolygon: polygonGeoJson,
          areaGainedM2: areaGainedM2,
        );
      }

      final distanceMeters = processing.distanceMeters > 0
          ? processing.distanceMeters
          : (_totalDistance * 1000);
      final movingTimeSeconds = processing.movingTimeSeconds > 0
          ? processing.movingTimeSeconds
          : _elapsedTime.inSeconds;
      final distanceKm = distanceMeters / 1000;

      final routeGeoJson =
          territoryService.buildLineStringFromTrack(processedTrack);
      final storageInfo = await _uploadTrackArtifacts(uid, processing);
      
      // Condiciones de la carrera (terrain y mood del usuario)
      // El clima se obtendrá automáticamente en el backend usando la ubicación
      final runConditions = conditions != null
          ? {
              'terrain': conditions['terrain'],
              'mood': conditions['mood'],
            }
          : {
              'terrain': null,
              'mood': null,
            };

      final runData = {
        'userId': uid,
        'startedAt': _startedAt!.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'distanceM': distanceMeters.round(),
        'durationS': movingTimeSeconds,
        'avgPaceSecPerKm':
            distanceKm > 0 ? (movingTimeSeconds / distanceKm) : null,
        'isClosedCircuit': isClosed,
        'startLat': processedTrack.isNotEmpty
            ? processedTrack.first.lat
            : _currentLocation.latitude,
        'startLon': processedTrack.isNotEmpty
            ? processedTrack.first.lon
            : _currentLocation.longitude,
        'endLat': processedTrack.isNotEmpty
            ? processedTrack.last.lat
            : _currentLocation.latitude,
        'endLon': processedTrack.isNotEmpty
            ? processedTrack.last.lon
            : _currentLocation.longitude,
        'routeGeoJson': routeGeoJson,
        'summaryPolyline': processing.summaryPolyline,
        // 📦 NUEVO: Polyline encoding profesional (compresión -94%)
        'polyline': finalResult.encodedPolyline,
        'processingStats': {
          'originalPoints': finalResult.stats.originalPoints,
          'processedPoints': finalResult.stats.processedPoints,
          'reductionRate': finalResult.stats.reductionRate,
        },
        'simplification': processing.simplificationMetadata,
        'metrics': {
          'distanceKm': distanceKm,
          'movingTimeS': movingTimeSeconds,
          'avgSpeedKmh': movingTimeSeconds > 0
              ? (distanceMeters / movingTimeSeconds) * 3.6
              : null,
          'paceSecPerKm':
              distanceKm > 0 ? (movingTimeSeconds / distanceKm) : null,
        },
        'conditions': runConditions,
        'storage': storageInfo,
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

      final totalsUpdate = <String, dynamic>{
        'totalRuns': currentTotalRuns + 1,
        'totalDistance': currentTotalDistance + distanceKm,
        'totalTime': currentTotalTime + movingTimeSeconds,
        'lastActivityAt': endedAt.toIso8601String(),
      };

      if (profile == null || profile.isEmpty) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final upsertPayload = <String, dynamic>{
          'email': firebaseUser?.email,
          'displayName': firebaseUser?.displayName,
          'photoUrl': firebaseUser?.photoURL,
          'preferredUnits': 'metric',
          'level': 1,
          'experience': 0,
          'achievements': const <String>[],
          'createdAt': _startedAt!.toIso8601String(),
          ...totalsUpdate,
        };
        upsertPayload.removeWhere((key, value) => value == null);
        await api.upsertUserProfile(uid, upsertPayload);
      } else {
        await api.patchUserProfile(uid, totalsUpdate);
      }

      ref.invalidate(userRunsProvider);
      ref.invalidate(runDocProvider(runId));
      ref.invalidate(userProfileDocProvider);
      ref.invalidate(userTerritoryDocProvider);

      // 🏆 Procesar logros y XP tras guardar
      try {
        final achievementsService = ref.read(achievementsServiceProvider);
        await achievementsService.initialize();

        final runModel = models.Run(
          id: runId,
          startTime: _startedAt!,
          durationSeconds: movingTimeSeconds,
          distanceMeters: distanceMeters,
          avgSpeedKmh: movingTimeSeconds > 0
              ? (distanceMeters / movingTimeSeconds) * 3.6
              : 0,
          territoryCovered: (areaGainedM2 ?? 0) > 0 ? 1 : 0, // aproximado
          isClosed: isClosed,
        );

        final unlocked = await achievementsService.processRunForAchievements(runModel);
        if (unlocked.isNotEmpty) {
          // Mostrar notificaciones por cada logro
          final notifier = ref.read(achievementNotificationProvider.notifier);
          for (final a in unlocked) {
            notifier.showAchievement(a);
          }

          // Sumar XP y mostrar overlay de Level Up si aplica
          final totalXp = unlocked.fold<int>(0, (sum, a) => sum + a.xpReward);
          if (totalXp > 0) {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null && mounted) {
              final prefs = await SharedPreferences.getInstance();
              final levelService = LevelService(prefs: prefs);
              final levelUp = await levelService.addXP(uid, totalXp);
              if (levelUp != null && mounted) {
                LevelUpOverlayManager.show(context, levelUp);
                await levelService.recordLevelMilestone(uid, levelUp);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Achievements processing error: $e');
      }
    } catch (e) {
      debugPrint('Error guardando run: $e');
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final territoryAsync = ref.watch(userTerritoryDocProvider);
    final mapType = ref.watch(mapTypeProvider);
    final mapStyle = ref.watch(mapStyleProvider);
    final styleString = resolveMapStyle(mapStyle, theme.brightness);
    // ✅ USAR ESTADO LOCAL en lugar de observar provider (evita dependencia circular)
    final mediaPadding = MediaQuery.of(context).padding;
    final bool navVisible = !(_isRunning && !_isPaused);
    final navBarHeight = ref.watch(navBarHeightProvider);
    final double navClearance = navVisible
        ? math.max(navBarHeight - TerritoryTokens.space20, 0)
        : 0;
    final double bottomOffset = navVisible
        ? mediaPadding.bottom + navClearance + TerritoryTokens.space8
        : mediaPadding.bottom + TerritoryTokens.space12;
    final double topOffset = mediaPadding.top + TerritoryTokens.space16;
    final Set<Polygon> territoryPolygons = territoryAsync.maybeWhen(
      data: (doc) => _parseTerritoryPolygons(doc, theme),
      orElse: () => <Polygon>{},
    );

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
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
              onCameraMoveStarted: () {
                if (!mounted) return;
                setState(() {
                  _followUser = false;
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          Positioned(
            top: topOffset,
            left: TerritoryTokens.space16,
            right: TerritoryTokens.space16,
            child: _RunHud(
              elapsedLabel: _formatTime(_elapsedTime),
              distanceLabel: _totalDistance.toStringAsFixed(2),
              paceLabel: _formattedPace(),
              speedLabel: _formattedSpeed(),
              gpsLabel: _gpsStatusLabel(),
              gpsColor: _gpsStatusColor(theme),
              accuracy: _lastAccuracy,
              isCollapsed: _isHudCollapsed,
              isRunning: _isRunning,
              isPaused: _isPaused,
              onToggle: _toggleHud,
            ),
          ),
          Positioned(
            left: TerritoryTokens.space16,
            right: TerritoryTokens.space16,
            bottom: bottomOffset,
            child: _ControlPanel(
              isRunning: _isRunning,
              isPaused: _isPaused,
              onCenter: () {
                if (!mounted) return;
                setState(() {
                  _followUser = true;
                });
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation, 17),
                );
              },
              onToggleRun: _toggleRun,
              onTogglePause: _isRunning ? _pauseRun : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunHud extends StatelessWidget {
  final String elapsedLabel;
  final String distanceLabel;
  final String paceLabel;
  final String speedLabel;
  final String gpsLabel;
  final Color gpsColor;
  final double? accuracy;
  final bool isCollapsed;
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onToggle;

  const _RunHud({
    required this.elapsedLabel,
    required this.distanceLabel,
    required this.paceLabel,
    required this.speedLabel,
    required this.gpsLabel,
    required this.gpsColor,
    required this.accuracy,
    required this.isCollapsed,
    required this.isRunning,
    required this.isPaused,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: TerritoryTokens.durationFast,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        ),
        child: isCollapsed
            ? _CollapsedHud(
                gpsLabel: gpsLabel,
                gpsColor: gpsColor,
                isRunning: isRunning,
                isPaused: isPaused,
              )
            : _ExpandedHud(
                elapsedLabel: elapsedLabel,
                distanceLabel: distanceLabel,
                paceLabel: paceLabel,
                speedLabel: speedLabel,
                gpsLabel: gpsLabel,
                gpsColor: gpsColor,
                accuracy: accuracy,
              ),
      ),
    );
  }
}

class _ExpandedHud extends StatelessWidget {
  final String elapsedLabel;
  final String distanceLabel;
  final String paceLabel;
  final String speedLabel;
  final String gpsLabel;
  final Color gpsColor;
  final double? accuracy;

  const _ExpandedHud({
    required this.elapsedLabel,
    required this.distanceLabel,
    required this.paceLabel,
    required this.speedLabel,
    required this.gpsLabel,
    required this.gpsColor,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
    );

    return AeroSurface(
      level: AeroLevel.medium,
      borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
      padding: const EdgeInsets.symmetric(
        horizontal: TerritoryTokens.space16,
        vertical: TerritoryTokens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Tiempo',
                  value: elapsedLabel,
                  textStyle: textStyle,
                ),
              ),
              const SizedBox(width: TerritoryTokens.space12),
              Expanded(
                child: _StatChip(
                  label: 'Distancia',
                  value: '$distanceLabel km',
                  textStyle: textStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: TerritoryTokens.space12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Ritmo',
                  value: '$paceLabel min/km',
                  textStyle: textStyle,
                ),
              ),
              const SizedBox(width: TerritoryTokens.space12),
              Expanded(
                child: _StatChip(
                  label: 'Velocidad',
                  value: '$speedLabel km/h',
                  textStyle: textStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: TerritoryTokens.space12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gpsColor,
                  boxShadow: TerritoryTokens.shadowSubtle(gpsColor),
                ),
              ),
              const SizedBox(width: TerritoryTokens.space8),
              Expanded(
                child: Text(
                  accuracy != null
                      ? '$gpsLabel · ±${accuracy!.toStringAsFixed(1)}m'
                      : gpsLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Icon(
                Icons.expand_less,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollapsedHud extends StatelessWidget {
  final String gpsLabel;
  final Color gpsColor;
  final bool isRunning;
  final bool isPaused;

  const _CollapsedHud({
    required this.gpsLabel,
    required this.gpsColor,
    required this.isRunning,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isPaused
        ? theme.colorScheme.tertiary
        : isRunning
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant;
    final statusLabel = isPaused
        ? 'Pausado'
        : isRunning
            ? 'Corriendo'
            : 'Listo';

    return AeroSurface(
      level: AeroLevel.subtle,
      borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
      padding: const EdgeInsets.symmetric(
        horizontal: TerritoryTokens.space16,
        vertical: TerritoryTokens.space12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights,
            color: statusColor,
          ),
          const SizedBox(width: TerritoryTokens.space12),
          Expanded(
            child: Text(
              statusLabel,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gpsColor,
              boxShadow: TerritoryTokens.shadowSubtle(gpsColor),
            ),
          ),
          const SizedBox(width: TerritoryTokens.space8),
          Text(
            gpsLabel,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: TerritoryTokens.space8),
          Icon(
            Icons.expand_more,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? textStyle;

  const _StatChip({
    required this.label,
    required this.value,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onCenter;
  final VoidCallback onToggleRun;
  final VoidCallback? onTogglePause;

  const _ControlPanel({
    required this.isRunning,
    required this.isPaused,
    required this.onCenter,
    required this.onToggleRun,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const buttonSpacing = TerritoryTokens.space12;

    final buttons = <Widget>[
      Expanded(
        child: _PrimaryControlButton(
          icon: Icons.my_location,
          label: '',
          onTap: onCenter,
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          foregroundColor: theme.colorScheme.onSurface,
        ),
      ),
      const SizedBox(width: buttonSpacing),
      Expanded(
        flex: 2,
        child: _PrimaryControlButton(
          icon: isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
          label: isRunning ? 'Detener' : 'Iniciar carrera',
          onTap: onToggleRun,
          backgroundColor:
              isRunning ? theme.colorScheme.error : theme.colorScheme.primary,
          foregroundColor: isRunning
              ? theme.colorScheme.onError
              : theme.colorScheme.onPrimary,
        ),
      ),
    ];

    if (isRunning) {
      buttons
        ..add(const SizedBox(width: buttonSpacing))
        ..add(
          Expanded(
            child: _PrimaryControlButton(
              icon: isPaused ? Icons.play_arrow : Icons.pause,
              label: isPaused ? '' : '',
              onTap: onTogglePause,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              foregroundColor: theme.colorScheme.onTertiaryContainer,
            ),
          ),
        );
    }

    return AeroSurface(
      level: AeroLevel.medium,
      borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
      padding: const EdgeInsets.symmetric(
        horizontal: TerritoryTokens.space16,
        vertical: TerritoryTokens.space12,
      ),
      child: Row(children: buttons),
    );
  }
}

class _PrimaryControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;

  const _PrimaryControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    final hasLabel = label.trim().isNotEmpty;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: SizedBox(
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
              ),
              boxShadow: TerritoryTokens.shadowSubtle(
                theme.colorScheme.shadow,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, color: foregroundColor),
                if (hasLabel) ...[
                  const SizedBox(width: TerritoryTokens.space12),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
