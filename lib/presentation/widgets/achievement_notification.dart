import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../core/design_system/territory_tokens.dart';
import '../../domain/entities/achievement.dart';
import '../providers/achievements_provider.dart';

/// Widget global para mostrar notificaciones de logros desbloqueados
class AchievementNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;
  
  const AchievementNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AchievementNotificationOverlay> createState() => 
      _AchievementNotificationOverlayState();
}

class _AchievementNotificationOverlayState 
    extends ConsumerState<AchievementNotificationOverlay>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _showNotification() {
    HapticFeedback.heavyImpact();
    _controller.forward();
    
    // Auto-hide después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _controller.isCompleted) {
        _hideNotification();
      }
    });
  }
  
  void _hideNotification() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = ref.watch(achievementNotificationProvider);
    final theme = Theme.of(context);
    
    // Mostrar notificación cuando cambia el achievement
    // Ejecutar después del frame para evitar "modify provider during build"
    ref.listen<Achievement?>(
      achievementNotificationProvider,
      (previous, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          if (next != null && next != previous) {
            _showNotification();
          } else if (next == null && previous != null) {
            _hideNotification();
          }
        });
      },
    );
    
    return Stack(
      children: [
        widget.child,
        
        if (achievement != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildNotificationCard(context, theme, achievement),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildNotificationCard(
    BuildContext context,
    ThemeData theme,
    Achievement achievement,
  ) {
    final rarityColor = Color(
      int.parse(achievement.rarityColor.replaceAll('#', '0xFF')),
    );
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(achievementNotificationProvider.notifier).hideAchievement();
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    rarityColor.withValues(alpha: 0.3),
                    rarityColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
                border: Border.all(
                  color: rarityColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de rareza
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: rarityColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '¡LOGRO ${achievement.rarityName.toUpperCase()}!',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Icono animado
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: rarityColor.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        // Icono principal
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              achievement.icon,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        // Sparkle effects
                        ...List.generate(8, (index) {
                          final angle = (index * 45) * 3.14159 / 180;
                          return Transform.translate(
                            offset: Offset(
                              40 * (angle.abs() > 1.5 ? -1 : 1) * (index % 2 == 0 ? 1 : 0.7),
                              40 * (angle.abs() < 1 ? -1 : 1) * (index % 2 == 0 ? 0.7 : 1),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Título del logro
                    Text(
                      achievement.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Descripción
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Recompensa XP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stars,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${achievement.xpReward} XP',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Indicador de cerrar
                    Text(
                      'Toca para cerrar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
