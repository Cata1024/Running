import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_profile_dto.dart';
import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';

/// Sección de información personal del perfil
/// Muestra datos del onboarding: edad, género, peso, altura, objetivo
class PersonalInfoSection extends ConsumerWidget {
  final UserProfileDto? profile;
  
  const PersonalInfoSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    if (profile == null) {
      return const SizedBox.shrink();
    }
    
    // Extraer datos
    // Manejar birthDate que puede venir como Timestamp (Firestore) o DateTime
    DateTime? birthDate = profile!.birthDate;
    
    final gender = profile!.gender;
    final weightKg = profile!.weightKg;
    final heightCm = profile!.heightCm;
    final goalType = profile!.goalType;
    final weeklyDistanceGoal = profile!.weeklyDistanceGoal;
    
    // Si no hay datos personales, no mostrar la sección
    if (birthDate == null && gender == null && weightKg == null && 
        heightCm == null && goalType == null) {
      return const SizedBox.shrink();
    }
    
    final age = birthDate != null ? _calculateAge(birthDate) : null;
    final bmi = _calculateBMI(weightKg, heightCm);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header con botón de editar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Información Personal',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: TerritoryTokens.space16),
        
        // Cards de información
        AeroCard(
          child: Padding(
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            child: Column(
              children: [
                // Fila 1: Edad y Género
                if (age != null || gender != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TerritoryTokens.space16),
                    child: Row(
                      children: [
                        if (age != null)
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.cake_outlined,
                              label: 'Edad',
                              value: '$age años',
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        if (age != null && gender != null)
                          const SizedBox(width: TerritoryTokens.space12),
                        if (gender != null)
                          Expanded(
                            child: _InfoItem(
                              icon: _getGenderIcon(gender),
                              label: 'Género',
                              value: _getGenderLabel(gender),
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Fila 2: Peso y Altura
                if (weightKg != null || heightCm != null)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: (goalType != null || weeklyDistanceGoal != null)
                          ? TerritoryTokens.space16
                          : 0,
                    ),
                    child: Row(
                      children: [
                        if (weightKg != null)
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.monitor_weight_outlined,
                              label: 'Peso',
                              value: '${weightKg.toStringAsFixed(1)} kg',
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        if (weightKg != null && heightCm != null)
                          const SizedBox(width: TerritoryTokens.space12),
                        if (heightCm != null)
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.height,
                              label: 'Altura',
                              value: '$heightCm cm',
                              color: Colors.purple,
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Fila 3: Objetivo y Meta
                if (goalType != null || weeklyDistanceGoal != null)
                  Row(
                    children: [
                      if (goalType != null)
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.flag_outlined,
                            label: 'Objetivo',
                            value: _getGoalLabel(goalType),
                            color: Colors.orange,
                          ),
                        ),
                      if (goalType != null && weeklyDistanceGoal != null)
                        const SizedBox(width: TerritoryTokens.space12),
                      if (weeklyDistanceGoal != null)
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.track_changes,
                            label: 'Meta semanal',
                            value: '${weeklyDistanceGoal.toStringAsFixed(0)} km',
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                
                // BMI si está disponible
                if (bmi != null) ...[
                  const SizedBox(height: TerritoryTokens.space16),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: TerritoryTokens.space16),
                  
                  _BMIIndicator(bmi: bmi),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
  
  double? _calculateBMI(double? weightKg, int? heightCm) {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.person_outline;
    }
  }
  
  String _getGenderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Masculino';
      case 'female':
        return 'Femenino';
      case 'other':
        return 'Otro';
      case 'prefer_not_say':
        return 'Prefiero no decir';
      default:
        return gender;
    }
  }
  
  String _getGoalLabel(String goalType) {
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
        return goalType;
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(TerritoryTokens.space12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BMIIndicator extends StatelessWidget {
  final double bmi;
  
  const _BMIIndicator({required this.bmi});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String category;
    Color color;
    
    if (bmi < 18.5) {
      category = 'Bajo peso';
      color = Colors.blue;
    } else if (bmi < 25) {
      category = 'Normal';
      color = Colors.green;
    } else if (bmi < 30) {
      category = 'Sobrepeso';
      color = Colors.orange;
    } else {
      category = 'Obesidad';
      color = Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  'Índice de Masa Corporal (IMC)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              bmi.toStringAsFixed(1),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'kg/m²',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra de rango IMC
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Fondo con gradiente de rangos
                Row(
                  children: [
                    Expanded(
                      flex: 185,
                      child: Container(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    Expanded(
                      flex: 250 - 185,
                      child: Container(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    Expanded(
                      flex: 300 - 250,
                      child: Container(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    Expanded(
                      flex: 400 - 300,
                      child: Container(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
                // Indicador de posición actual
                FractionallySizedBox(
                  widthFactor: (bmi.clamp(15, 40) - 15) / (40 - 15),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 3,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
