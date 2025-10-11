import 'package:flutter/material.dart';

import '../../../shared/utils/format_utils.dart';

class ProfileStatsGrid extends StatelessWidget {
  final int totalRuns;
  final double totalDistance;
  final int totalTime;
  final double averagePace;
  final double averageSpeed;

  const ProfileStatsGrid({
    super.key,
    required this.totalRuns,
    required this.totalDistance,
    required this.totalTime,
    required this.averagePace,
    required this.averageSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _ProfileStat(icon: Icons.directions_run, label: 'Carreras', value: '$totalRuns'),
      _ProfileStat(
        icon: Icons.route,
        label: 'Distancia',
        value: FormatUtils.distanceKm(totalDistance, fractionDigits: 1),
      ),
      _ProfileStat(
        icon: Icons.timelapse,
        label: 'Tiempo',
        value: FormatUtils.durationFromSeconds(totalTime),
      ),
      _ProfileStat(
        icon: Icons.speed,
        label: 'Ritmo prom',
        value: averagePace > 0 ? FormatUtils.paceMinutesPerKm(averagePace) : '--:--',
      ),
      _ProfileStat(
        icon: Icons.flash_on,
        label: 'Velocidad prom',
        value: averageSpeed > 0 ? FormatUtils.speedKmPerHour(averageSpeed) : '--',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: items
          .map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(item.icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.value,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProfileStat {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileStat({required this.icon, required this.label, required this.value});
}
