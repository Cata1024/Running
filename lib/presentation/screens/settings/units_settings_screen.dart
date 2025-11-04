import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../providers/settings_provider.dart';

class UnitsSettingsScreen extends ConsumerWidget {
  const UnitsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUnits = ref.watch(settingsProvider.select((s) => s.units));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        children: [
          // Explicación
          AeroSurface(
            level: AeroLevel.subtle,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
            child: Row(
              children: [
                Icon(
                  Icons.straighten,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: TerritoryTokens.space12),
                Expanded(
                  child: Text(
                    'Selecciona el sistema de unidades para distancias y velocidades',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Sistema Métrico
          _UnitsCard(
            icon: Icons.speed,
            title: 'Sistema Métrico',
            subtitle: 'Kilómetros, metros, kg',
            examples: const [
              'Distancia: 5.00 km',
              'Ritmo: 5:30 min/km',
              'Velocidad: 10.8 km/h',
            ],
            isSelected: currentUnits == 'metric',
            onTap: () => ref.read(settingsProvider.notifier).setUnits('metric'),
          ),
          const SizedBox(height: TerritoryTokens.space16),

          // Sistema Imperial
          _UnitsCard(
            icon: Icons.speed,
            title: 'Sistema Imperial',
            subtitle: 'Millas, pies, libras',
            examples: const [
              'Distancia: 3.11 mi',
              'Ritmo: 8:51 min/mi',
              'Velocidad: 6.7 mph',
            ],
            isSelected: currentUnits == 'imperial',
            onTap: () => ref.read(settingsProvider.notifier).setUnits('imperial'),
          ),
        ],
      ),
    );
  }
}

class _UnitsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> examples;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.examples,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
        ),
        child: AeroSurface(
          level: isSelected ? AeroLevel.medium : AeroLevel.subtle,
          padding: const EdgeInsets.all(TerritoryTokens.space20),
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: TerritoryTokens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: TerritoryTokens.space16),
              const Divider(height: 1),
              const SizedBox(height: TerritoryTokens.space12),
              Text(
                'Ejemplos:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TerritoryTokens.space8),
              ...examples.map((example) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_right,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          example,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
