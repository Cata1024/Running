import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';
import '../../../../domain/constants/level_system.dart';
import 'profile_view_model.dart';

class LevelSection extends StatelessWidget {
  final ProfileViewModel profile;

  const LevelSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = profile.levelProgress.clamp(0.0, 1.0);
    
    // Calcular XP y nivel con el nuevo sistema
    final currentLevel = profile.level;
    final currentXP = profile.xp;
    final xpForCurrentLevel = LevelSystem.totalXpForLevel(currentLevel);
    final xpForNextLevel = LevelSystem.totalXpForLevel(currentLevel + 1);
    final xpInCurrentLevel = currentXP - xpForCurrentLevel;
    final xpNeededForNext = xpForNextLevel - xpForCurrentLevel;
    final xpToNext = xpForNextLevel - currentXP;
    
    final levelTitle = LevelSystem.getLevelTitle(currentLevel);
    final levelColor = Color(
      int.parse(LevelSystem.getLevelColor(currentLevel).replaceAll('#', '0xFF')),
    );

    return AeroSurface(
      level: AeroLevel.medium,
      padding: const EdgeInsets.all(TerritoryTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nivel y título
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [levelColor, levelColor.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: levelColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "NIVEL $currentLevel",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.emoji_events,
                        color: levelColor,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    levelTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // XP total con icono
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentXP XP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total acumulado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: TerritoryTokens.space20),
          
          // Barra de progreso mejorada
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$xpInCurrentLevel / $xpNeededForNext',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$xpToNext XP para nivel ${currentLevel + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                child: Stack(
                  children: [
                    // Fondo
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                      ),
                    ),
                    // Progreso con gradiente
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [levelColor, levelColor.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: levelColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${(progress * 100).round()}% completado",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LevelSectionShimmer extends StatelessWidget {
  const LevelSectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.medium,
      padding: const EdgeInsets.all(TerritoryTokens.space24),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceContainerHighest,
        highlightColor: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 28,
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 80),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: TerritoryTokens.space16),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
              ),
            ),
            const SizedBox(height: TerritoryTokens.space12),
            Container(
              height: 14,
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 60),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
