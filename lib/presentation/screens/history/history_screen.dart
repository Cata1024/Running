import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import 'package:go_router/go_router.dart';
// run_detail_screen.dart is routed via GoRouter; no direct import needed here

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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(historyFilterProvider);
    final filterNotifier = ref.read(historyFilterProvider.notifier);
    
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
                    value: '12',
                    icon: Icons.directions_run,
                  ),
                  _StatItem(
                    label: 'Distancia Total',
                    value: '85.4 km',
                    icon: Icons.route,
                  ),
                  _StatItem(
                    label: 'Tiempo Total',
                    value: '8:42:15',
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
              child: Builder(
                builder: (context) {
                  final user = ref.watch(currentFirebaseUserProvider);
                  if (user == null) {
                    return const Center(child: Text('Inicia sesión'));
                  }
                  // Consulta completa con filtros (requiere índice compuesto)
                  Query<Map<String, dynamic>> q = FirebaseFirestore.instance
                      .collection('runs')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('startedAt', descending: true);
                  
                  // Aplicar filtros opcionales
                  if (filter.onlyClosed) {
                    q = q.where('isClosedCircuit', isEqualTo: true);
                  }
                  if (filter.start != null) {
                    q = q.where('startedAt', isGreaterThanOrEqualTo: filter.start!.toIso8601String());
                  }
                  if (filter.end != null) {
                    q = q.where('startedAt', isLessThanOrEqualTo: filter.end!.toIso8601String());
                  }
                  
                  q = q.limit(50);
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: q.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        // Mostrar error completo con URL de índice
                        final errorStr = snapshot.error.toString();
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text('Error de Firestore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                SelectableText(
                                  errorStr,
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Copiar al portapapeles
                                    debugPrint('=== ERROR COMPLETO ===');
                                    debugPrint(errorStr);
                                    debugPrint('=====================');
                                  },
                                  icon: const Icon(Icons.bug_report),
                                  label: const Text('Ver en Consola'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('Sin carreras aún'));
                      }
                      var runs = docs.map((d) => {'id': d.id, ...d.data()}).toList();
                      
                      // Filtro de distancia en cliente (solo este, el resto en Firestore)
                      runs = runs.where((r) {
                        final km = ((r['distanceM'] as num?)?.toDouble() ?? 0.0) / 1000.0;
                        return km >= filter.minKm && km <= filter.maxKm;
                      }).toList();
                      return ListView.separated(
                        itemCount: runs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final run = runs[index];
                          return _RunCardFirestore(
                            run: run,
                            onTap: () => context.push('/history/detail', extra: run['id']),
                          );
                        },
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

class _RunCardFirestore extends StatelessWidget {
  final Map<String, dynamic> run;
  final VoidCallback onTap;
  const _RunCardFirestore({required this.run, required this.onTap});

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

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    month,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Run Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startedAt != null ? '${startedAt.year}-${startedAt.month.toString().padLeft(2,'0')}-${startedAt.day.toString().padLeft(2,'0')}' : 'Carrera',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(distanceM / 1000).toStringAsFixed(2)} km',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fmt(durationS),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ritmo: ${pace()} min/km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Button
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
