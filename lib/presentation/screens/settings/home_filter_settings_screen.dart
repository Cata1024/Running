import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../providers/app_providers.dart';

/// Pantalla para configurar el filtro de hogar (privacidad de ubicación)
class HomeFilterSettingsScreen extends ConsumerStatefulWidget {
  const HomeFilterSettingsScreen({super.key});

  @override
  ConsumerState<HomeFilterSettingsScreen> createState() => _HomeFilterSettingsScreenState();
}

class _HomeFilterSettingsScreenState extends ConsumerState<HomeFilterSettingsScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Cargar ubicación guardada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (settings.homeLatitude != null && settings.homeLongitude != null) {
        setState(() {
          _selectedLocation = LatLng(
            settings.homeLatitude!,
            settings.homeLongitude!,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          return;
        }
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Mover cámara
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error obteniendo ubicación: $e')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _saveHomeLocation() {
    if (_selectedLocation == null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Text('Selecciona una ubicación primero'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    ref.read(settingsProvider.notifier).setHomeLocation(
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Ubicación de hogar guardada'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _clearHomeLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: const Text('Eliminar ubicación de hogar'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar la ubicación de hogar? '
          'Esto desactivará el filtro de privacidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ref.read(settingsProvider.notifier).clearHomeLocation();
    setState(() => _selectedLocation = null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Ubicación de hogar eliminada'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtro de Hogar'),
        centerTitle: true,
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHomeLocation,
              tooltip: 'Eliminar ubicación',
            ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Padding(
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            child: AeroSurface(
              level: AeroLevel.subtle,
              padding: const EdgeInsets.all(TerritoryTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¿Qué es el filtro de hogar?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Oculta tu ubicación exacta de hogar en mapas compartidos y vistas públicas. '
                    'Los segmentos dentro del radio configurado serán enmascarados.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Switch
                  SwitchListTile(
                    value: settings.homeFilterEnabled,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleHomeFilter(value);
                    },
                    title: Text(
                      'Activar filtro de hogar',
                      style: theme.textTheme.bodyMedium,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  // Radio slider
                  if (settings.homeFilterEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Radio de privacidad: ${settings.homeRadiusMeters.toInt()}m',
                      style: theme.textTheme.labelMedium,
                    ),
                    Slider(
                      value: settings.homeRadiusMeters,
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: '${settings.homeRadiusMeters.toInt()}m',
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).setHomeRadius(value);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Mapa
          if (settings.homeFilterEnabled)
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? const LatLng(4.6097, -74.0817),
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: (latLng) {
                      setState(() {
                        _selectedLocation = latLng;
                      });
                    },
                    markers: _selectedLocation != null
                        ? {
                            Marker(
                              markerId: const MarkerId('home'),
                              position: _selectedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          }
                        : {},
                    circles: _selectedLocation != null
                        ? {
                            Circle(
                              circleId: const CircleId('home-radius'),
                              center: _selectedLocation!,
                              radius: settings.homeRadiusMeters,
                              fillColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                              strokeColor: theme.colorScheme.primary,
                              strokeWidth: 2,
                            ),
                          }
                        : {},
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),

                  // Botón de ubicación actual
                  Positioned(
                    right: 16,
                    bottom: 80,
                    child: FloatingActionButton(
                      heroTag: 'current-location',
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),

                  // Instrucciones
                  if (_selectedLocation == null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: AeroSurface(
                        level: AeroLevel.medium,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Toca el mapa para seleccionar tu hogar',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Botón guardar
          if (settings.homeFilterEnabled)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(TerritoryTokens.space16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _selectedLocation != null ? _saveHomeLocation : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar ubicación'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
