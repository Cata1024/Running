import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';
import 'profile_view_model.dart';

class MainStatsSection extends StatelessWidget {
  final ProfileViewModel profile;

  const MainStatsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = <_StatTile>[
      _StatTile(
        icon: Icons.directions_run,
        value: profile.totalRuns.toString(),
        label: 'Carreras',
      ),
      _StatTile(
        icon: Icons.social_distance,
        value: profile.totalDistanceKm.toStringAsFixed(1),
        label: 'Kilómetros',
      ),
      _StatTile(
        icon: Icons.timer_outlined,
        value: _formatDuration(profile.totalTimeSeconds),
        label: 'Tiempo total',
      ),
      if (profile.streak > 0)
        _StatTile(
          icon: Icons.local_fire_department,
          value: profile.streak.toString(),
          label: 'Racha',
        ),
    ];

    return AeroSurface(
      level: AeroLevel.subtle,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > TerritoryTokens.breakpoints.tablet;

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats
                  .map(
                    (tile) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TerritoryTokens.space8,
                        ),
                        child: tile,
                      ),
                    ),
                  )
                  .toList(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                stats[i],
                if (i != stats.length - 1)
                  const Divider(height: TerritoryTokens.space24),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--:--';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    final minuteString = minutes.toString().padLeft(2, '0');
    final secondString = secs.toString().padLeft(2, '0');

    if (hours > 0) {
      final hourString = hours.toString().padLeft(2, '0');
      return '$hourString:$minuteString:$secondString';
    }

    return '$minuteString:$secondString';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: scheme.primary,
            ),
            const SizedBox(width: TerritoryTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: TerritoryTokens.space4),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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

class MainStatsSectionShimmer extends StatelessWidget {
  const MainStatsSectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.subtle,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceContainerHighest,
        highlightColor: theme.colorScheme.surface,
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index < 2 ? TerritoryTokens.space24 : 0,
              ),
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: TerritoryTokens.space8),
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: TerritoryTokens.space4),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
