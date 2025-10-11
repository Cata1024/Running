import 'package:flutter/material.dart';

import '../../run/widgets/liquid_overlay.dart';
import '../../run/widgets/profile_avatar.dart';

class ProfileActionsOverlay extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoUrl;
  final VoidCallback? onEditProfile;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onLogout;

  const ProfileActionsOverlay({
    super.key,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.onEditProfile,
    this.onNavigateToMap,
    this.onOpenSettings,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LiquidOverlay(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileAvatar(
              photoUrl: photoUrl, radius: 26, fallbackIcon: Icons.person),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (onNavigateToMap != null)
            _OverlayIconButton(
              icon: Icons.map_outlined,
              tooltip: 'Explorar territorios',
              onPressed: onNavigateToMap!,
            ),
          if (onEditProfile != null)
            _OverlayIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Editar perfil',
              onPressed: onEditProfile!,
            ),
          if (onOpenSettings != null)
            _OverlayIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Ajustes',
              onPressed: onOpenSettings!,
            ),
          if (onLogout != null)
            _OverlayIconButton(
              icon: Icons.logout,
              tooltip: 'Cerrar sesión',
              onPressed: onLogout!,
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
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
