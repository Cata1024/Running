import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../core/map_styles.dart';
import '../core/marker_utils.dart';
import '../services/auth/auth_service.dart';
import 'home/helpers/map_layers_builder.dart';
import 'home/providers/run_state_provider.dart';
import 'home/widgets/home_map.dart';
import 'home/widgets/home_metrics_bar.dart';
import 'home/widgets/home_run_fab.dart';
import 'home/widgets/home_preferences_sheet.dart';
import 'map_widget.dart';

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
      final blue = await MarkerUtils.runnerMarker(
        logicalSize: 72,
        tint: const Color(0xFF1E88E5),
      );
      if (mounted) {
        setState(() {
          _runnerIconBlue = blue;
        });
      }
    } catch (e) {
      debugPrint('Error creando íconos de marcador: $e');
    }
  }

  HomeMapLayersBuilder _buildMapLayers(RunState runState) {
    return HomeMapLayersBuilder(
      runState: runState,
      currentUserLocation: _currentUserLocation,
      runnerIcon: _runnerIconBlue,
      heading: _heading,
    );
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
                child: HomeMetricsBar(runState: runState),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: HomeRunFab(runState: runState),
    );
  }

  Widget _buildMap(RunState runState) {
    final layersBuilder = _buildMapLayers(runState);

    return HomeMap(
      mapKey: _mapContainerKey,
      initialTarget: _currentUserLocation ?? const LatLng(4.7110, -74.0721),
      mapType: _mapType,
      mapStyle: _mapStyle,
      markers: layersBuilder.buildMarkers(),
      polylines: layersBuilder.buildPolylines(),
      polygons: layersBuilder.buildPolygons(),
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
                ref.read(authServiceProvider).signOut();
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _openPreferencesSheet() async {
    final result = await showModalBottomSheet<HomePreferencesResult>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => HomePreferencesSheet(
        followUser: _followUser,
        mapType: _mapType,
      ),
    );

    if (result != null) {
      setState(() {
        _followUser = result.follow;
        _mapType = result.mapType;
      });
    }
  }
}
