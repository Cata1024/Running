import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../providers/settings_provider.dart';

class GpsSettingsScreen extends ConsumerWidget {
  const GpsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración GPS'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.gps_fixed,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: TerritoryTokens.space12),
                Expanded(
                  child: Text(
                    'Ajusta la precisión y frecuencia del GPS según tus necesidades. Mayor precisión consume más batería.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Precisión GPS
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space20),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precisión',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space8),
                Text(
                  _getAccuracyDescription(settings.gpsAccuracy),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'low',
                      label: Text('Baja'),
                      icon: Icon(Icons.battery_saver),
                    ),
                    ButtonSegment(
                      value: 'balanced',
                      label: Text('Equilibrada'),
                      icon: Icon(Icons.balance),
                    ),
                    ButtonSegment(
                      value: 'high',
                      label: Text('Alta'),
                      icon: Icon(Icons.my_location),
                    ),
                  ],
                  selected: {settings.gpsAccuracy},
                  onSelectionChanged: (Set<String> selection) {
                    ref.read(settingsProvider.notifier).setGpsAccuracy(selection.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Intervalo de actualización
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space20),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intervalo de actualización',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TerritoryTokens.space12,
                        vertical: TerritoryTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
                      ),
                      child: Text(
                        '${settings.gpsIntervalMs}ms',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TerritoryTokens.space8),
                Text(
                  '${(1000 / settings.gpsIntervalMs).toStringAsFixed(1)} actualizaciones por segundo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  ),
                  child: Slider(
                    value: settings.gpsIntervalMs.toDouble(),
                    min: 500,
                    max: 5000,
                    divisions: 18,
                    label: '${settings.gpsIntervalMs}ms',
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setGpsInterval(value.toInt());
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Más rápido',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Ahorro de batería',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Auto-pausa
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space20),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-pausa',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: TerritoryTokens.space4),
                          Text(
                            'Pausar automáticamente cuando te detienes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.autoPauseEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).toggleAutoPause(value);
                      },
                    ),
                  ],
                ),
                if (settings.autoPauseEnabled) ...[
                  const SizedBox(height: TerritoryTokens.space16),
                  const Divider(),
                  const SizedBox(height: TerritoryTokens.space16),
                  Text(
                    'Umbral de velocidad',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TerritoryTokens.space8),
                  Text(
                    'Pausar si la velocidad baja de ${settings.autoPauseThresholdMs.toStringAsFixed(1)} m/s',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: TerritoryTokens.space12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: settings.autoPauseThresholdMs,
                      min: 0.2,
                      max: 2.0,
                      divisions: 18,
                      label: '${settings.autoPauseThresholdMs.toStringAsFixed(1)} m/s',
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).setAutoPauseThreshold(value);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space16),

          // Recomendaciones
          Padding(
            padding: const EdgeInsets.all(TerritoryTokens.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: TerritoryTokens.space8),
                    Text(
                      'Recomendaciones',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TerritoryTokens.space8),
                _buildRecommendation(
                  context,
                  'Para carreras urbanas usa precisión Alta (1000ms)',
                ),
                _buildRecommendation(
                  context,
                  'Para entrenamientos largos usa Equilibrada (2000ms)',
                ),
                _buildRecommendation(
                  context,
                  'Auto-pausa es útil en recorridos con semáforos',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getAccuracyDescription(String accuracy) {
    switch (accuracy) {
      case 'low':
        return 'Menor precisión, mayor ahorro de batería. Ideal para caminatas.';
      case 'balanced':
        return 'Equilibrio entre precisión y consumo. Recomendado para la mayoría.';
      case 'high':
        return 'Máxima precisión, mayor consumo de batería. Ideal para carreras.';
      default:
        return '';
    }
  }
}
