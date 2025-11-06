import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import 'complete_onboarding_screen.dart';

// ==================== PASO 3: Objetivo ====================

class Step3Goal extends ConsumerWidget {
  final VoidCallback? onNext;
  
  const Step3Goal({super.key, this.onNext});

  void _selectGoal(BuildContext context, WidgetRef ref, String goal) {
    HapticFeedback.mediumImpact();
    
    // Guardar objetivo
    ref.read(onboardingDataProvider.notifier).updateField((data) {
      data.goalType = goal;
      
      // Asignar meta semanal automática según objetivo
      switch (goal) {
        case 'fitness':
          data.weeklyDistanceGoal = 15.0; // 15km para fitness general
          break;
        case 'weight_loss':
          data.weeklyDistanceGoal = 25.0; // 25km para perder peso
          break;
        case 'competition':
          data.weeklyDistanceGoal = 35.0; // 35km para competir
          break;
        case 'fun':
          data.weeklyDistanceGoal = 10.0; // 10km para diversión
          break;
        default:
          data.weeklyDistanceGoal = 20.0; // Por defecto
      }
    });
    
    // Navegar al siguiente paso
    onNext?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedGoal = ref.watch(onboardingDataProvider).goalType;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '¿Cuál es tu objetivo?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Personalizaremos tu experiencia',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          _GoalCard(
            icon: Icons.fitness_center,
            title: 'Fitness General',
            description: 'Mantenerme activo y saludable',
            weeklyGoal: '~15 km/semana',
            value: 'fitness',
            isSelected: selectedGoal == 'fitness',
            onTap: () => _selectGoal(context, ref, 'fitness'),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _GoalCard(
            icon: Icons.trending_down,
            title: 'Perder Peso',
            description: 'Quemar calorías y adelgazar',
            weeklyGoal: '~25 km/semana',
            value: 'weight_loss',
            isSelected: selectedGoal == 'weight_loss',
            onTap: () => _selectGoal(context, ref, 'weight_loss'),
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade600,
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _GoalCard(
            icon: Icons.emoji_events,
            title: 'Competir',
            description: 'Prepararme para carreras',
            weeklyGoal: '~35 km/semana',
            value: 'competition',
            isSelected: selectedGoal == 'competition',
            onTap: () => _selectGoal(context, ref, 'competition'),
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade400,
                Colors.purple.shade600,
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _GoalCard(
            icon: Icons.sentiment_satisfied_alt,
            title: 'Diversión',
            description: 'Disfrutar corriendo sin presión',
            weeklyGoal: '~10 km/semana',
            value: 'fun',
            isSelected: selectedGoal == 'fun',
            onTap: () => _selectGoal(context, ref, 'fun'),
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade600,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String weeklyGoal;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final Gradient gradient;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.weeklyGoal,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AeroCard(
      level: isSelected ? AeroLevel.medium : AeroLevel.ghost,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
              )
            : null,
        child: Row(
          children: [
            // Icono con gradiente
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : theme.iconTheme.color,
              ),
            ),
            const SizedBox(width: 16),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      weeklyGoal,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== PASO 4: ¡Listo! ====================

class Step4Ready extends ConsumerWidget {
  final VoidCallback? onComplete;
  
  const Step4Ready({super.key, this.onComplete});

  void _handleStart(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();
    
    // Navegar para completar el registro
    onComplete?.call();
  }

  String _getGoalEmoji(String goalType) {
    switch (goalType) {
      case 'fitness':
        return '💪';
      case 'weight_loss':
        return '🔥';
      case 'competition':
        return '🏆';
      case 'fun':
        return '🎉';
      default:
        return '🚀';
    }
  }

  String _getGoalName(String goalType) {
    switch (goalType) {
      case 'fitness':
        return 'Fitness General';
      case 'weight_loss':
        return 'Perder Peso';
      case 'competition':
        return 'Competir';
      case 'fun':
        return 'Diversión';
      default:
        return 'Tu objetivo';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(onboardingDataProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          // Confetti animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '¡Todo listo!',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Tu perfil ha sido configurado',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Resumen visual
          AeroCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Nombre y edad
                  _SummaryItem(
                    icon: Icons.person_outline,
                    label: 'Perfil',
                    value: data.displayName,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  
                  // Objetivo
                  _SummaryItem(
                    icon: Icons.flag_outlined,
                    label: 'Objetivo',
                    value: '${_getGoalEmoji(data.goalType)} ${_getGoalName(data.goalType)}',
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  
                  // Meta semanal
                  _SummaryItem(
                    icon: Icons.directions_run,
                    label: 'Meta semanal',
                    value: '${data.weeklyDistanceGoal.toStringAsFixed(0)} km',
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  
                  // Stats físicas
                  Row(
                    children: [
                      Expanded(
                        child: _CompactStat(
                          icon: Icons.monitor_weight_outlined,
                          value: '${data.weightKg.toStringAsFixed(0)} kg',
                          label: 'Peso',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactStat(
                          icon: Icons.height,
                          value: '${data.heightCm} cm',
                          label: 'Altura',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Info sobre logros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistema de logros desbloqueado',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '32 logros te esperan. ¡Comienza a correr para desbloquearlos!',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          AeroButton(
            onPressed: () => _handleStart(context, ref),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('¡Comenzar mi primera carrera!'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Puedes editar estos datos después en tu perfil',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CompactStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

