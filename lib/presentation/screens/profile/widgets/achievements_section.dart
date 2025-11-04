import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/aero_widgets.dart';
import '../../../../core/design_system/territory_tokens.dart';
import '../../../providers/achievements_provider.dart';
import '../../achievements/widgets/achievement_card.dart';

/// Sección de logros para mostrar en el perfil
class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Verificar que el servicio esté inicializado antes de acceder a los datos
    final initState = ref.watch(achievementsInitializationProvider);
    
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
              Text(
                '🔥 Casi lo logras',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearCompletion.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < nearCompletion.length - 1 ? 8 : 0,
                      ),
                      child: AchievementCard(
                        achievement: nearCompletion[index],
                        compact: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/achievements');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            // Logros recientes
            if (recentUnlocked.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '✨ Logros Recientes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentUnlocked.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < recentUnlocked.length - 1 ? 8 : 0,
                      ),
                      child: AchievementCard(
                        achievement: recentUnlocked[index],
                        compact: true,
                        showProgress: false,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/achievements');
                        },
                      ),
                    );
                  },
                ),
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
