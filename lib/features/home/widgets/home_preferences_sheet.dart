import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePreferencesSheet extends StatefulWidget {
  final bool followUser;
  final MapType mapType;

  const HomePreferencesSheet({super.key, required this.followUser, required this.mapType});

  @override
  State<HomePreferencesSheet> createState() => _HomePreferencesSheetState();
}

class _HomePreferencesSheetState extends State<HomePreferencesSheet> {
  late bool _followUser;
  late MapType _mapType;

  @override
  void initState() {
    super.initState();
    _followUser = widget.followUser;
    _mapType = widget.mapType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.tune),
              const SizedBox(width: 8),
              Text('Personalización', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _followUser,
            onChanged: (v) => setState(() => _followUser = v),
            title: const Text('Seguir usuario'),
            secondary: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.map_outlined),
              const SizedBox(width: 8),
              const Text('Tipo de mapa'),
              const Spacer(),
              DropdownButton<MapType>(
                value: _mapType,
                onChanged: (v) => setState(() => _mapType = v ?? MapType.normal),
                items: const [
                  DropdownMenuItem(value: MapType.normal, child: Text('Normal')),
                  DropdownMenuItem(value: MapType.terrain, child: Text('Terreno')),
                  DropdownMenuItem(value: MapType.satellite, child: Text('Satélite')),
                  DropdownMenuItem(value: MapType.hybrid, child: Text('Híbrido')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                HomePreferencesResult(follow: _followUser, mapType: _mapType),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Aplicar'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class HomePreferencesResult {
  final bool follow;
  final MapType mapType;

  const HomePreferencesResult({required this.follow, required this.mapType});
}
