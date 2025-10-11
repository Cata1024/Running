import 'package:flutter/material.dart';

import '../providers/run_state_provider.dart';
import '../../../shared/utils/format_utils.dart';

class HomeMetricsBar extends StatelessWidget {
  final RunState runState;

  const HomeMetricsBar({super.key, required this.runState});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricChip(
          icon: Icons.timer,
          value: FormatUtils.duration(runState.elapsed),
          label: 'Tiempo',
        ),
        _MetricChip(
          icon: Icons.straighten,
          value: FormatUtils.distanceKm(runState.distance, fractionDigits: 2),
          label: 'Distancia',
        ),
        _MetricChip(
          icon: Icons.speed,
          value: runState.averagePace > 0
              ? FormatUtils.paceMinutesPerKm(runState.averagePace)
              : '--:--',
          label: 'Ritmo',
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
