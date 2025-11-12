import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/aero_widgets.dart';
import '../../../../domain/entities/achievement.dart';

/// Widget para mostrar una tarjeta de logro individual
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool compact;
  final double? compactWidth;
  final EdgeInsetsGeometry? compactMargin;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
    this.showProgress = true,
    this.compact = false,
    this.compactWidth,
    this.compactMargin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rarityColor = Color(int.parse(achievement.rarityColor.replaceAll('#', '0xFF')));

    if (compact) {
      return _buildCompactCard(context, theme, isDark, rarityColor);
    }

    return _buildFullCard(context, theme, isDark, rarityColor);
  }

  Widget _buildFullCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color rarityColor,
  ) {
    return GestureDetector(
      onTap: () {
        if (!achievement.isUnlocked) {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          children: [
            // Fondo con glassmorphism
            AeroCard(
              child: Opacity(
                opacity: achievement.isUnlocked ? 1.0 : 0.6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icono del logro
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: achievement.isUnlocked
                                  ? LinearGradient(
                                      colors: [
                                        rarityColor.withValues(alpha:0.3),
                                        rarityColor.withValues(alpha:0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: achievement.isUnlocked 
                                  ? null 
                                  : Colors.grey.withValues(alpha:0.2),
                              border: Border.all(
                                color: achievement.isUnlocked 
                                    ? rarityColor 
                                    : Colors.grey.withValues(alpha:0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                achievement.icon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Información del logro
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        achievement.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: achievement.isUnlocked 
                                              ? null 
                                              : theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                    if (achievement.isUnlocked)
                                      Icon(
                                        Icons.check_circle,
                                        color: rarityColor,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievement.description,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                
                                // Rareza y XP
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: rarityColor.withValues(alpha:0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: rarityColor.withValues(alpha:0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        achievement.rarityName,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: rarityColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.stars,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${achievement.xpReward} XP',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Barra de progreso
                      if (showProgress && !achievement.isUnlocked)
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildProgressBar(theme),
                          ],
                        ),
                      
                      // Fecha de desbloqueo
                      if (achievement.isUnlocked && achievement.unlockedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Desbloqueado el ${_formatDate(achievement.unlockedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Badge de "Cerca de completar"
            if (achievement.isNearCompletion)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha:0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '¡Casi!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color rarityColor,
  ) {
    final margin = compactMargin ?? const EdgeInsets.all(4);
    final width = compactWidth ?? 80.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: width,
        margin: margin,
        child: Column(
          children: [
            // Icono
            Container(
              width: width - 24,
              height: width - 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: achievement.isUnlocked
                    ? LinearGradient(
                        colors: [
                          rarityColor.withValues(alpha:0.3),
                          rarityColor.withValues(alpha:0.1),
                        ],
                      )
                    : null,
                color: achievement.isUnlocked 
                    ? null 
                    : Colors.grey.withValues(alpha:0.2),
                border: Border.all(
                  color: achievement.isUnlocked 
                      ? rarityColor 
                      : Colors.grey.withValues(alpha:0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: (width - 24) * 0.43,
                      color: achievement.isUnlocked ? null : Colors.grey,
                    ),
                  ),
                  if (achievement.isUnlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: rarityColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Título
            Text(
              achievement.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Progreso o XP
            if (!achievement.isUnlocked && showProgress)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${achievement.progressPercentage}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (achievement.isUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${achievement.xpReward}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: rarityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${achievement.currentValue}/${achievement.requiredValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: achievement.progress,
            backgroundColor: Colors.grey.withValues(alpha:0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              achievement.isNearCompletion 
                  ? Colors.orange 
                  : theme.colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
