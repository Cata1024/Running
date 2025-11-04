import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import 'complete_onboarding_screen.dart';

// ==================== PASO 4: Peso ====================

class StepWeight extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepWeight({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<StepWeight> createState() => _StepWeightState();
}

class _StepWeightState extends ConsumerState<StepWeight> {
  late double _weight;

  @override
  void initState() {
    super.initState();
    // Inicializar con un valor por defecto
    _weight = 70.0;
    // Diferir la lectura del provider hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _weight = ref.read(onboardingDataProvider).weightKg;
      });
    });
  }

  void _handleNext() {
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.weightKg = _weight;
      });
      widget.onNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          Icon(
            Icons.monitor_weight_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '¿Cuál es tu peso actual?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Nos ayuda a calcular tus métricas de rendimiento',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Valor grande
          Text(
            '${_weight.toStringAsFixed(1)} kg',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Slider
          Slider(
            value: _weight,
            min: 30,
            max: 200,
            divisions: 170,
            label: '${_weight.toStringAsFixed(1)} kg',
            onChanged: (value) => setState(() => _weight = value),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30 kg', style: theme.textTheme.bodySmall),
              Text('200 kg', style: theme.textTheme.bodySmall),
            ],
          ),
          
          const SizedBox(height: 48),
          
          AeroButton(
            onPressed: _handleNext,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

// ==================== PASO 5: Altura ====================

class StepHeight extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepHeight({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<StepHeight> createState() => _StepHeightState();
}

class _StepHeightState extends ConsumerState<StepHeight> {
  late int _height;

  @override
  void initState() {
    super.initState();
    // Inicializar con un valor por defecto
    _height = 170;
    // Diferir la lectura del provider hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _height = ref.read(onboardingDataProvider).heightCm;
      });
    });
  }

  void _handleNext() {
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.heightCm = _height;
      });
      widget.onNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          Icon(
            Icons.height,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '¿Cuál es tu altura?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Para cálculos más precisos de tus métricas',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Valor grande
          Text(
            '$_height cm',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Slider
          Slider(
            value: _height.toDouble(),
            min: 100,
            max: 250,
            divisions: 150,
            label: '$_height cm',
            onChanged: (value) => setState(() => _height = value.round()),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('100 cm', style: theme.textTheme.bodySmall),
              Text('250 cm', style: theme.textTheme.bodySmall),
            ],
          ),
          
          const SizedBox(height: 48),
          
          AeroButton(
            onPressed: _handleNext,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

// ==================== PASO 6: Objetivo ====================

class StepGoal extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepGoal({super.key, required this.onNext, required this.onBack});

  void _selectGoal(BuildContext context, WidgetRef ref, String goal) {
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.goalType = goal;
      });
      onNext();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedGoal = ref.watch(onboardingDataProvider).goalType;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          Icon(
            Icons.flag_outlined,
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
            'Elige el que mejor te describa',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          _GoalOption(
            icon: Icons.fitness_center,
            label: 'Fitness General',
            description: 'Mantenerme activo y saludable',
            value: 'fitness',
            isSelected: selectedGoal == 'fitness',
            onTap: () => _selectGoal(context, ref, 'fitness'),
          ),
          
          const SizedBox(height: 16),
          
          _GoalOption(
            icon: Icons.trending_down,
            label: 'Perder Peso',
            description: 'Quemar calorías y adelgazar',
            value: 'weight_loss',
            isSelected: selectedGoal == 'weight_loss',
            onTap: () => _selectGoal(context, ref, 'weight_loss'),
          ),
          
          const SizedBox(height: 16),
          
          _GoalOption(
            icon: Icons.emoji_events,
            label: 'Competir',
            description: 'Prepararme para carreras',
            value: 'competition',
            isSelected: selectedGoal == 'competition',
            onTap: () => _selectGoal(context, ref, 'competition'),
          ),
          
          const SizedBox(height: 16),
          
          _GoalOption(
            icon: Icons.sentiment_satisfied_alt,
            label: 'Diversión',
            description: 'Disfrutar corriendo',
            value: 'fun',
            isSelected: selectedGoal == 'fun',
            onTap: () => _selectGoal(context, ref, 'fun'),
          ),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.isSelected,
    required this.onTap,
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== PASO 7: Meta Semanal ====================

class StepWeeklyGoal extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepWeeklyGoal({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<StepWeeklyGoal> createState() => _StepWeeklyGoalState();
}

class _StepWeeklyGoalState extends ConsumerState<StepWeeklyGoal> {
  late double _distance;
  late bool _isMetric;

  @override
  void initState() {
    super.initState();
    // Inicializar con valores por defecto
    _distance = 20.0;
    _isMetric = true;
    // Diferir la lectura del provider hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = ref.read(onboardingDataProvider);
      setState(() {
        _distance = data.weeklyDistanceGoal;
        _isMetric = data.preferredUnits == 'metric';
      });
    });
  }

  void _handleNext() {
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.weeklyDistanceGoal = _distance;
        data.preferredUnits = _isMetric ? 'metric' : 'imperial';
      });
      widget.onNext();
    });
  }

  String get _unit => _isMetric ? 'km' : 'mi';
  double get _displayDistance => _isMetric ? _distance : _distance * 0.621371;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          Icon(
            Icons.directions_run,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '¿Cuánto quieres correr?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Meta semanal recomendada',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Valor grande
          Text(
            '${_displayDistance.toStringAsFixed(0)} $_unit',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          
          Text(
            'por semana',
            style: theme.textTheme.bodyLarge,
          ),
          
          const SizedBox(height: 32),
          
          // Slider
          Slider(
            value: _distance,
            min: 5,
            max: 100,
            divisions: 95,
            label: '${_displayDistance.toStringAsFixed(0)} $_unit',
            onChanged: (value) => setState(() => _distance = value),
          ),
          
          const SizedBox(height: 32),
          
          // Toggle de unidades
          AeroCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _UnitButton(
                    label: 'Kilómetros',
                    isSelected: _isMetric,
                    onTap: () => setState(() => _isMetric = true),
                  ),
                  _UnitButton(
                    label: 'Millas',
                    isSelected: !_isMetric,
                    onTap: () => setState(() => _isMetric = false),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          AeroButton(
            onPressed: _handleNext,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

class _UnitButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected
                ? Colors.white
                : theme.textTheme.titleSmall?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ==================== PASO 8: Descripción ====================

class StepDescription extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepDescription({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<StepDescription> createState() => _StepDescriptionState();
}

class _StepDescriptionState extends ConsumerState<StepDescription> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Diferir la lectura del provider hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _descriptionController.text = ref.read(onboardingDataProvider).goalDescription ?? '';
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final description = _descriptionController.text.trim();
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (description.isNotEmpty) {
        ref.read(onboardingDataProvider.notifier).updateField((data) {
          data.goalDescription = description;
        });
      }
      widget.onNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = ref.watch(onboardingDataProvider).displayName;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          Icon(
            Icons.psychology_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '¡Casi listo, $name!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '¿Algo más que quieras compartir?',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          AeroTextField(
            controller: _descriptionController,
            label: 'Cuéntanos tu historia (opcional)',
            hint: 'Ej: Quiero prepararme para un maratón en 6 meses',
            maxLines: 5,
            textInputAction: TextInputAction.done,
          ),
          
          const SizedBox(height: 32),
          
          AeroButton(
            onPressed: _handleNext,
            child: const Text('Ver Resumen'),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: _handleNext,
            child: const Text('Omitir'),
          ),
        ],
      ),
    );
  }
}
