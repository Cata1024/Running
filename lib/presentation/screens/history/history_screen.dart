// history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart'; // agregar dependencia shimmer en pubspec.yaml

import '../../../core/design_system/territory_tokens.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../core/utils/debouncer.dart';
import '../../providers/app_providers.dart'; // contiene userRunsProvider y historyFilterProvider

class _HistorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

final historySearchQueryProvider =
    NotifierProvider<_HistorySearchQueryNotifier, String>(
  _HistorySearchQueryNotifier.new,
);

/// Archivo refactorizado y optimizado de HistoryScreen
/// - RunUtils: helpers reutilizables
/// - filteredRunsProvider: computa filtrado y orden fuera del build
/// - shimmer placeholders, AnimatedSwitcher, Hero, MiniMap modal

/// ---------- Helpers / Utils ----------
class RunUtils {
  RunUtils._();

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Rango de fechas';
    if (start != null && end == null) return formatDate(start);
    if (start == null && end != null) return formatDate(end);
    return '${formatDate(start!)} - ${formatDate(end!)}';
  }

  static String formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return hours == '00' ? '$minutes:$secs' : '$hours:$minutes:$secs';
  }

  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatPace(double distanceM, int durationS) {
    if (distanceM <= 0 || durationS <= 0) return '--:--';
    final km = distanceM / 1000;
    final secPerKm = durationS / km;
    final m = (secPerKm / 60).floor();
    final s = (secPerKm % 60).round().toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatWeekday(DateTime date) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }

  static Map<String, dynamic> summarize(List<Map<String, dynamic>> runs) {
    double totalDistanceKm = 0;
    int totalTime = 0;
    for (final run in runs) {
      totalDistanceKm +=
          ((run['distanceM'] as num?)?.toDouble() ?? 0.0) / 1000.0;
      totalTime += (run['durationS'] as num?)?.toInt() ?? 0;
    }
    return {
      'totalRuns': runs.length,
      'totalDistanceKm': totalDistanceKm,
      'totalTime': totalTime,
    };
  }

  /// Devuelve el índice de la mejor carrera según ritmo (min/km más bajo).
  static int? bestRunIndexByPace(List<Map<String, dynamic>> runs) {
    double bestPace = double.infinity;
    int? idx;
    for (var i = 0; i < runs.length; i++) {
      final distanceM = (runs[i]['distanceM'] as num?)?.toDouble() ?? 0.0;
      final durationS = (runs[i]['durationS'] as num?)?.toInt() ?? 0;
      if (distanceM <= 0 || durationS <= 0) continue;
      final pace = (durationS) / (distanceM / 1000.0);
      if (pace < bestPace) {
        bestPace = pace;
        idx = i;
      }
    }
    return idx;
  }
}

/// ---------- Header widgets ----------
class _MiniStatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _MiniStatCard extends StatelessWidget {
  final _MiniStatItem item;

