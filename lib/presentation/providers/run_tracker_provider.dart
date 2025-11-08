import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/route_processor.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/run.dart' as models;
import '../../domain/entities/territory.dart';
import '../../domain/services/circuit_closure_validator.dart';
import '../../domain/services/territory_service.dart';
import '../../domain/track_processing/track_processing.dart';
import '../../domain/entities/storage_resource.dart';
import '../../core/services/audit_logger.dart';
import '../../data/services/api_service.dart';
import 'achievements_provider.dart';
import 'app_providers.dart';
import 'territory_provider.dart';

part 'run_tracker_provider.g.dart';

enum GpsStatus { initial, strong, medium, weak }

typedef RunSaveResult = ({bool success, String? message});

class RunState {
  final bool isRunning;
  final bool isPaused;
  final Duration elapsedTime;
  final double totalDistance;
  final List<LatLng> routePoints;
  final List<LatLng> smoothedRoute;
  final List<TrackPoint> rawTrack;
  final GpsStatus gpsStatus;
  final double? lastAccuracy;
  final DateTime? startedAt;
  final LatLng? currentLocation;
  final bool followUser;
  final bool isHudCollapsed;

  const RunState({
    this.isRunning = false,
    this.isPaused = false,
    this.elapsedTime = Duration.zero,
    this.totalDistance = 0.0,
    this.routePoints = const [],
    this.smoothedRoute = const [],
    this.rawTrack = const [],
    this.gpsStatus = GpsStatus.initial,
    this.lastAccuracy,
    this.startedAt,
    this.currentLocation,
    this.followUser = true,
    this.isHudCollapsed = false,
  });

  RunState copyWith({
    bool? isRunning,
    bool? isPaused,
    Duration? elapsedTime,
    double? totalDistance,
    List<LatLng>? routePoints,
    List<LatLng>? smoothedRoute,
    List<TrackPoint>? rawTrack,
    GpsStatus? gpsStatus,
    double? lastAccuracy,
    DateTime? startedAt,
    LatLng? currentLocation,
    bool? followUser,
    bool? isHudCollapsed,
  }) {
    return RunState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      totalDistance: totalDistance ?? this.totalDistance,
      routePoints: routePoints ?? this.routePoints,
      smoothedRoute: smoothedRoute ?? this.smoothedRoute,
      rawTrack: rawTrack ?? this.rawTrack,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      lastAccuracy: lastAccuracy ?? this.lastAccuracy,
      startedAt: startedAt ?? this.startedAt,
      currentLocation: currentLocation ?? this.currentLocation,
      followUser: followUser ?? this.followUser,
      isHudCollapsed: isHudCollapsed ?? this.isHudCollapsed,
    );
  }
}

@riverpod
class RunTracker extends _$RunTracker {
  // Para leer la configuración del usuario
  late final AppSettings _settings;

  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  @override
  RunState build() {
    _settings = ref.watch(settingsProvider);

    ref.onDispose(() {
      _positionStream?.cancel();
      _timer?.cancel();
    });
    return const RunState();
  }

  void _startGpsTracking() {
    if (_positionStream != null) {
      _positionStream!.cancel();
    }

    final LocationAccuracy accuracy;
    switch (_settings.gpsAccuracy) {
      case 'low':
        accuracy = LocationAccuracy.low;
        break;
      case 'balanced':
        accuracy = LocationAccuracy.medium;
        break;
      case 'high':
      default:
        accuracy = LocationAccuracy.high;
        break;
    }

    final LocationSettings locationSettings =
        (defaultTargetPlatform == TargetPlatform.android)
            ? AndroidSettings(
                accuracy: accuracy,
                distanceFilter: (_settings.gpsIntervalMs / 100.0).round(),
                intervalDuration:
                    Duration(milliseconds: _settings.gpsIntervalMs),
                foregroundNotificationConfig: const ForegroundNotificationConfig(
                  notificationTitle: 'Territory Run',
                  notificationText: 'Seguimiento de ubicación activo',
                  notificationChannelName: 'Seguimiento de Carrera',
                ),
              )
            : LocationSettings(
                accuracy: accuracy,
                distanceFilter: (_settings.gpsIntervalMs / 100.0).round(),
              );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!state.isRunning || state.isPaused) return;

