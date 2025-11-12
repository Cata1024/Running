import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';
import '../../../providers/app_providers.dart';

class ProfileActionsSection extends ConsumerWidget {
  const ProfileActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authService = ref.read(authServiceProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final mapType = ref.watch(mapTypeProvider);
    final mapTypeNotifier = ref.read(mapTypeProvider.notifier);

    final logoutBackground = theme.colorScheme.error.withValues(alpha: 0.9);
    final logoutForeground = theme.colorScheme.onError;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + TerritoryTokens.space16,
      ),
      child: AeroSurface(
        level: AeroLevel.subtle,
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox.shrink(),
            const SizedBox(height: TerritoryTokens.space12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final columns = isWide ? 4 : 2;
                final spacing = TerritoryTokens.space12;
                final totalSpacing = spacing * (columns - 1);
                final availableWidth = constraints.maxWidth - totalSpacing;
                final tileWidth = (availableWidth / columns).clamp(0.0, constraints.maxWidth).toDouble();

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: MapType.values
                      .map(
                        (type) => SizedBox(
                          width: tileWidth,
                          child: _MapTypeTile(
                            type: type,
                            isSelected: type == mapType,
                            label: _labelFor(type),
                            icon: _iconFor(type),
                            onTap: () => mapTypeNotifier.setMapType(type),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: TerritoryTokens.space12),
            AeroButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Seguro que quieres cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await authService.signOut();
                }
              },
              isOutlined: true,
              backgroundColor: logoutBackground,
              child: IconTheme(
                data: IconThemeData(color: logoutForeground),
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: logoutForeground,
                    fontWeight: FontWeight.w600,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: TerritoryTokens.space8),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(MapType type) {
    switch (type) {
      case MapType.normal:
        return 'Estándar';
      case MapType.satellite:
        return 'Satélite';
      case MapType.terrain:
        return 'Terreno';
      case MapType.hybrid:
        return 'Híbrido';
      case MapType.none:
        return 'Sin mapa';
    }
  }

  IconData _iconFor(MapType type) {
    switch (type) {
      case MapType.normal:
        return Icons.map_outlined;
      case MapType.satellite:
        return Icons.satellite_alt_outlined;
      case MapType.terrain:
        return Icons.terrain_outlined;
      case MapType.hybrid:
        return Icons.layers_outlined;
      case MapType.none:
        return Icons.grid_off_outlined;
    }
  }
}

class _MapTypeTile extends StatelessWidget {
  final MapType type;
  final bool isSelected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MapTypeTile({
    required this.type,
    required this.isSelected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final gradient = isSelected
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.9),
            ],
          )
        : null;
    final bgColor = isSelected
        ? null
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.15),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: foreground.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                size: 22,
                color: foreground,
              ),
            ),
            const SizedBox(height: TerritoryTokens.space8),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
