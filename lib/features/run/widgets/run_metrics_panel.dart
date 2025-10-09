import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../home.dart';
import 'glass_panel.dart';

class RunMetricsPanel extends StatelessWidget {
  final RunState runState;

  const RunMetricsPanel({super.key, required this.runState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            runState.isRunning ? 'Sesión activa' : 'Listo para correr',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PrimaryMetric(
                label: 'Distancia',
                value: '${runState.distance.toStringAsFixed(2)} km',
                accent: colorScheme.primary,
              ),
              _PrimaryMetric(
                label: 'Tiempo',
                value: _formatDuration(runState.elapsed),
                accent: colorScheme.secondary,
              ),
              _PrimaryMetric(
                label: 'Ritmo',
                value: runState.averagePace > 0
                    ? '${runState.averagePace.toStringAsFixed(1)} min/km'
                    : '--:--',
                accent: colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SecondaryMetrics(runState: runState),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _PrimaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _PrimaryMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: textTheme.labelSmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryMetrics extends StatelessWidget {
  final RunState runState;

  const _SecondaryMetrics({required this.runState});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        _SecondaryMetricChip(
          icon: Icons.flag_outlined,
          label: 'Circuito',
          value: runState.isCircuitClosed ? 'Cerrado' : 'Abierto',
        ),
        const SizedBox(width: 12),
        _SecondaryMetricChip(
          icon: Icons.speed,
          label: 'Velocidad',
          value: runState.distance > 0 && runState.elapsed.inSeconds > 0
              ? '${(runState.distance / (runState.elapsed.inSeconds / 3600)).toStringAsFixed(1)} km/h'
              : '--',
        ),
        const SizedBox(width: 12),
        _SecondaryMetricChip(
          icon: Icons.local_fire_department_outlined,
          label: 'Calorías',
          value: '${runState.calories}',
        ),
      ],
    );
  }
}

class _SecondaryMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SecondaryMetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