      addLocation(position);

      if (_settings.autoPauseEnabled && position.speed >= 0) {
        final speedMs = position.speed;
        if (speedMs < _settings.autoPauseThresholdMs && !state.isPaused) {
          togglePause();
        } else if (speedMs >= _settings.autoPauseThresholdMs && state.isPaused) {
          togglePause();
        }
      }
    });
  }

  void startRun() {
    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      elapsedTime: Duration.zero,
      totalDistance: 0.0,
      routePoints: [],
      smoothedRoute: [],
      rawTrack: [],
      startedAt: DateTime.now(),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRunning && !state.isPaused) {
        state = state.copyWith(
          elapsedTime: Duration(seconds: state.elapsedTime.inSeconds + 1),
        );
      }
    });
    // Iniciar el seguimiento GPS
    _startGpsTracking();
  }

  void togglePause() {
    if (!state.isRunning) return;
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();
    state = state.copyWith(isRunning: false, isPaused: false, followUser: true);
  }

  void addLocation(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    final newTrackPoint = TrackPoint(
      lat: position.latitude,
      lon: position.longitude,
      ele: position.altitude.isFinite ? position.altitude : null,
      timestamp: position.timestamp,
      hdop: position.accuracy.isFinite ? position.accuracy : null,
    );

    final newRoutePoints = List<LatLng>.from(state.routePoints)..add(newLocation);
    final newRawTrack = List<TrackPoint>.from(state.rawTrack)..add(newTrackPoint);

    double distanceDelta = 0;
    if (state.routePoints.isNotEmpty) {
      final lastPoint = state.routePoints.last;
      distanceDelta = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );
    }

    state = state.copyWith(
      currentLocation: newLocation,
      routePoints: newRoutePoints,
      rawTrack: newRawTrack,
      totalDistance: state.totalDistance + (distanceDelta / 1000), // a km
      lastAccuracy: position.accuracy.isFinite ? position.accuracy : null,
      gpsStatus: _deriveGpsStatus(position.accuracy),
    );
  }

  void toggleFollowUser(bool follow) {
    state = state.copyWith(followUser: follow);
  }

  void toggleHud() {
    state = state.copyWith(isHudCollapsed: !state.isHudCollapsed);
  }

  Future<RunSaveResult> stopAndSaveRun({Map<String, dynamic>? conditions}) async {
    // 1. Detener timers y streams
    stopRun();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || state.startedAt == null) {
      return (success: false, message: 'Sesión inválida. Inicia sesión nuevamente.');
    }

    final endedAt = DateTime.now();
    final routeProcessor = RouteProcessor();

    try {
      // 2. Procesar la ruta final con máxima compresión
      final finalResult = await routeProcessor.processRoute(
        rawPoints: state.routePoints,
        config: const RouteProcessingConfig.storage(),
      );

      // 3. Procesamiento legacy para compatibilidad
      final processing = await processTrackPipeline(state.rawTrack);
      final processedTrack = processing.simplifiedTrack.isNotEmpty
          ? processing.simplifiedTrack
          : state.rawTrack;

      // 4. Actualizar estado con la ruta final (opcional, la UI ya debería tenerla)
      state = state.copyWith(
        smoothedRoute: finalResult.smoothedPoints,
        routePoints: finalResult.simplifiedPoints,
      );

      // 5. Validar si es un circuito cerrado
      final isClosed = const CircuitClosureValidator().isClosedCircuit(
        routePoints: processedTrack,
        duration: state.elapsedTime,
      );

      // 6. Calcular y unir territorio si aplica
      Map<String, dynamic>? polygonGeoJson;
      double? areaGainedM2;
      Territory? updatedTerritory;
      final territoryService = const TerritoryService();
      if (isClosed && processedTrack.length >= 3) {
        polygonGeoJson = territoryService.buildPolygonFromTrack(processedTrack);
        areaGainedM2 = territoryService.polygonAreaM2(polygonGeoJson);
        final territoryUseCase = await ref.read(territoryUseCaseProvider.future);
        updatedTerritory = await territoryUseCase.mergeAndSaveFromPolygon(
          newPolygon: polygonGeoJson,
          areaGainedM2: areaGainedM2,
        );
      }

      // 7. Calcular estadísticas finales
      final distanceMeters = processing.distanceMeters > 0
          ? processing.distanceMeters
          : (state.totalDistance * 1000);
      final movingTimeSeconds = processing.movingTimeSeconds > 0
          ? processing.movingTimeSeconds
          : state.elapsedTime.inSeconds;
      final distanceKm = distanceMeters / 1000;
      final avgPaceSecPerKm =
          distanceKm > 0 ? (movingTimeSeconds / distanceKm) : null;

      // 8. Subir artefactos a Storage
      final routeGeoJson = territoryService.buildLineStringFromTrack(processedTrack);
      final storageInfo = await _uploadTrackArtifacts(uid, processing);

      // 9. Preparar el payload para la API
      final runData = {
        'userId': uid,
        'startedAt': state.startedAt!.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'distanceM': distanceMeters.round(),
        'durationS': movingTimeSeconds,
        'isClosedCircuit': isClosed,
        'startLat': processedTrack.isNotEmpty ? processedTrack.first.lat : state.currentLocation!.latitude,
        'startLon': processedTrack.isNotEmpty ? processedTrack.first.lon : state.currentLocation!.longitude,
        'endLat': processedTrack.isNotEmpty ? processedTrack.last.lat : state.currentLocation!.latitude,
        'endLon': processedTrack.isNotEmpty ? processedTrack.last.lon : state.currentLocation!.longitude,
        'routeGeoJson': routeGeoJson,
        'summaryPolyline': processing.summaryPolyline,
        'polyline': finalResult.encodedPolyline,
        'processingStats': {
          'originalPoints': finalResult.stats.originalPoints,
          'processedPoints': finalResult.stats.processedPoints,
          'reductionRate': finalResult.stats.reductionRate,
        },
        'simplification': processing.simplificationMetadata,
        'storage': storageInfo,
        'conditions': conditions ?? {'terrain': null, 'mood': null},
        'gainedAreaM2': areaGainedM2,
        'avgPace': avgPaceSecPerKm,
      };

      // 10. Enviar a la API
      final api = ref.read(apiServiceProvider);
      final runId = await api.createRun(runData);

      // 11. Actualizar territorio y perfil de usuario
      if (updatedTerritory != null) {
        ref.invalidate(territoryUseCaseProvider);
        ref.invalidate(userTerritoryProvider);
      }

      // 12. Invalidar caches
      ref.invalidate(userRunsDtoProvider);
      ref.invalidate(runDocDtoProvider(runId));
      ref.invalidate(userTerritoryProvider);

      // 13. Procesar logros
      try {
        final runModel = models.Run(
          id: runId,
          startTime: state.startedAt!,
          durationSeconds: movingTimeSeconds,
          distanceMeters: distanceMeters,
          avgSpeedKmh: movingTimeSeconds > 0 ? (distanceMeters / movingTimeSeconds) * 3.6 : 0,
          territoryCovered: (areaGainedM2 ?? 0) > 0 ? 1 : 0,
          isClosed: isClosed,
        );
        await processRunAchievements(ref, runModel);
      } catch (e) {
        debugPrint('Error procesando logros: $e');
      }

      // 14. Registrar auditoría del guardado de carrera
      final auditLogger = ref.read(auditLoggerProvider);
      await auditLogger.log('run.saved', {
        'runId': runId,
        'uid': uid,
        'distanceMeters': distanceMeters,
        'durationSeconds': movingTimeSeconds,
        'closedCircuit': isClosed,
        'gainedAreaM2': areaGainedM2,
      });

      return (success: true, message: null);
    } on ApiException catch (e) {
      debugPrint('Error API guardando carrera: ${e.message}');
      return (
        success: false,
        message: 'No se pudo guardar la carrera (código ${e.statusCode}). Intenta nuevamente.',
      );
    } catch (e, st) {
      debugPrint('Error guardando carrera: $e');
      debugPrintStack(stackTrace: st);
      return (
        success: false,
        message: 'No se pudo guardar la carrera. Verifica tu conexión e inténtalo de nuevo.',
      );
    }
  }

  String _buildRawGpx(List<TrackPoint> points) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="TerritoryRun" xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <trk>');
    final name = state.startedAt?.toIso8601String() ?? DateTime.now().toIso8601String();
    buffer
      ..writeln('    <name>$name</name>')
      ..writeln('    <trkseg>');
    for (final point in points) {
      buffer.writeln('      <trkpt lat="${point.lat}" lon="${point.lon}">${point.ele != null ? '<ele>${point.ele}</ele>' : ''}<time>${point.timestamp.toUtc().toIso8601String()}</time></trkpt>');
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
    if (state.rawTrack.isEmpty) {
      return const {
        'rawTrackPath': null,
        'rawTrackUrl': null,
        'detailedTrackPath': null,
        'detailedTrackUrl': null,
      };
    }

    final storage = ref.read(storageRepositoryProvider);
    final timestampKey = state.startedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    final basePath = 'runs/$uid/$timestampKey';
    final info = <String, dynamic>{
      'rawTrackPath': null,
      'rawTrackUrl': null,
      'detailedTrackPath': null,
      'detailedTrackUrl': null,
      'samples': {
        'raw': state.rawTrack.length,
        'smoothed': processing.smoothedTrack.length,
        'resampled': processing.resampledTrack.length,
        'simplified': processing.simplifiedTrack.length,
      },
    };

    try {
      final gpx = _buildRawGpx(state.rawTrack);
      final rawPath = '$basePath/raw.gpx';
      final rawBytes = Uint8List.fromList(utf8.encode(gpx));
      final rawResult = await storage.upload(
        StorageUploadRequest(
          path: rawPath,
          bytes: rawBytes,
          contentType: 'application/gpx+xml',
        ),
      );
      info['rawTrackPath'] = rawResult.path;
      info['rawTrackUrl'] = rawResult.downloadUrl;
    } catch (e) {
      debugPrint('Error uploading raw track GPX: $e');
    }

    try {
      final detailedJson = jsonEncode(processing.simplificationMetadata);
      final detailedPath = '$basePath/detailed.json';
      final detailedBytes = Uint8List.fromList(utf8.encode(detailedJson));
      final detailedResult = await storage.upload(
        StorageUploadRequest(
          path: detailedPath,
          bytes: detailedBytes,
          contentType: 'application/json',
        ),
      );
      info['detailedTrackPath'] = detailedResult.path;
      info['detailedTrackUrl'] = detailedResult.downloadUrl;
    } catch (e) {
      debugPrint('Error uploading detailed track JSON: $e');
    }

    return info;
  }

  Future<void> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      state = state.copyWith(
        currentLocation: newLocation,
        lastAccuracy: position.accuracy.isFinite ? position.accuracy : null,
        gpsStatus: _deriveGpsStatus(position.accuracy),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  GpsStatus _deriveGpsStatus(double? accuracy) {
    if (accuracy == null) return GpsStatus.initial;
    if (accuracy <= 10) return GpsStatus.strong;
    if (accuracy <= 25) return GpsStatus.medium;
    return GpsStatus.weak;
  }
}
