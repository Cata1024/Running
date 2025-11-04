import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/app_providers.dart';
import '../../utils/map_style_utils.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_surface.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/aero_button.dart';
import '../../../core/services/route_processor.dart';

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
    final asyncRun = ref.watch(runDocProvider(widget.runId));
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
          onRetry: () => ref.invalidate(runDocProvider(widget.runId)),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Carrera no encontrada'));
          }

          final route = _parseLineString(data['routeGeoJson']);
          final polygon = _parsePolygon(data['polygonGeoJson']);

          // 🎨 PROCESAR RUTA CON PIPELINE PROFESIONAL
          if (route.isNotEmpty && _processedRoute == null && !_isProcessingRoute) {
            // Procesar en el próximo frame para no bloquear UI
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _processRoute(route);
            });
          }

          // Usar ruta suavizada si está disponible, sino usar original
          final displayRoute = _processedRoute?.smoothedPoints ?? route;

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

          final distanceM = (data['distanceM'] as num?)?.toDouble() ?? 0.0;
          final durationS = (data['durationS'] as num?)?.toInt() ?? 0;
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
          final areaM2 = (data['areaGainedM2'] as num?)?.toDouble();
          final areaKm2 = areaM2 != null ? areaM2 / 1000000 : null;
          final bool isClosedCircuit = data['isClosedCircuit'] == true;
          final weatherData = data['conditions']?['weather'] as Map<String, dynamic>?;
          final weatherIcon = _getWeatherIcon(weatherData?['condition'] as String?);
          final startedAtStr = data['startedAt'] as String?;
          final startedAt =
              startedAtStr != null ? DateTime.tryParse(startedAtStr) : null;
          final shareText =
              'Mi carrera${startedAt != null ? ' del ${startedAt.year}-${startedAt.month.toString().padLeft(2, '0')}-${startedAt.day.toString().padLeft(2, '0')}' : ''}: ${(distanceM / 1000).toStringAsFixed(2)} km en $durationLabel (ritmo $paceLabel min/km)';

          return Stack(
            children: [
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
                    shareText: shareText,
                    onShare: () => SharePlus.instance.share(
                      ShareParams(text: shareText),
                    ),
                    onBack: () => Navigator.of(context).maybePop(),
                    meta: _buildHeader(data, theme),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  bottom: true,
                  minimum: EdgeInsets.only(
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

  static Widget _buildHeader(Map<String, dynamic> data, ThemeData theme) {
    final startedAtStr = data['startedAt'] as String?;
    final date = startedAtStr != null ? DateTime.tryParse(startedAtStr) : null;
    final isClosedCircuit = data['isClosedCircuit'] == true;
    final highlightColor = theme.colorScheme.tertiary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                date != null ? _formatHeaderDate(date) : 'Carrera',
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
}

class _TopHeaderRow extends StatelessWidget {
  final String shareText;
  final VoidCallback onShare;
  final VoidCallback onBack;
  final Widget meta;

  const _TopHeaderRow({
    required this.shareText,
    required this.onShare,
    required this.onBack,
    required this.meta,
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
        ),
      ],
    );
  }
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
