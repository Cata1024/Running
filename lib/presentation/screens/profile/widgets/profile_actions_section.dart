import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    final editBackground = theme.colorScheme.primary.withValues(alpha: 0.9);
    final editForeground = theme.colorScheme.onPrimary;

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
            Row(
              children: [
                Expanded(
                  child: AeroButton(
                    onPressed: () => context.push('/profile/complete'),
                    isOutlined: true,
                    backgroundColor: editBackground,
                    child: IconTheme(
                      data: IconThemeData(color: editForeground),
                      child: DefaultTextStyle.merge(
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: editForeground,
                          fontWeight: FontWeight.w600,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: TerritoryTokens.space8),
                            Text('Editar perfil'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TerritoryTokens.space12),
            Wrap(
              spacing: TerritoryTokens.space12,
              runSpacing: TerritoryTokens.space12,
              alignment: WrapAlignment.center,
              children: MapType.values.map((type) {
                final isSelected = type == mapType;
                final background = isSelected
                    ? theme.colorScheme.secondary.withValues(alpha: 0.9)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6);
                final foreground = isSelected
                    ? theme.colorScheme.onSecondary
                    : theme.colorScheme.onSurface;

                return SizedBox(
                  width: 120,
                  child: AeroButton(
                    onPressed: () => mapTypeNotifier.setMapType(type),
                    isOutlined: true,
                    backgroundColor: background,
                    child: DefaultTextStyle.merge(
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                      child: IconTheme(
                        data: IconThemeData(color: foreground),
                        child: _MapTypeLabel(type: type),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
}

class _MapTypeLabel extends StatelessWidget {
  final MapType type;

  const _MapTypeLabel({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(type);
    final icon = _iconFor(type);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: TerritoryTokens.space8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
