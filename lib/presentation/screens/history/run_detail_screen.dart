import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';

import '../../providers/app_providers.dart';
import '../../utils/map_style_utils.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_surface.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/aero_button.dart';
import '../../../core/services/route_processor.dart';
import '../../../data/models/run_dto.dart';
import '../../../domain/entities/app_settings.dart';

class RunDetailScreen extends ConsumerStatefulWidget {
  final String runId;
  const RunDetailScreen({super.key, required this.runId});

  @override
  ConsumerState<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends ConsumerState<RunDetailScreen> {
  GoogleMapController? _mapController;
  final RouteProcessor _routeProcessor = RouteProcessor();
  RouteProcessingResult? _processedRoute;
  bool _isProcessingRoute = false;
  bool _isSharing = false;
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Procesar ruta con pipeline profesional
  Future<void> _processRoute(List<LatLng> rawPoints) async {
    if (rawPoints.isEmpty || _isProcessingRoute) return;

    setState(() => _isProcessingRoute = true);

    try {
      final result = await _routeProcessor.processRoute(
        rawPoints: rawPoints,
        config: const RouteProcessingConfig.smooth(), // Calidad visual máxima
      );

      if (mounted) {
        setState(() {
          _processedRoute = result;
          _isProcessingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingRoute = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRun = ref.watch(runDocDtoProvider(widget.runId));
    final theme = Theme.of(context);
    final mapType = ref.watch(mapTypeProvider);
    final stylePref = ref.watch(mapStyleProvider);
    final styleString = resolveMapStyle(stylePref, theme.brightness);
    final iconsAsync = ref.watch(mapIconsProvider);
    final navBarHeight = ref.watch(navBarHeightProvider);
    final navBarClearance = navBarHeight > TerritoryTokens.space12
        ? navBarHeight - TerritoryTokens.space12
        : navBarHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: asyncRun.when(
        loading: () => const LoadingState(message: 'Cargando detalles...'),
        error: (e, st) => ErrorState(
          message: 'No se pudo cargar la carrera',
          onRetry: () => ref.invalidate(runDocDtoProvider(widget.runId)),
        ),
        data: (run) {
          if (run == null) {
            return const Center(child: Text('Carrera no encontrada'));
          }

          var route = _parseLineString(run.routeGeoJson);
          if (_isRouteTooSimple(route) && (run.polyline?.isNotEmpty ?? false)) {
            route = _decodePolyline(run.polyline!);
          }
          final polygon = _parsePolygon(run.polygonGeoJson);
          final settings = ref.watch(settingsProvider);

          // 🎨 PROCESAR RUTA CON PIPELINE PROFESIONAL
          if (route.isNotEmpty && _processedRoute == null && !_isProcessingRoute) {
            // Procesar en el próximo frame para no bloquear UI
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _processRoute(route);
            });
          }

          final processedRoute = _processedRoute;
          List<LatLng> displayRoute = route;
          if (processedRoute != null) {
            final smoothed = processedRoute.smoothedPoints;
            final simplified = processedRoute.simplifiedPoints;
            if (smoothed.length >= 4) {
              displayRoute = smoothed;
            } else if (simplified.length >= 4) {
              displayRoute = simplified;
            }
          }

          final icons = iconsAsync.maybeWhen(
            data: (bundle) => bundle,
            orElse: () => null,
          );

          final markers = <Marker>{};
          if (route.isNotEmpty) {
            markers.add(
              Marker(
                markerId: const MarkerId('start'),
                position: route.first,
                infoWindow: const InfoWindow(title: 'Inicio de la carrera'),
                icon:
                    icons?.start ?? BitmapDescriptor.defaultMarkerWithHue(110),
              ),
            );
            markers.add(
              Marker(
                markerId: const MarkerId('end'),
                position: route.last,
                infoWindow: const InfoWindow(title: 'Fin de la carrera'),
                icon: icons?.finish ?? BitmapDescriptor.defaultMarkerWithHue(0),
              ),
            );
          }

          // 🌊 USAR RUTA SUAVIZADA (CALIDAD STRAVA/NIKE RC)
          final polylines = displayRoute.length > 1
              ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: displayRoute,
                    color: theme.colorScheme.primary,
                    width: 6,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                  ),
                }
              : const <Polyline>{};

          final polygons = polygon.isNotEmpty
              ? {
                  Polygon(
                    polygonId: const PolygonId('area'),
                    points: polygon,
                    strokeWidth: 3,
                    strokeColor: theme.colorScheme.secondary,
                    fillColor:
                        theme.colorScheme.secondary.withValues(alpha: 0.25),
                  ),
                }
              : <Polygon>{};

          final bounds = _computeBounds(route.isNotEmpty ? route : polygon);
          final initialTarget = bounds == null
              ? (route.isNotEmpty
                  ? route.first
                  : const LatLng(4.6097, -74.0817))
              : LatLng(
                  (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                  (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                );

          final distanceM = (run.distanceM).toDouble();
          final durationS = run.durationS;
          String fmt(int s) {
            final h = (s ~/ 3600).toString().padLeft(2, '0');
            final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
            final sec = (s % 60).toString().padLeft(2, '0');
            return '$h:$m:$sec';
          }

          final distanceKm = distanceM / 1000;
          final durationLabel = fmt(durationS);
          final paceLabel = _pace(distanceM, durationS);
          final speedLabel = _speed(distanceM, durationS);
          final areaM2 = (run.areaGainedM2);
          final areaKm2 = areaM2 != null ? areaM2 / 1000000 : null;
          final bool isClosedCircuit = run.isClosedCircuit == true;
          final weatherData = run.conditions?['weather'] as Map<String, dynamic>?;
          final weatherIcon = _getWeatherIcon(weatherData?['condition'] as String?);
          final startedAt = run.startedAt;
          final shareText =
              'Mi carrera del ${startedAt.year}-${startedAt.month.toString().padLeft(2, '0')}-${startedAt.day.toString().padLeft(2, '0')}: ${(distanceM / 1000).toStringAsFixed(2)} km en $durationLabel (ritmo $paceLabel min/km)';

          return Stack(
            children: [
              Offstage(
                offstage: true,
                child: RepaintBoundary(
                  key: _shareCardKey,
                  child: _ShareCard(
                    run: run,
                    route: displayRoute,
                    polygon: polygon,
                    settings: settings,
                    distanceKm: distanceKm,
                    durationLabel: durationLabel,
                    paceLabel: paceLabel,
                    speedLabel: speedLabel,
                    isClosedCircuit: isClosedCircuit,
                    areaKm2: areaKm2,
                    weatherData: weatherData,
                    weatherIcon: weatherIcon,
                    shareText: shareText,
                  ),
                ),
              ),
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: initialTarget, zoom: 14),
                markers: markers,
                polylines: polylines,
                polygons: polygons,
                mapType: mapType,
                style: styleString,
                onMapCreated: (ctrl) async {
                  _mapController = ctrl;
                  if (bounds != null) {
                    await Future.delayed(const Duration(milliseconds: 100));
                    await _mapController?.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, 50));
                  }
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                top: TerritoryTokens.space16,
                left: TerritoryTokens.space16,
                right: TerritoryTokens.space16,
                child: SafeArea(
                  bottom: false,
                  child: _TopHeaderRow(
                    onShare: _isSharing
                        ? null
                        : () => _shareRun(
                              run: run,
                              route: displayRoute,
                              polygon: polygon,
                              settings: settings,
                              shareText: shareText,
                            ),
                    isSharing: _isSharing,
                    onBack: () => Navigator.of(context).maybePop(),
                    meta: _buildHeader(run, theme),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  bottom: true,
                  minimum: const EdgeInsets.only(
                    left: TerritoryTokens.space16,
                    right: TerritoryTokens.space16,
                    bottom: TerritoryTokens.space12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatsCluster(
                        distanceKm: distanceKm,
                        durationLabel: durationLabel,
                        paceLabel: paceLabel,
                        speedLabel: speedLabel,
                        isClosedCircuit: isClosedCircuit,
                        areaKm2: areaKm2,
                        weatherData: weatherData,
                        weatherIcon: weatherIcon,
                      ),
                      const SizedBox(height: TerritoryTokens.space12),
                      SizedBox(height: navBarClearance),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildHeader(RunDto run, ThemeData theme) {
    final date = run.startedAt;
    final isClosedCircuit = run.isClosedCircuit == true;
    final highlightColor = theme.colorScheme.tertiary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatHeaderDate(date),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
        if (isClosedCircuit)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: highlightColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Circuito Cerrado',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: highlightColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _formatHeaderDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = (date.year).toString().padLeft(2, '0');
    final weekday = _getWeekday(date.weekday);
    final time = _getTimeOfDay(date);
    return "$weekday • $day $month $year • $time";
  }

  static String _getWeekday(int weekday) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  static String _getTimeOfDay(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _pace(double distanceM, int durationS) {
    if (distanceM <= 0 || durationS <= 0) return '--:--';
    final km = distanceM / 1000.0;
    final paceSec = durationS / km;
    final m = (paceSec / 60).floor();
    final s = (paceSec % 60).round().toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _speed(double distanceM, int durationS) {
    if (distanceM <= 0 || durationS <= 0) return '--';
    final metersPerSecond = distanceM / durationS;
    final kmh = metersPerSecond * 3.6;
    if (!kmh.isFinite) return '--';
    return kmh.toStringAsFixed(1);
  }

  static List<LatLng> _parseLineString(dynamic geojson) {
    // Si es un string, parsearlo primero
    if (geojson is String) {
      try {
        geojson = jsonDecode(geojson);
      } catch (e) {
        return const [];
      }
    }

    if (geojson is Map && geojson['type'] == 'LineString') {
      final coords = (geojson['coordinates'] as List?) ?? const [];
      return coords
          .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    }
    return const [];
  }

  bool _isRouteTooSimple(List<LatLng> route) => route.length < 4;

  List<LatLng> _decodePolyline(String encoded) {
    return _routeProcessor.decodePolyline(encoded);
  }

  static List<LatLng> _parsePolygon(dynamic geojson) {
    // Si es un string, parsearlo primero
    if (geojson is String) {
      try {
        geojson = jsonDecode(geojson);
      } catch (e) {
        return const [];
      }
    }

    if (geojson is Map && geojson['type'] == 'Polygon') {
      final rings = (geojson['coordinates'] as List?) ?? const [];
      if (rings.isEmpty) return const [];
      final outer = rings.first as List;
      return outer
          .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    }
    return const [];
  }

  IconData _getWeatherIcon(String? condition) {
    final desc = condition?.toLowerCase() ?? '';
    if (desc.contains('soleado') || desc.contains('despejado')) return Icons.wb_sunny_outlined;
    if (desc.contains('nubes') || desc.contains('nublado')) return Icons.cloud_outlined;
    if (desc.contains('lluvia') || desc.contains('llovizna')) return Icons.grain_outlined;
    if (desc.contains('tormenta')) return Icons.thunderstorm_outlined;
    if (desc.contains('nieve')) return Icons.ac_unit_outlined;
    if (desc.contains('niebla')) return Icons.foggy;
    return Icons.thermostat_outlined;
  }

  static LatLngBounds? _computeBounds(List<LatLng> pts) {
    if (pts.isEmpty) return null;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _shareRun({
    required RunDto run,
    required List<LatLng> route,
    required List<LatLng> polygon,
    required AppSettings settings,
    required String shareText,
  }) async {
    try {
      setState(() => _isSharing = true);
      await Future.delayed(const Duration(milliseconds: 50));
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('No se pudo generar la vista para compartir');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Captura inválida');
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/territory_run_${run.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: shareText,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo preparar la imagen para compartir: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}

class _TopHeaderRow extends StatelessWidget {
  final VoidCallback? onShare;
  final VoidCallback onBack;
  final Widget meta;
  final bool isSharing;

  const _TopHeaderRow({
    required this.onShare,
    required this.onBack,
    required this.meta,
    required this.isSharing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AeroIconButton(
          onPressed: onBack,
          icon: Icons.arrow_back,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          iconColor: theme.colorScheme.onSurface,
          size: 44,
        ),
        const SizedBox(width: TerritoryTokens.space12),
        Expanded(
          child: AeroSurface(
            level: AeroLevel.medium,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            padding: const EdgeInsets.symmetric(
              horizontal: TerritoryTokens.space16,
              vertical: TerritoryTokens.space12,
            ),
            child: meta,
          ),
        ),
        const SizedBox(width: TerritoryTokens.space12),
        AeroIconButton(
          onPressed: onShare,
          icon: Icons.share,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          iconColor: theme.colorScheme.primary,
          size: 44,
          isLoading: isSharing,
        ),
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  final RunDto run;
  final List<LatLng> route;
  final List<LatLng> polygon;
  final AppSettings settings;
  final double distanceKm;
  final String durationLabel;
  final String paceLabel;
  final String speedLabel;
  final bool isClosedCircuit;
  final double? areaKm2;
  final Map<String, dynamic>? weatherData;
  final IconData weatherIcon;
  final String shareText;

  const _ShareCard({
    required this.run,
    required this.route,
    required this.polygon,
    required this.settings,
    required this.distanceKm,
    required this.durationLabel,
    required this.paceLabel,
    required this.speedLabel,
    required this.isClosedCircuit,
    required this.areaKm2,
    required this.weatherData,
    required this.weatherIcon,
    required this.shareText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: 1080,
      height: 1080,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.85),
              scheme.secondary.withValues(alpha: 0.85),
              scheme.tertiary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(72),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: CustomPaint(
                    painter: _RoutePainter(
                      route: route,
                      polygon: polygon,
                      settings: settings,
                      routeColor: scheme.primary,
                      polygonColor: scheme.secondary,
                      backgroundColor: scheme.surface,
                      maskColor: scheme.surface,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 120,
              right: 120,
              bottom: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Territory Run',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _MetricChip(label: 'Distancia', value: '${distanceKm.toStringAsFixed(2)} km'),
                      _MetricChip(label: 'Duración', value: durationLabel),
                      _MetricChip(label: 'Ritmo', value: '$paceLabel min/km'),
                      _MetricChip(label: 'Velocidad', value: '$speedLabel km/h'),
                      if (isClosedCircuit)
                        const _MetricChip(label: 'Circuito', value: 'Cerrado', icon: Icons.check_circle),
                      if (areaKm2 != null)
                        _MetricChip(label: 'Área ganada', value: '${areaKm2!.toStringAsFixed(3)} km²'),
                      if (weatherData != null)
                        _MetricChip(
                          label: 'Clima',
                          value: '${(weatherData?['condition'] as String?) ?? ''}${weatherData?['temperatureC'] != null ? ', ${(weatherData!['temperatureC'] as num).toStringAsFixed(1)}°C' : ''}',
                          icon: weatherIcon,
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    shareText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _MetricChip({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<LatLng> route;
  final List<LatLng> polygon;
  final AppSettings settings;
  final Color routeColor;
  final Color polygonColor;
  final Color backgroundColor;
  final Color maskColor;

  _RoutePainter({
    required this.route,
    required this.polygon,
    required this.settings,
    required this.routeColor,
    required this.polygonColor,
    required this.backgroundColor,
    required this.maskColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allPoints = <LatLng>[];
    allPoints.addAll(route);
    allPoints.addAll(polygon);

    final homeLat = settings.homeLatitude;
    final homeLon = settings.homeLongitude;
    double? homeLatValue;
    double? homeLonValue;
    if (settings.homeFilterEnabled && homeLat != null && homeLon != null) {
      homeLatValue = homeLat;
      homeLonValue = homeLon;
      allPoints.add(LatLng(homeLatValue, homeLonValue));
    }

    if (allPoints.isEmpty) {
      final paint = Paint()..color = backgroundColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(40)),
        paint,
      );
      return;
    }

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLon = allPoints.first.longitude;
    double maxLon = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    if ((maxLat - minLat).abs() < 1e-5) {
      maxLat += 0.0005;
      minLat -= 0.0005;
    }
    if ((maxLon - minLon).abs() < 1e-5) {
      maxLon += 0.0005;
      minLon -= 0.0005;
    }

    Offset toOffset(LatLng point) {
      final dx = (point.longitude - minLon) / (maxLon - minLon);
      final dy = (point.latitude - minLat) / (maxLat - minLat);
      return Offset(dx * size.width, size.height - dy * size.height);
    }

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(40)),
      backgroundPaint,
    );

    if (polygon.length >= 3) {
      final path = Path();
      final first = toOffset(polygon.first);
      path.moveTo(first.dx, first.dy);
      for (final point in polygon.skip(1)) {
        final offset = toOffset(point);
        path.lineTo(offset.dx, offset.dy);
      }
      path.close();

      final polygonPaint = Paint()
        ..color = polygonColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, polygonPaint);

      final polygonStroke = Paint()
        ..color = polygonColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawPath(path, polygonStroke);
    }

    if (route.length >= 2) {
      final path = Path();
      final first = toOffset(route.first);
      path.moveTo(first.dx, first.dy);
      for (final point in route.skip(1)) {
        final offset = toOffset(point);
        path.lineTo(offset.dx, offset.dy);
      }

      final routePaint = Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 8;
      canvas.drawPath(path, routePaint);

      final startPaint = Paint()..color = routeColor.withValues(alpha: 0.3);
      final startOffset = toOffset(route.first);
      canvas.drawCircle(startOffset, 12, startPaint);
      final endOffset = toOffset(route.last);
      canvas.drawCircle(endOffset, 12, Paint()..color = routeColor);
    }

    if (homeLatValue != null && homeLonValue != null) {
      final center = toOffset(LatLng(homeLatValue, homeLonValue));
      final metersPerDegLat = 111320.0;
      final metersPerDegLon = 111320.0 * math.cos(homeLatValue * math.pi / 180);
      final degLatRadius = settings.homeRadiusMeters / metersPerDegLat;
      final degLonRadius = settings.homeRadiusMeters / metersPerDegLon;
      final pxPerDegLat = size.height / (maxLat - minLat);
      final pxPerDegLon = size.width / (maxLon - minLon);
      final radiusPx = math.max(
        (degLatRadius * pxPerDegLat).abs(),
        (degLonRadius * pxPerDegLon).abs(),
      );

      final maskPaint = Paint()
        ..color = maskColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radiusPx, maskPaint);

      final blurPaint = Paint()
        ..color = maskColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(center, radiusPx + 24, blurPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeatherInfo extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final IconData weatherIcon;

  const _WeatherInfo({required this.weatherData, required this.weatherIcon});

  @override
  Widget build(BuildContext context) {
    if (weatherData == null) return const SizedBox.shrink();

    final condition = weatherData?['condition'] as String?;
    final temp = weatherData?['temperatureC'] as num?;

    if (condition == null && temp == null) return const SizedBox.shrink();

    return _StatMetricTile(
      metric: _StatMetric(
        icon: weatherIcon,
        label: 'Clima',
        value: '${condition ?? ''}${condition != null && temp != null ? ', ' : ''}${temp?.toStringAsFixed(1) ?? ''}°C',
      ),
    );
  }
}

class _StatsCluster extends StatelessWidget {
  final double distanceKm;
  final String durationLabel;
  final String paceLabel;
  final String speedLabel;
  final bool isClosedCircuit;
  final double? areaKm2;
  final Map<String, dynamic>? weatherData;
  final IconData weatherIcon;

  const _StatsCluster({
    required this.distanceKm,
    required this.durationLabel,
    required this.paceLabel,
    required this.speedLabel,
    required this.isClosedCircuit,
    required this.areaKm2,
    required this.weatherData,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _buildMetrics();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: AeroSurface(
        level: AeroLevel.medium,
        padding: const EdgeInsets.symmetric(
          horizontal: TerritoryTokens.space16,
          vertical: TerritoryTokens.space16,
        ),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusXLarge),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacing = TerritoryTokens.space12;
            final itemWidth = (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                ...metrics.map(
                  (metric) => SizedBox(
                    width: itemWidth,
                    child: _StatMetricTile(metric: metric),
                  ),
                ),
                if (weatherData != null) 
                  SizedBox(
                    width: itemWidth,
                    child: _WeatherInfo(
                      weatherData: weatherData,
                      weatherIcon: weatherIcon,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_StatMetric> _buildMetrics() {
    final metrics = <_StatMetric>[
      _StatMetric(
        icon: Icons.route,
        label: 'Distancia',
        value: '${distanceKm.toStringAsFixed(2)} km',
      ),
      _StatMetric(
        icon: Icons.timer_outlined,
        label: 'Tiempo',
        value: durationLabel,
      ),
      _StatMetric(
        icon: Icons.speed,
        label: 'Ritmo',
        value: '$paceLabel min/km',
      ),
    ];

    if (speedLabel != '--') {
      metrics.add(
        _StatMetric(
          icon: Icons.flash_on,
          label: 'Velocidad',
          value: '$speedLabel km/h',
        ),
      );
    }

    if (isClosedCircuit && areaKm2 != null) {
      metrics.add(
        _StatMetric(
          icon: Icons.terrain,
          label: 'Territorio ganado',
          value: '${areaKm2!.toStringAsFixed(3)} km²',
        ),
      );
    }


    return metrics;
  }
}

class _StatMetric {
  final IconData icon;
  final String label;
  final String value;

  const _StatMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatMetricTile extends StatelessWidget {
  final _StatMetric metric;

  const _StatMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TerritoryTokens.space12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              metric.icon,
              size: 20,
              color: scheme.primary,
            ),
            const SizedBox(width: TerritoryTokens.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: TerritoryTokens.space4),
                  Text(
                    metric.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
