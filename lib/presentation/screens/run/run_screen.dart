import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:running/core/map_icons.dart';
import 'package:running/core/design_system/territory_tokens.dart';
import 'package:running/data/models/territory_dto.dart';
import 'package:running/presentation/providers/app_providers.dart' hide RunState;
import 'package:running/presentation/providers/territory_provider.dart';
import 'package:running/presentation/providers/run_tracker_provider.dart';
import 'package:running/presentation/utils/map_style_utils.dart';
import '../../utils/run_calculations.dart';
import 'package:running/core/widgets/aero_surface.dart';

class RunScreen extends ConsumerStatefulWidget {
  // Callback para notificar cambios de estado sin usar provider
  final void Function(bool isRunning, bool isPaused)? onRunStateChanged;
  
  const RunScreen({
    super.key,
    this.onRunStateChanged,
  });

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

Set<Polygon> _parseTerritoryPolygons(
    TerritoryDto? territory, ThemeData theme) {
  if (territory == null) return <Polygon>{};
  final dynamic geoDyn = territory.unionGeoJson;
  if (geoDyn is! Map<String, dynamic>) return <Polygon>{};
  final Map<String, dynamic> geo = geoDyn;

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
  // La mayoría del estado y la lógica ahora viven en `RunTrackerNotifier`.
  GoogleMapController? _mapController;
  MapIconsBundle? _iconBundle;
  LatLng? _pendingCameraTarget;
  bool _runListenerInitialized = false;

  // Opciones para el modal de guardado (se moverán junto con la lógica)
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

  void _toggleHud() {
    ref.read(runTrackerProvider.notifier).toggleHud();
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

  Set<Marker> _buildMarkers(RunState runState, [MapIconsBundle? bundle]) {
    final icons = bundle ?? _iconBundle;
    final currentLocation = runState.currentLocation ?? const LatLng(4.6097, -74.0817);

    if (runState.routePoints.isEmpty) {
      return {
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation,
          infoWindow: const InfoWindow(title: 'Ubicación actual'),
          icon: icons?.runner ?? BitmapDescriptor.defaultMarker,
        ),
      };
    }

    final start = runState.routePoints.first;
    final end = runState.routePoints.last;
    final bool isActive = runState.isRunning && !runState.isPaused;

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
              ? (runState.isPaused ? 'Pausado' : 'Corriendo...')
              : 'Fin de la carrera',
        ),
        icon: isActive
            ? (icons?.runner ?? BitmapDescriptor.defaultMarker)
            : (icons?.finish ?? BitmapDescriptor.defaultMarkerWithHue(0)),
      ),
    };
  }

  Set<Polyline> _buildPolylines(RunState runState, ThemeData theme) {
    final displayPoints = runState.smoothedRoute.isNotEmpty ? runState.smoothedRoute : runState.routePoints;
    
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
    // Obtener ubicación y cargar iconos DESPUÉS del build inicial
    // Delay adicional para evitar conflictos con provider
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        ref.read(mapIconsProvider.future).then((bundle) {
          if (!mounted) return;
          setState(() {
            _iconBundle = bundle;
            // The markers will be rebuilt by the build method watching the provider state
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _handleRunStateChange(RunState? previous, RunState next) {
    if (!mounted) return;

    if (previous?.isRunning != next.isRunning ||
        previous?.isPaused != next.isPaused) {
      widget.onRunStateChanged?.call(next.isRunning, next.isPaused);
    }

    final nextLocation = next.currentLocation;
    if (!next.followUser || nextLocation == null) {
      return;
    }

    final prevLat = previous?.currentLocation?.latitude;
    final prevLng = previous?.currentLocation?.longitude;
    final hasLocationChanged =
        prevLat != nextLocation.latitude || prevLng != nextLocation.longitude;

    if (hasLocationChanged) {
      _moveCameraTo(nextLocation);
    }
  }

  void _toggleRun() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notifier = ref.read(runTrackerProvider.notifier);
      final isCurrentlyRunning = ref.read(runTrackerProvider).isRunning;

      if (isCurrentlyRunning) {
        // Detener el seguimiento
        notifier.stopRun();
        
        // Mostrar modal de condiciones
        final conditions = await _promptRunConditions();
        
        // Guardar la carrera con las condiciones
        final result = await notifier.stopAndSaveRun(conditions: conditions);
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        if (result.success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Carrera guardada correctamente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (result.message != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(result.message!),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Reintentar',
                onPressed: () {
                  notifier.stopAndSaveRun(conditions: conditions);
                },
              ),
            ),
          );
        }
      } else {
        // Iniciar nueva carrera
        notifier.startRun();
      }
    });
  }

  void _pauseRun() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(runTrackerProvider.notifier);
      final runState = ref.read(runTrackerProvider);
      if (!runState.isRunning) return;
      
      notifier.togglePause();
    });
  }

  void _moveCameraTo(LatLng target, {double? zoom}) {
    if (!mounted) return;

    final controller = _mapController;
    if (controller == null) {
      _pendingCameraTarget = target;
      return;
    }

    _pendingCameraTarget = null;

    final update = zoom != null
        ? CameraUpdate.newLatLngZoom(target, zoom)
        : CameraUpdate.newLatLng(target);

    controller.animateCamera(update);
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Color _gpsStatusColor(GpsStatus status, ThemeData theme) {
    switch (status) {
      case GpsStatus.strong:
        return theme.colorScheme.primary;
      case GpsStatus.medium:
        return theme.colorScheme.tertiary;
      case GpsStatus.weak:
        return theme.colorScheme.error;
      case GpsStatus.initial:
        return theme.colorScheme.outlineVariant;
    }
  }

  String _gpsStatusLabel(GpsStatus status) {
    switch (status) {
      case GpsStatus.strong:
        return 'GPS fuerte';
      case GpsStatus.medium:
        return 'GPS medio';
      case GpsStatus.weak:
        return 'GPS débil';
      case GpsStatus.initial:
        return 'GPS iniciando';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_runListenerInitialized) {
      _runListenerInitialized = true;
      final currentState = ref.read(runTrackerProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleRunStateChange(null, currentState);
      });
      ref.listen<RunState>(
        runTrackerProvider,
        _handleRunStateChange,
      );
    }

    final runState = ref.watch(runTrackerProvider);
    final theme = Theme.of(context);
    final territoryAsync = ref.watch(userTerritoryDtoProvider);
    final mapType = ref.watch(mapTypeProvider);
    final mapStyle = ref.watch(mapStyleProvider);
    final styleString = resolveMapStyle(mapStyle, theme.brightness);
    final mediaPadding = MediaQuery.of(context).padding;
    final bool navVisible = !(runState.isRunning && !runState.isPaused);
    final navBarHeight = ref.watch(navBarHeightProvider);
    
    final double navClearance = navVisible ? navBarHeight : 0;
    final double bottomOffset = mediaPadding.bottom + (navVisible ? navClearance + 16 : 16);
    final double topOffset = mediaPadding.top + 16;

    final Set<Marker> markers = _buildMarkers(runState, _iconBundle);
    final Set<Polyline> polylines = _buildPolylines(runState, theme);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: runState.currentLocation ?? const LatLng(4.6097, -74.0817),
                zoom: 17,
              ),
              markers: markers,
              polylines: polylines,
              polygons: _parseTerritoryPolygons(territoryAsync.value, theme),
              mapType: mapType,
              style: styleString,
              onMapCreated: (controller) {
                _mapController = controller;
                final target = _pendingCameraTarget;
                if (target != null) {
                  controller.moveCamera(
                    CameraUpdate.newLatLngZoom(target, 17),
                  );
                  _pendingCameraTarget = null;
                }
              },
              onCameraMoveStarted: () {
                if (!mounted) return;
                ref.read(runTrackerProvider.notifier).toggleFollowUser(false);
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
              elapsedLabel: _formatTime(runState.elapsedTime),
              distanceLabel: runState.totalDistance.toStringAsFixed(2),
              paceLabel: RunCalculations.formatPace(RunCalculations.calculatePaceSecPerKm(runState.totalDistance, runState.elapsedTime)),
              speedLabel: RunCalculations.formatSpeed(RunCalculations.calculateSpeedKmh(runState.totalDistance, runState.elapsedTime)),
              gpsLabel: _gpsStatusLabel(runState.gpsStatus),
              gpsColor: _gpsStatusColor(runState.gpsStatus, theme),
              accuracy: runState.lastAccuracy ?? 0.0,
              isCollapsed: runState.isHudCollapsed,
              isRunning: runState.isRunning,
              isPaused: runState.isPaused,
              onToggle: _toggleHud,
            ),
          ),
          Positioned(
            left: TerritoryTokens.space16,
            right: TerritoryTokens.space16,
            bottom: bottomOffset,
            child: _ControlPanel(
              isRunning: runState.isRunning,
              isPaused: runState.isPaused,
              onCenter: () {
                if (!mounted) return;
                final notifier = ref.read(runTrackerProvider.notifier);
                notifier.toggleFollowUser(true);

                final currentLocation = runState.currentLocation;
                if (currentLocation != null) {
                  _moveCameraTo(currentLocation);
                } else {
                  notifier.getCurrentLocation();
                }
              },
              onToggleRun: _toggleRun,
              onTogglePause: runState.isRunning ? _pauseRun : null,
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
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Tiempo',
                    value: elapsedLabel,
                    textStyle: textStyle,
                  ),
                ),
                const VerticalDivider(width: TerritoryTokens.space12, indent: 8, endIndent: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Distancia',
                    value: '$distanceLabel km',
                    textStyle: textStyle,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: TerritoryTokens.space12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Ritmo',
                    value: '$paceLabel min/km',
                    textStyle: textStyle,
                  ),
                ),
                const VerticalDivider(width: TerritoryTokens.space12, indent: 8, endIndent: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Velocidad',
                    value: '$speedLabel km/h',
                    textStyle: textStyle,
                  ),
                ),
              ],
            ),
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

    return Column(
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
