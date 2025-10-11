import 'package:flutter/material.dart';

import 'liquid_overlay.dart';
import 'profile_avatar.dart';

class RunProfileOverlay extends StatelessWidget {
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool showOnlyMine;
  final ValueChanged<bool> onToggleTerritory;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;
  final VoidCallback? onViewMetrics;

  const RunProfileOverlay({
    super.key,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.showOnlyMine,
    required this.onToggleTerritory,
    required this.onOpenSettings,
    required this.onLogout,
    this.onViewMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!
        : (email ?? 'Corredor');

    return LiquidOverlay(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileAvatar(photoUrl: photoUrl),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onViewMetrics != null)
            _OverlayIconButton(
              icon: Icons.data_thresholding_outlined,
              tooltip: 'Ver métricas',
              onPressed: onViewMetrics!,
            ),
          _OverlayIconButton(
            icon: Icons.settings_suggest_outlined,
            tooltip: 'Personalización',
            onPressed: onOpenSettings,
          ),
          _OverlayIconButton(
            icon: showOnlyMine ? Icons.person_pin_circle : Icons.public,
            tooltip: showOnlyMine
                ? 'Ver territorio de todos'
                : 'Ver solo mi territorio',
            onPressed: () => onToggleTerritory(!showOnlyMine),
          ),
          _OverlayIconButton(
            icon: Icons.logout,
            tooltip: 'Cerrar sesión',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
