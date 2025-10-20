import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/mini_map.dart';
import '../../providers/app_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Rango de fechas';
    if (start != null && end == null) return _formatDate(start);
    if (start == null && end != null) return _formatDate(end);
    return '${_formatDate(start!)} - ${_formatDate(end!)}';
  }

  String _formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(historyFilterProvider);
    final filterNotifier = ref.read(historyFilterProvider.notifier);
    
    final runsAsync = ref.watch(userRunsProvider);

    final summary = runsAsync.when<Map<String, dynamic>>(
      loading: () => const {
        'totalRuns': null,
        'totalDistanceKm': null,
        'totalTime': null,
      },
      error: (_, __) => const {
        'totalRuns': null,
        'totalDistanceKm': null,
        'totalTime': null,
      },
      data: (runs) {
        int totalRuns = runs.length;
        double totalDistanceKm = 0;
        int totalTime = 0;
        for (final run in runs) {
          totalDistanceKm +=
              ((run['distanceM'] as num?)?.toDouble() ?? 0.0) / 1000.0;
          totalTime += (run['durationS'] as num?)?.toInt() ?? 0;
        }
        return {
          'totalRuns': totalRuns,
          'totalDistanceKm': totalDistanceKm,
          'totalTime': totalTime,
        };
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        centerTitle: true,
      ),
      body: Padding(
        padding: AppTheme.paddingMedium,
        child: Column(
          children: [
            // Stats Summary
            GlassContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: 'Total Carreras',
                    value: summary['totalRuns'] == null
                        ? '--'
                        : summary['totalRuns'].toString(),
                    icon: Icons.directions_run,
                  ),
                  _StatItem(
                    label: 'Distancia Total',
                    value: summary['totalDistanceKm'] == null
                        ? '--'
                        : '${(summary['totalDistanceKm'] as double).toStringAsFixed(1)} km',
                    icon: Icons.route,
                  ),
                  _StatItem(
                    label: 'Tiempo Total',
                    value: summary['totalTime'] == null
                        ? '--:--'
                        : _formatDuration(summary['totalTime'] as int),
                    icon: Icons.timer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Filters
            Row(
              children: [
                Text(
                  'Mis Carreras',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text('Circuitos cerrados'),
                    Switch(
                      value: filter.onlyClosed,
                      onChanged: (v) => filterNotifier.update(onlyClosed: v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Controles de filtros: Fecha y Distancia
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_formatDateRange(filter.start, filter.end)),
                    onPressed: () async {
                      final now = DateTime.now();
                      final DateTimeRange initial = DateTimeRange(
                        start: filter.start ?? now.subtract(const Duration(days: 30)),
                        end: filter.end ?? now,
                      );
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: initial,
                        builder: (context, child) => Theme(data: theme, child: child!),
                      );
                      if (picked != null) {
                        // Normalizamos end al final del día
                        final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
                        filterNotifier.update(start: picked.start, end: end);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distancia: ${filter.minKm.toStringAsFixed(0)} - ${filter.maxKm.toStringAsFixed(0)} km', style: theme.textTheme.bodySmall),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(showValueIndicator: ShowValueIndicator.never),
                        child: RangeSlider(
                          values: RangeValues(filter.minKm, filter.maxKm),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: (r) => filterNotifier.update(minKm: r.start, maxKm: r.end),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Run List (Firestore con filtros)
            Expanded(
              child: runsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudieron cargar las carreras',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(userRunsProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (runs) {
                  final filtered = runs.where((run) {
                    final distanceKm =
                        ((run['distanceM'] as num?)?.toDouble() ?? 0.0) / 1000.0;
                    if (distanceKm < filter.minKm || distanceKm > filter.maxKm) {
                      return false;
                    }

                    if (filter.onlyClosed && run['isClosedCircuit'] != true) {
                      return false;
                    }

                    final startedAtStr = run['startedAt'] as String?;
                    final startedAt =
                        startedAtStr != null ? DateTime.tryParse(startedAtStr) : null;
                    if (filter.start != null && startedAt != null) {
                      if (startedAt.isBefore(filter.start!)) return false;
                    }
                    if (filter.end != null && startedAt != null) {
                      if (startedAt.isAfter(filter.end!)) return false;
                    }

                    return true;
                  }).toList();

                  filtered.sort((a, b) {
                    final aDate =
                        DateTime.tryParse(a['startedAt'] ?? '') ?? DateTime(1970);
                    final bDate =
                        DateTime.tryParse(b['startedAt'] ?? '') ?? DateTime(1970);
                    return bDate.compareTo(aDate);
                  });

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.directions_run,
                      title: 'Sin carreras aún',
                      message: 'Inicia tu primera carrera para ver tu historial aquí',
                      actionLabel: 'Ir a Mapa',
                      onAction: () {
                        DefaultTabController.of(context).animateTo(1);
                      },
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final run = filtered[index];
                      return _RunCard(
                        run: run,
                        onTap: () => GoRouter.of(context)
                            .pushNamed('run-detail', extra: run['id']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RunCard extends StatelessWidget {
  final Map<String, dynamic> run;
  final VoidCallback onTap;
  const _RunCard({required this.run, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startedAtStr = run['startedAt'] as String?;
    DateTime? startedAt;
    if (startedAtStr != null) {
      startedAt = DateTime.tryParse(startedAtStr);
    }
    final day = startedAt != null ? startedAt.day.toString().padLeft(2, '0') : '--';
    const months = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];
    final month = startedAt != null ? months[startedAt.month - 1] : '--';
    final distanceM = (run['distanceM'] as num?)?.toDouble() ?? 0.0;
    final durationS = (run['durationS'] as num?)?.toInt() ?? 0;

    String fmt(int s) {
      final h = (s ~/ 3600).toString().padLeft(2, '0');
      final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
      final sec = (s % 60).toString().padLeft(2, '0');
      return h == '00' ? '$m:$sec' : '$h:$m:$sec';
    }
    String pace() {
      if (distanceM <= 0 || durationS <= 0) return '--:--';
      final km = distanceM / 1000;
      final sec = durationS / km;
      final m = (sec / 60).floor();
      final s = (sec % 60).round().toString().padLeft(2, '0');
      return '$m:$s';
    }

    final isClosedCircuit = run['isClosedCircuit'] == true;
    final routeGeoJson = run['routeGeoJson'] as Map<String, dynamic>?;
    final coordinates = routeGeoJson?['coordinates'] as List<dynamic>? ?? [];

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Mini Map
            MiniMap(
              routeCoordinates: coordinates,
              width: 70,
              height: 70,
              borderRadius: 10,
            ),
            const SizedBox(width: 12),
            
            // Run Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$day $month',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isClosedCircuit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: AppTheme.successColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Circuito',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(distanceM / 1000).toStringAsFixed(2)} km',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fmt(durationS),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pace()} min/km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Button
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
