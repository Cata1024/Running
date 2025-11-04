import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';

class RecentRunsSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> runsAsync;

  const RecentRunsSection({super.key, required this.runsAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return runsAsync.when(
      data: (runs) {
        final sortedRuns = List<Map<String, dynamic>>.from(runs);
        sortedRuns.sort((a, b) {
          final aDate = _parseRunDate(a);
          final bDate = _parseRunDate(b);

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return bDate.compareTo(aDate);
        });
        final recent = sortedRuns.take(3).toList();

        if (recent.isEmpty) {
          return AeroSurface(
            level: AeroLevel.subtle,
            padding: const EdgeInsets.all(TerritoryTokens.space24),
            child: Text(
              'Sin carreras recientes',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: TerritoryTokens.space12,
              ),
              child: Text(
                'Carreras recientes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...recent.map(
              (run) => Padding(
                padding: const EdgeInsets.only(
                  bottom: TerritoryTokens.space8,
                ),
                child: AeroSurface(
                  level: AeroLevel.ghost,
                  enableBlur: false,
                  padding: const EdgeInsets.all(TerritoryTokens.space12),
                  onTap: () {
                    final id = run['id'] as String?;
                    if (id != null && id.isNotEmpty) {
                      context.go('/history/detail', extra: id);
                    }
                  },
                  child: _RunSummaryTile(run: run),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AeroSurface(
        level: AeroLevel.subtle,
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        child: Text(
          'Error al cargar carreras recientes',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  DateTime? _parseRunDate(Map<String, dynamic> run) {
    final startAtRaw =
        (run['startedAt'] as String?) ?? (run['startAt'] as String?);
    if (startAtRaw == null) return null;
    return DateTime.tryParse(startAtRaw);
  }
}

class _RunSummaryTile extends StatelessWidget {
  final Map<String, dynamic> run;

  const _RunSummaryTile({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _resolveRunData(run);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TerritoryTokens.space4),
              Text(
                data.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: TerritoryTokens.space16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${data.distanceKm} km',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TerritoryTokens.space4),
            Text(
              data.pace,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _RunSummaryData _resolveRunData(Map<String, dynamic> run) {
    final title = _resolveRunTitle(run);
    final startedAt = _parseRunDate(run);

    final distanceKm = _resolveDistanceKm(run);
    final paceValue = _resolvePaceSeconds(run, distanceKm);
    final pace = paceValue != null ? _formatPace(paceValue) : '--:--';

    return _RunSummaryData(
      title: title,
      subtitle:
          startedAt != null ? _formatDate(startedAt) : 'Fecha desconocida',
      distanceKm: distanceKm.toStringAsFixed(2),
      pace: pace,
    );
  }

  String _resolveRunTitle(Map<String, dynamic> run) {
    final explicitTitle = run['title'] as String?;
    if (explicitTitle != null && explicitTitle.trim().isNotEmpty) {
      return explicitTitle;
    }

    final terrain = (run['conditions'] as Map<String, dynamic>?)?['terrain'];
    if (terrain is String && terrain.trim().isNotEmpty) {
      return terrain;
    }

    return 'Carrera';
  }

  double _resolveDistanceKm(Map<String, dynamic> run) {
    final distanceKm = (run['distanceKm'] as num?)?.toDouble();
    if (distanceKm != null && distanceKm > 0) {
      return distanceKm;
    }

    final distanceM = (run['distanceM'] as num?)?.toDouble();
    if (distanceM != null && distanceM > 0) {
      return distanceM / 1000;
    }

    final metrics = run['metrics'] as Map<String, dynamic>?;
    final metricsDistance = (metrics?['distanceKm'] as num?)?.toDouble();
    return metricsDistance ?? 0.0;
  }

  double? _resolvePaceSeconds(Map<String, dynamic> run, double distanceKm) {
    final paceStr = run['pace'] as String?;
    if (paceStr != null && paceStr.contains(':')) {
      final parts = paceStr.split(':');
      if (parts.length >= 2) {
        final minutes = int.tryParse(parts[0]);
        final seconds = int.tryParse(parts[1]);
        if (minutes != null && seconds != null) {
          return (minutes * 60 + seconds).toDouble();
        }
      }
    }

    final avgPaceSecPerKm = (run['avgPaceSecPerKm'] as num?)?.toDouble();
    if (avgPaceSecPerKm != null && avgPaceSecPerKm > 0) {
      return avgPaceSecPerKm;
    }

    final metrics = run['metrics'] as Map<String, dynamic>?;
    final metricsPace = (metrics?['paceSecPerKm'] as num?)?.toDouble();
    if (metricsPace != null && metricsPace > 0) {
      return metricsPace;
    }

    final durationSeconds = (run['durationS'] as num?)?.toDouble();
    if (durationSeconds != null && durationSeconds > 0 && distanceKm > 0) {
      return durationSeconds / distanceKm;
    }

    final metricsDuration = (metrics?['movingTimeS'] as num?)?.toDouble();
    if (metricsDuration != null && metricsDuration > 0 && distanceKm > 0) {
      return metricsDuration / distanceKm;
    }

    return null;
  }

  String _formatPace(double paceSeconds) {
    final minutes = paceSeconds ~/ 60;
    final seconds = (paceSeconds % 60).round();
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    return '$minutes:$paddedSeconds';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  DateTime? _parseRunDate(Map<String, dynamic> run) {
    final startAtRaw =
        (run['startedAt'] as String?) ?? (run['startAt'] as String?);
    if (startAtRaw == null) return null;
    return DateTime.tryParse(startAtRaw);
  }
}

class _RunSummaryData {
  final String title;
  final String subtitle;
  final String distanceKm;
  final String pace;

  const _RunSummaryData({
    required this.title,
    required this.subtitle,
    required this.distanceKm,
    required this.pace,
  });
}