  const _MiniStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
          color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TerritoryTokens.space12,
            vertical: TerritoryTokens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: item.color, size: 24),
              const SizedBox(height: TerritoryTokens.space8),
              Text(
                item.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TerritoryTokens.space4),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _QuickStatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRuns = summary['totalRuns'] as int?;
    final totalDistanceKm = summary['totalDistanceKm'] as double?;
    final totalTime = summary['totalTime'] as int?;

    final items = [
      _MiniStatItem(
        icon: Icons.flag_rounded,
        label: 'Carreras',
        value: totalRuns?.toString() ?? '--',
        color: theme.colorScheme.primary,
      ),
      _MiniStatItem(
        icon: Icons.route_rounded,
        label: 'Kilómetros',
        value:
            totalDistanceKm == null ? '--' : totalDistanceKm.toStringAsFixed(1),
        color: theme.colorScheme.tertiary,
      ),
      _MiniStatItem(
        icon: Icons.timer_rounded,
        label: 'Tiempo',
        value: totalTime == null ? '--:--' : RunUtils.formatDuration(totalTime),
        color: theme.colorScheme.secondary,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == items.length - 1 ? 0 : TerritoryTokens.space12,
              ),
              child: _MiniStatCard(item: items[i]),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TerritoryTokens.space12,
        vertical: TerritoryTokens.space8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: TerritoryTokens.space8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFilterBar extends ConsumerStatefulWidget {
  final HistoryFilter filter;
  final VoidCallback onOpenFilters;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _CompactFilterBar({
    required this.filter,
    required this.onOpenFilters,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  ConsumerState<_CompactFilterBar> createState() => _CompactFilterBarState();
}

class _CompactFilterBarState extends ConsumerState<_CompactFilterBar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final TextEditingController _searchController;
  late final Debouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchDebouncer = Debouncer(milliseconds: 300);
  }

  @override
  void didUpdateWidget(covariant _CompactFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(
          offset: widget.searchQuery.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = _buildFilterChips(widget.filter, theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: TerritoryTokens.space20,
              vertical: TerritoryTokens.space12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusXLarge),
              color: theme.colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: TerritoryTokens.space12),
                Expanded(
                  child: Text(
                    'Buscar / Filtrar',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: TerritoryTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    _searchDebouncer.run(() => widget.onSearchChanged(value));
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar carreras…',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TerritoryTokens.radiusLarge),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh
                        .withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space12),
                Wrap(
                  spacing: TerritoryTokens.space8,
                  runSpacing: TerritoryTokens.space8,
                  children: chips,
                ),
                const SizedBox(height: TerritoryTokens.space12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: widget.onOpenFilters,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Configurar filtros'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilterChips(HistoryFilter filter, ThemeData theme) {
    final chips = <Widget>[
      _SummaryChip(
        icon: Icons.route,
        label:
            '${filter.minKm.toStringAsFixed(0)} - ${filter.maxKm.toStringAsFixed(0)} km',
      ),
      if (filter.start != null || filter.end != null)
        _SummaryChip(
          icon: Icons.date_range,
          label: RunUtils.formatDateRange(filter.start, filter.end),
        ),
      if (filter.onlyClosed)
        _SummaryChip(
          icon: Icons.check_circle,
          label: 'Circuitos cerrados',
        ),
    ];

    if (chips.isEmpty) {
      return [
        Text(
          'Sin filtros activos',
          style: theme.textTheme.bodySmall,
        ),
      ];
    }

    return chips;
  }
}

class _FiltersSheet {
  static Future<void> show(
    BuildContext context, {
    required HistoryFilter filter,
    required ValueChanged<bool> onToggleClosed,
    required void Function(DateTime? start, DateTime? end) onPickDateRange,
    required ValueChanged<RangeValues> onRangeChanged,
    required VoidCallback onClear,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: FractionallySizedBox(
            heightFactor: 0.8,
            child: DraggableScrollableSheet(
              expand: false,
              builder: (context, controller) {
                return Padding(
                  padding: const EdgeInsets.all(TerritoryTokens.space16),
                  child: AeroSurface(
                    level: AeroLevel.medium,
                    borderRadius:
                        BorderRadius.circular(TerritoryTokens.radiusXLarge),
                    padding: const EdgeInsets.all(TerritoryTokens.space16),
                    child: ListView(
                      controller: controller,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(
                              top: TerritoryTokens.space8,
                              bottom: TerritoryTokens.space16,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Filtros de carreras',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: onClear,
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Restablecer filtros',
                            ),
                          ],
                        ),
                        const SizedBox(height: TerritoryTokens.space12),
                        _FiltersSection(
                          filter: filter,
                          onToggleClosed: onToggleClosed,
                          onPickDateRange: onPickDateRange,
                          onRangeChanged: onRangeChanged,
                          onClear: onClear,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// ---------- Computed provider: filtra y ordena runs ----------
class _FilteredRunsArgs {
  final HistoryFilter filter;
  final String query;

  const _FilteredRunsArgs({required this.filter, required this.query});
}

final _filteredRunsProvider = Provider.autoDispose
    .family<List<Map<String, dynamic>>, _FilteredRunsArgs>((ref, args) {
  final runsAsync = ref.watch(userRunsProvider);

  return runsAsync.maybeWhen(
    data: (runs) {
      final query = args.query.trim().toLowerCase();
      final filtered = runs.where((run) {
        final distanceKm =
            ((run['distanceM'] as num?)?.toDouble() ?? 0.0) / 1000.0;
        final filter = args.filter;
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
        if (query.isNotEmpty) {
          final title = (run['title'] as String?)?.toLowerCase() ?? '';
          final notes = (run['notes'] as String?)?.toLowerCase() ?? '';
          if (!title.contains(query) && !notes.contains(query)) {
            return false;
          }
        }
        return true;
      }).toList();

      filtered.sort((a, b) {
        final aDate = DateTime.tryParse(a['startedAt'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['startedAt'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return filtered;
    },
    orElse: () => [],
  );
});

/// ---------- Screen ----------
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with AutomaticKeepAliveClientMixin<HistoryScreen> {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  int _displayedRunsCount = 20; // Cargar 20 inicialmente
  static const int _batchSize = 10; // Cargar 10 más cada vez

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Cuando estamos al 80% del scroll, cargar más
      setState(() {
        _displayedRunsCount += _batchSize;
      });
    }
  }

  Future<void> _refreshRuns() async {
    // Invalidar provider para forzar recarga
    ref.invalidate(userRunsProvider);

    // Esperar a que se complete la recarga
    await ref.read(userRunsProvider.future);

    // Resetear el contador de runs mostrados
    if (mounted) {
      setState(() {
        _displayedRunsCount = 20;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final filter = ref.watch(historyFilterProvider);
    final filterNotifier = ref.read(historyFilterProvider.notifier);
    final runsAsync = ref.watch(userRunsProvider);
    final navBarHeight = ref.watch(navBarHeightProvider);
    final navBarClearance = navBarHeight > TerritoryTokens.space16
        ? navBarHeight - TerritoryTokens.space16
        : navBarHeight;

    // summary memoizado a partir del AsyncValue
    final summary = runsAsync.maybeWhen(
      data: (runs) => RunUtils.summarize(runs),
      orElse: () => {
        'totalRuns': null,
        'totalDistanceKm': null,
        'totalTime': null,
      },
    );

    final searchQuery = ref.watch(historySearchQueryProvider);
    final allFilteredRuns = ref.watch(
      _filteredRunsProvider(
        _FilteredRunsArgs(
          filter: filter,
          query: searchQuery,
        ),
      ),
    );

    // Lazy loading: limitar runs mostrados
    final filteredRuns = allFilteredRuns.take(_displayedRunsCount).toList();
    final hasMore = allFilteredRuns.length > _displayedRunsCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: AeroSurface.fullscreenBackground(
              theme: theme,
              startOpacity: 0.0,
              endOpacity: 0.035,
            ),
          ),
          SafeArea(
            bottom: true,
            child: RefreshIndicator(
              onRefresh: _refreshRuns,
              edgeOffset: 0,
              displacement: 40,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: ResponsiveContainer(
                      mobileMaxWidth: double.infinity,
                      tabletMaxWidth: 720,
                      desktopMaxWidth: 1200,
                      padding: TerritoryTokens.getAdaptivePadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Mi actividad',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: TerritoryTokens.space16),
                          _QuickStatsRow(summary: summary),
                          const SizedBox(height: TerritoryTokens.space24),
                          _CompactFilterBar(
                            filter: filter,
                            searchQuery: searchQuery,
                            onSearchChanged: (query) => ref
                                .read(historySearchQueryProvider.notifier)
                                .setQuery(query),
                            onOpenFilters: () => _FiltersSheet.show(
                              context,
                              filter: filter,
                              onToggleClosed: (value) =>
                                  filterNotifier.update(onlyClosed: value),
                              onPickDateRange: (start, end) =>
                                  filterNotifier.update(
                                start: start,
                                end: end,
                              ),
                              onRangeChanged: (range) => filterNotifier.update(
                                minKm: range.start,
                                maxKm: range.end,
                              ),
                              onClear: () => filterNotifier.reset(),
                            ),
                          ),
                          const SizedBox(height: TerritoryTokens.space24),
                        ],
                      ),
                    ),
                  ),

                  // Lista de runs (usa filteredRuns calculado)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TerritoryTokens.space16,
                    ),
                    sliver: runsAsync.when(
                      loading: () => SliverToBoxAdapter(
                        child: _RunsShimmerList(),
                      ),
                      error: (err, st) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: TerritoryTokens.space24),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: theme.colorScheme.error),
                              const SizedBox(height: TerritoryTokens.space16),
                              const Text('No se pudieron cargar las carreras'),
                              const SizedBox(height: TerritoryTokens.space12),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(userRunsProvider),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (_) {
                        if (filteredRuns.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Column(
                              children: [
                                EmptyState(
                                  icon: Icons.directions_run,
                                  title: 'Sin carreras aún',
                                  message:
                                      'Inicia tu primera carrera para ver tu historial aquí',
                                  actionLabel: 'Ir a Mapa',
                                  onAction: () =>
                                      DefaultTabController.of(context)
                                          .animateTo(1),
                                ),
                                const SizedBox(height: TerritoryTokens.space24),
                              ],
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final run = filteredRuns[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: TerritoryTokens.space16),
                                child: _RunCard(
                                  run: run,
                                  onTap: () => GoRouter.of(context).pushNamed(
                                      'run-detail',
                                      extra: run['id']),
                                ),
                              );
                            },
                            childCount: filteredRuns.length,
                          ),
                        );
                      },
                    ),
                  ),

                  // Loading indicator cuando hay más items
                  if (hasMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(TerritoryTokens.space16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: navBarClearance),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Filters ----------
class _FiltersSection extends StatelessWidget {
  final HistoryFilter filter;
  final ValueChanged<bool> onToggleClosed;
  final void Function(DateTime? start, DateTime? end) onPickDateRange;
  final ValueChanged<RangeValues> onRangeChanged;
  final VoidCallback onClear;

  const _FiltersSection({
    required this.filter,
    required this.onToggleClosed,
    required this.onPickDateRange,
    required this.onRangeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.medium,
      borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Filtros',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Restablecer filtros',
              ),
            ],
          ),
          const SizedBox(height: TerritoryTokens.space12),
          Wrap(
            spacing: TerritoryTokens.space8,
            runSpacing: TerritoryTokens.space8,
            children: [
              AeroFilterChip(
                label: 'Circuitos cerrados',
                icon: Icons.route,
                selected: filter.onlyClosed,
                onSelected: (_) => onToggleClosed(!filter.onlyClosed),
              ),
              ..._quickRangeChips(context, filter, onPickDateRange),
            ],
          ),
          const SizedBox(height: TerritoryTokens.space16),
          Text(
            'Rango de fechas',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TerritoryTokens.space8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(RunUtils.formatDateRange(filter.start, filter.end)),
              onPressed: () =>
                  _openDatePicker(context, filter, onPickDateRange),
            ),
          ),
          const SizedBox(height: TerritoryTokens.space16),
          Text(
            'Distancia objetivo',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${filter.minKm.toStringAsFixed(0)} - ${filter.maxKm.toStringAsFixed(0)} km',
            style: theme.textTheme.bodySmall,
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: RangeValues(filter.minKm, filter.maxKm),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onRangeChanged,
            ),
          ),
        ],
      ),
    );
  }

  static Iterable<Widget> _quickRangeChips(
    BuildContext context,
    HistoryFilter filter,
    void Function(DateTime? start, DateTime? end) onPickDateRange,
  ) {
    final now = DateTime.now();
    final todayEnd = _endOfDay(now);
    final options = <({String label, DateTimeRange range})>[
      (
        label: 'Últimos 7 días',
        range: DateTimeRange(
          start: _startOfDay(now.subtract(const Duration(days: 6))),
          end: todayEnd,
        ),
      ),
      (
        label: 'Últimos 30 días',
        range: DateTimeRange(
          start: _startOfDay(now.subtract(const Duration(days: 29))),
          end: todayEnd,
        ),
      ),
      (
        label: 'Este año',
        range: DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: todayEnd,
        ),
      ),
    ];

    final activeStart =
        filter.start != null ? _startOfDay(filter.start!) : null;
    final activeEnd = filter.end != null ? _endOfDay(filter.end!) : null;

    bool isActive(DateTimeRange range) {
      if (activeStart == null || activeEnd == null) return false;
      return activeStart.isAtSameMomentAs(range.start) &&
          activeEnd.isAtSameMomentAs(range.end);
    }

    return options.map((entry) {
      final selected = isActive(entry.range);
      return AeroFilterChip(
        label: entry.label,
        icon: Icons.calendar_today,
        selected: selected,
        onSelected: (_) {
          if (selected) {
            onPickDateRange(null, null);
          } else {
            onPickDateRange(entry.range.start, entry.range.end);
          }
        },
      );
    });
  }

  static Future<void> _openDatePicker(
    BuildContext context,
    HistoryFilter filter,
    void Function(DateTime? start, DateTime? end) onPickDateRange,
  ) async {
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: filter.start ?? now.subtract(const Duration(days: 30)),
      end: filter.end ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: _startOfDay(initial.start),
        end: _endOfDay(initial.end),
      ),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Selecciona un rango',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onPickDateRange(
        _startOfDay(picked.start),
        _endOfDay(picked.end),
      );
    }
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

/// ---------- Shimmer / placeholder ----------
class _RunsShimmerList extends StatelessWidget {
  const _RunsShimmerList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TerritoryTokens.space16),
      child: Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: TerritoryTokens.space12),
            child: Shimmer.fromColors(
              baseColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.25),
              highlightColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.05),
              child: AeroSurface(
                level: AeroLevel.subtle,
                borderRadius:
                    BorderRadius.circular(TerritoryTokens.radiusLarge),
                padding: const EdgeInsets.all(TerritoryTokens.space12),
                child: SizedBox(
                  height: 86,
                  child: Row(
                    children: [
                      Container(width: 70, height: 70, color: Colors.white),
                      const SizedBox(width: TerritoryTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 14, width: 120, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(
                                height: 12, width: 180, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(
                                height: 12, width: 80, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(width: TerritoryTokens.space8),
                      Container(width: 24, height: 24, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ---------- RunCard ----------
class _RunCard extends StatefulWidget {
  final Map<String, dynamic> run;
  final VoidCallback onTap;

  const _RunCard({required this.run, required this.onTap});

  @override
  State<_RunCard> createState() => _RunCardState();
}

class _RunCardState extends State<_RunCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final run = widget.run;

    final startedAtStr = run['startedAt'] as String?;
    DateTime? startedAt;
    if (startedAtStr != null) startedAt = DateTime.tryParse(startedAtStr);

    final distanceM = (run['distanceM'] as num?)?.toDouble() ?? 0.0;
    final durationS = (run['durationS'] as num?)?.toInt() ?? 0;
    final isClosedCircuit = run['isClosedCircuit'] == true;
    final routeGeoJson = run['routeGeoJson'] as Map<String, dynamic>?;
    final coordinates = routeGeoJson?['coordinates'] as List<dynamic>? ?? [];
    final heroTag = 'run-${run['id']}';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
          child: Hero(
            tag: heroTag,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius:
                    BorderRadius.circular(TerritoryTokens.radiusXLarge),
                border: Border.all(
                  color: _isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.35)
                      : theme.colorScheme.outline.withValues(alpha: 0.15),
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color:
                              theme.colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(TerritoryTokens.space16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showMapDialog(
                          context,
                          theme,
                          startedAt,
                          distanceM,
                          coordinates,
                        ),
                        child: AnimatedScale(
                          scale: _isHovered ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  TerritoryTokens.radiusLarge),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  TerritoryTokens.radiusLarge),
                              child: MiniMap(
                                routeCoordinates: coordinates,
                                width: 80,
                                height: 80,
                                borderRadius: 10,
                                enableZoom: true,
                                showRoutePolyline: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_isHovered)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  TerritoryTokens.radiusLarge),
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.zoom_in,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: TerritoryTokens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    startedAt != null
                                        ? '${RunUtils.formatWeekday(startedAt)} • ${RunUtils.formatDate(startedAt)} • ${RunUtils.formatTime(startedAt)}'
                                        : 'Fecha no disponible',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: TerritoryTokens.space4),
                                  Text(
                                    '${(distanceM / 1000).toStringAsFixed(2)} km',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isClosedCircuit) ...[
                          const SizedBox(height: TerritoryTokens.space4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TerritoryTokens.space8,
                              vertical: TerritoryTokens.space4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary
                                  .withValues(alpha: 0.12),
                              border: Border.all(
                                color: theme.colorScheme.tertiary
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(
                                  TerritoryTokens.radiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag,
                                  size: 14,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Territorio Conquistado',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: TerritoryTokens.space12),
                        Wrap(
                          spacing: TerritoryTokens.space8,
                          runSpacing: TerritoryTokens.space8,
                          children: [
                            _MetricChip(
                              icon: Icons.timer_outlined,
                              value: RunUtils.formatDuration(durationS),
                              theme: theme,
                            ),
                            _MetricChip(
                              icon: Icons.speed,
                              value:
                                  '${RunUtils.formatPace(distanceM, durationS)} min/km',
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isHovered ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMapDialog(
    BuildContext context,
    ThemeData theme,
    DateTime? startedAt,
    double distanceM,
    List<dynamic> coordinates,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(TerritoryTokens.space16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(TerritoryTokens.space16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          startedAt != null
                              ? '${RunUtils.formatDate(startedAt)} • ${(distanceM / 1000).toStringAsFixed(2)} km'
                              : '${(distanceM / 1000).toStringAsFixed(2)} km',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(TerritoryTokens.space16),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(TerritoryTokens.radiusLarge),
                      child: MiniMap(
                        routeCoordinates: coordinates,
                        enableZoom: true,
                        showRoutePolyline: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final ThemeData theme;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TerritoryTokens.space8,
        vertical: TerritoryTokens.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
