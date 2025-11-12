import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/aero_widgets.dart';
import '../../../../core/design_system/territory_tokens.dart';
import '../../../providers/achievements_provider.dart';
import '../../achievements/widgets/achievement_card.dart';
import '../../../../domain/entities/achievement.dart';

/// Sección de logros para mostrar en el perfil
class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Verificar que el caso de uso esté inicializado antes de acceder a los datos
    final initState = ref.watch(achievementsUseCaseProvider);
    
    // Mostrar loading o error si es necesario
    if (initState.isLoading) {
      return const AeroCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (initState.hasError) {
      return const SizedBox.shrink();
    }
    
    // Solo acceder a los datos cuando la inicialización esté completa
    final stats = ref.watch(achievementsStatsProvider);
    final recentUnlocked = ref.watch(unlockedAchievementsProvider).take(5).toList();
    final nearCompletion = ref.watch(nearCompletionAchievementsProvider).take(3).toList();

    return AeroCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y botón ver todos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '🏆',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Logros',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/achievements');
                  },
                  child: Row(
                    children: [
                      Text(
                        'Ver todos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estadísticas principales
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    theme,
                    icon: Icons.emoji_events,
                    value: stats.unlockedCount.toString(),
                    label: 'Desbloqueados',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.dividerColor,
                  ),
                  _buildStatItem(
                    theme,
                    icon: Icons.stars,
                    value: stats.totalXp.toString(),
                    label: 'XP Total',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.dividerColor,
                  ),
                  _buildStatItem(
                    theme,
                    icon: Icons.trending_up,
                    value: stats.completionText,
                    label: 'Completado',
                  ),
                ],
              ),
            ),

            // Barra de progreso general
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso General',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      stats.progressText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                  child: LinearProgressIndicator(
                    value: stats.completionPercentage,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            // Logros cercanos a completar
            if (nearCompletion.isNotEmpty) ...[
              const SizedBox(height: 24),
              _HorizontalAchievementsList(
                title: '🔥 Casi lo logras',
                achievements: nearCompletion,
                showProgress: true,
              ),
            ],

            // Logros recientes
            if (recentUnlocked.isNotEmpty) ...[
              const SizedBox(height: 24),
              _HorizontalAchievementsList(
                title: '✨ Logros Recientes',
                achievements: recentUnlocked,
                showProgress: false,
              ),
            ],

            // Si no hay logros
            if (stats.unlockedCount == 0) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¡Comienza a correr para desbloquear logros!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _HorizontalAchievementsList extends StatelessWidget {
  final String title;
  final List<Achievement> achievements;
  final bool showProgress;

  const _HorizontalAchievementsList({
    required this.title,
    required this.achievements,
    required this.showProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final cardWidth = maxWidth >= 720
                ? 144.0
                : maxWidth >= 540
                    ? 128.0
                    : maxWidth >= 420
                        ? 112.0
                        : 96.0;
            final listHeight = cardWidth + 44;

            return SizedBox(
              height: listHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return AchievementCard(
                    achievement: achievement,
                    compact: true,
                    compactWidth: cardWidth,
                    compactMargin: EdgeInsets.zero,
                    showProgress: showProgress,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/achievements');
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: achievements.length,
              ),
            );
          },
        ),
      ],
    );
  }
}
