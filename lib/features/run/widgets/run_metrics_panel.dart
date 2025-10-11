import 'package:flutter/material.dart';

import '../../../shared/utils/format_utils.dart';
import 'glass_panel.dart';

class RunMetricsPanel extends StatelessWidget {
  final bool isRunning;
  final double distanceKm;
  final Duration elapsed;
  final double averagePace;
  final bool isCircuitClosed;
  final double? averageSpeedKmH;
  final int routePointCount;
  final bool dense;
  final bool showSecondary;

  const RunMetricsPanel({
    super.key,
    required this.isRunning,
    required this.distanceKm,
    required this.elapsed,
    required this.averagePace,
    required this.isCircuitClosed,
    this.averageSpeedKmH,
    required this.routePointCount,
    this.dense = false,
    this.showSecondary = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final EdgeInsetsGeometry padding = dense
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

    final String headerText = isRunning ? 'Sesión activa' : 'Listo para correr';
    final TextStyle? headerStyle = dense
        ? textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            letterSpacing: 0.4,
          )
        : textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            letterSpacing: 0.6,
          );

    final TextStyle? primaryValueStyle = dense
        ? textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          )
        : textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          );

    final TextStyle? primaryLabelStyle = dense
        ? textTheme.labelSmall?.copyWith(
            letterSpacing: 1.0,
            color: textTheme.labelSmall?.color?.withValues(alpha: 0.7),
          )
        : textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: textTheme.labelSmall?.color?.withValues(alpha: 0.7),
          );

    return GlassPanel(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headerText, style: headerStyle),
          SizedBox(height: dense ? 8 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PrimaryMetric(
                label: 'Distancia',
                value: FormatUtils.distanceKm(distanceKm),
                accent: colorScheme.primary,
                valueStyle: primaryValueStyle,
                labelStyle: primaryLabelStyle,
              ),
              _PrimaryMetric(
                label: 'Tiempo',
                value: FormatUtils.duration(elapsed),
                accent: colorScheme.secondary,
                valueStyle: primaryValueStyle,
                labelStyle: primaryLabelStyle,
              ),
              _PrimaryMetric(
                label: 'Ritmo',
                value: averagePace > 0
                    ? FormatUtils.paceMinutesPerKm(averagePace)
                    : '--:--',
                accent: colorScheme.tertiary,
                valueStyle: primaryValueStyle,
                labelStyle: primaryLabelStyle,
              ),
            ],
          ),
          if (showSecondary) ...[
            SizedBox(height: dense ? 12 : 16),
            _SecondaryMetrics(
              isCircuitClosed: isCircuitClosed,
              distanceKm: distanceKm,
              elapsed: elapsed,
              averageSpeedKmH: averageSpeedKmH,
              routePointCount: routePointCount,
              dense: dense,
            ),
          ],
        ],
      ),
    );
  }

}

class _PrimaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  const _PrimaryMetric({
    required this.label,
    required this.value,
    required this.accent,
    this.valueStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: valueStyle ??
              Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              style: labelStyle ??
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryMetrics extends StatelessWidget {
  final bool isCircuitClosed;
  final double distanceKm;
  final Duration elapsed;
  final double? averageSpeedKmH;
  final int routePointCount;
  final bool dense;

  const _SecondaryMetrics({
    required this.isCircuitClosed,
    required this.distanceKm,
    required this.elapsed,
    required this.averageSpeedKmH,
    required this.routePointCount,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final computedSpeed = averageSpeedKmH ??
        (distanceKm > 0 && elapsed.inSeconds > 0
            ? distanceKm / (elapsed.inSeconds / 3600)
            : null);

    return Row(
      children: [
        _SecondaryMetricChip(
          icon: Icons.flag_outlined,
          label: 'Circuito',
          value: isCircuitClosed ? 'Cerrado' : 'Abierto',
          dense: dense,
        ),
        const SizedBox(width: 12),
        _SecondaryMetricChip(
          icon: Icons.speed,
          label: 'Velocidad',
          value: computedSpeed != null
              ? FormatUtils.speedKmPerHour(computedSpeed)
              : '--',
          dense: dense,
        ),
        const SizedBox(width: 12),
        _SecondaryMetricChip(
          icon: Icons.timeline_outlined,
          label: 'Puntos',
          value: routePointCount.toString(),
          dense: dense,
        ),
      ],
    );
  }
}

class _SecondaryMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dense;

  const _SecondaryMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: dense ? 16 : 18, color: colorScheme.secondary),
            SizedBox(width: dense ? 6 : 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: dense
                      ? Theme.of(context).textTheme.labelMedium
                      : Theme.of(context).textTheme.labelLarge,
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
