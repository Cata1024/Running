import 'package:flutter/material.dart';

import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// Card para mostrar estadísticas con estilo glassmorphism
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveColor = color ?? scheme.primary;
    final borderRadius = BorderRadius.circular(TerritoryTokens.radiusLarge);

    Widget card = AeroSurface(
      level: AeroLevel.subtle,
      borderRadius: borderRadius,
      padding: const EdgeInsets.symmetric(
        horizontal: TerritoryTokens.space16,
        vertical: TerritoryTokens.space12,
      ),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(minWidth: 140, maxWidth: 180, minHeight: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(TerritoryTokens.radiusMedium),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: effectiveColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.navigate_next_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: TerritoryTokens.space8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: TerritoryTokens.space4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}
