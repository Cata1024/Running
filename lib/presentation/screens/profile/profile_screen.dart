import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";

import "../../../core/design_system/territory_tokens.dart";
import "../../../core/widgets/aero_button.dart";
import "../../../core/widgets/aero_surface.dart";
import "../../providers/app_providers.dart";

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileDocProvider);
    final territoryAsync = ref.watch(userTerritoryDocProvider);
    final runsAsync = ref.watch(userRunsProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: profileAsync.when(
          data: (profileData) {
            final viewModel = _ProfileViewModel.fromSources(
              data: profileData,
              fallbackName: currentUser?.displayName,
              fallbackEmail: currentUser?.email,
              fallbackPhotoUrl: currentUser?.photoURL,
            );

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(TerritoryTokens.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(profile: viewModel),
                        const SizedBox(height: TerritoryTokens.space24),
                        _LevelSection(profile: viewModel),
                        const SizedBox(height: TerritoryTokens.space24),
                        _MainStatsSection(profile: viewModel),
                        if (viewModel.goalDescription != null &&
                            viewModel.goalDescription!.isNotEmpty) ...[
                          const SizedBox(height: TerritoryTokens.space16),
                          _GoalSection(goal: viewModel.goalDescription!),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TerritoryTokens.space16,
                    ),
                    child: _TerritorySection(territoryAsync: territoryAsync),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TerritoryTokens.space16,
                      vertical: TerritoryTokens.space16,
                    ),
                    child: _RecentRunsSection(runsAsync: runsAsync),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TerritoryTokens.space16,
                    ),
                    child: const _ActionsSection(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: TerritoryTokens.space48),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              "Error al cargar perfil\n$error",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final _ProfileViewModel profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(photoUrl: profile.photoUrl, initials: profile.initials),
        const SizedBox(width: TerritoryTokens.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (profile.email != null && profile.email!.isNotEmpty) ...[
                const SizedBox(height: TerritoryTokens.space4),
                Text(
                  profile.email!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (profile.lastActivityAt != null) ...[
                const SizedBox(height: TerritoryTokens.space8),
                Text(
                  "Última actividad: ${_formatDate(profile.lastActivityAt!)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _LevelSection extends StatelessWidget {
  final _ProfileViewModel profile;

  const _LevelSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = profile.levelProgress.clamp(0.0, 1.0);

    return AeroSurface(
      level: AeroLevel.medium,
      padding: const EdgeInsets.all(TerritoryTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Nivel ${profile.level}",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: TerritoryTokens.space16),
          ClipRRect(
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: TerritoryTokens.space12),
          Text(
            "${(progress * 100).round()}% al siguiente nivel",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainStatsSection extends StatelessWidget {
  final _ProfileViewModel profile;

  const _MainStatsSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = <_StatTile>[
      _StatTile(
        icon: Icons.directions_run,
        value: profile.totalRuns.toString(),
        label: 'Carreras',
      ),
      _StatTile(
        icon: Icons.social_distance,
        value: profile.totalDistanceKm.toStringAsFixed(1),
        label: 'Kilómetros',
      ),
      _StatTile(
        icon: Icons.timer_outlined,
        value: _formatDuration(profile.totalTimeSeconds),
        label: 'Tiempo total',
      ),
      if (profile.streak > 0)
        _StatTile(
          icon: Icons.local_fire_department,
          value: profile.streak.toString(),
          label: 'Racha',
        ),
    ];

    return AeroSurface(
      level: AeroLevel.subtle,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 420;

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats
                  .map(
                    (tile) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TerritoryTokens.space8,
                        ),
                        child: tile,
                      ),
                    ),
                  )
                  .toList(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                stats[i],
                if (i != stats.length - 1)
                  const Divider(height: TerritoryTokens.space24),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GoalSection extends StatelessWidget {
  final String goal;

  const _GoalSection({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.ghost,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objetivo personal',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TerritoryTokens.space8),
          Text(
            goal,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: TerritoryTokens.space8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TerritoryTokens.space4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TerritorySection extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> territoryAsync;

  const _TerritorySection({required this.territoryAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.subtle,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: territoryAsync.when(
        data: (doc) {
          final areaKm2 = doc?['totalAreaM2'] != null
              ? (doc!['totalAreaM2'] as num) / 1e6
              : 0.0;
          final sectors = (doc?['tilesClaimed'] as num?)?.toInt() ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.terrain, color: theme.colorScheme.tertiary),
                  const SizedBox(width: TerritoryTokens.space8),
                  Text(
                    'Territorio conquistado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TerritoryTokens.space12),
              Text(
                areaKm2 > 0
                    ? 'Cobertura aprox. de ${areaKm2.toStringAsFixed(2)} km²'
                    : 'Aún no has conquistado territorio',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (sectors > 0) ...[
                const SizedBox(height: TerritoryTokens.space8),
                Text(
                  'Sectores capturados: $sectors',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Text(
          'No se pudo cargar el territorio',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RecentRunsSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> runsAsync;

  const _RecentRunsSection({required this.runsAsync});

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
      subtitle: startedAt != null ? _formatDate(startedAt) : 'Fecha desconocida',
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

class _ActionsSection extends ConsumerWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authService = ref.read(authServiceProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final mapType = ref.watch(mapTypeProvider);
    final mapTypeNotifier = ref.read(mapTypeProvider.notifier);

    final editBackground = theme.colorScheme.primary.withValues(alpha: 0.9);
    final editForeground = theme.colorScheme.onPrimary;

    final logoutBackground = theme.colorScheme.error.withValues(alpha: 0.9);
    final logoutForeground = theme.colorScheme.onError;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + TerritoryTokens.space16,
      ),
      child: AeroSurface(
        level: AeroLevel.subtle,
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AeroButton(
                    onPressed: () => context.push('/profile/complete'),
                    isOutlined: true,
                    backgroundColor: editBackground,
                    child: IconTheme(
                      data: IconThemeData(color: editForeground),
                      child: DefaultTextStyle.merge(
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: editForeground,
                          fontWeight: FontWeight.w600,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: TerritoryTokens.space8),
                            Text('Editar perfil'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TerritoryTokens.space12),
            Wrap(
              spacing: TerritoryTokens.space12,
              runSpacing: TerritoryTokens.space12,
              alignment: WrapAlignment.center,
              children: MapType.values.map((type) {
                final isSelected = type == mapType;
                final background = isSelected
                    ? theme.colorScheme.secondary.withValues(alpha: 0.9)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6);
                final foreground = isSelected
                    ? theme.colorScheme.onSecondary
                    : theme.colorScheme.onSurface;

                return SizedBox(
                  width: 120,
                  child: AeroButton(
                    onPressed: () => mapTypeNotifier.setMapType(type),
                    isOutlined: true,
                    backgroundColor: background,
                    child: DefaultTextStyle.merge(
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                      child: IconTheme(
                        data: IconThemeData(color: foreground),
                        child: _MapTypeLabel(type: type),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: TerritoryTokens.space12),
            AeroButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Seguro que quieres cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await authService.signOut();
                }
              },
              isOutlined: true,
              backgroundColor: logoutBackground,
              child: IconTheme(
                data: IconThemeData(color: logoutForeground),
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: logoutForeground,
                    fontWeight: FontWeight.w600,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: TerritoryTokens.space8),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;

  const _Avatar({required this.photoUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 36,
      backgroundColor: theme.colorScheme.primary,
      backgroundImage:
          photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
              initials,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _ProfileViewModel {
  final String displayName;
  final String? email;
  final String initials;
  final String? photoUrl;
  final int totalRuns;
  final double totalDistanceKm;
  final int totalTimeSeconds;
  final int streak;
  final int level;
  final double levelProgress;
  final double experience;
  final double? currentLevelExperience;
  final double? nextLevelExperience;
  final DateTime? lastActivityAt;
  final String? goalDescription;

  const _ProfileViewModel({
    required this.displayName,
    required this.email,
    required this.initials,
    required this.photoUrl,
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.totalTimeSeconds,
    required this.streak,
    required this.level,
    required this.levelProgress,
    required this.experience,
    required this.currentLevelExperience,
    required this.nextLevelExperience,
    required this.lastActivityAt,
    required this.goalDescription,
  });

  factory _ProfileViewModel.fromSources({
    required Map<String, dynamic>? data,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackPhotoUrl,
  }) {
    final displayName =
        (data?['displayName'] as String?) ?? fallbackName ?? 'Runner';
    final email = (data?['email'] as String?) ?? fallbackEmail;
    final photoUrl = (data?['photoUrl'] as String?) ?? fallbackPhotoUrl;
    final totalRuns = (data?['totalRuns'] as num?)?.toInt() ?? 0;
    final totalDistance = (data?['totalDistance'] as num?)?.toDouble() ?? 0.0;
    final totalTime = (data?['totalTime'] as num?)?.toInt() ?? 0;
    final streak = (data?['currentStreak'] as num?)?.toInt() ?? 0;
    final level = (data?['level'] as num?)?.toInt() ?? 1;
    final experience = (data?['experience'] as num?)?.toDouble() ?? 0.0;
    final currentLevelExperience =
        (data?['currentLevelExperience'] as num?)?.toDouble();
    final nextLevelExperience =
        (data?['nextLevelExperience'] as num?)?.toDouble();
    final providedProgress = (data?['levelProgress'] as num?)?.toDouble();
    final lastActivityRaw = data?['lastActivityAt'] as String?;
    final goalDescription = data?['goalDescription'] as String?;

    DateTime? lastActivityAt;
    if (lastActivityRaw != null) {
      lastActivityAt = DateTime.tryParse(lastActivityRaw);
    }

    return _ProfileViewModel(
      displayName: displayName,
      email: email,
      initials: _deriveInitials(displayName),
      photoUrl: photoUrl,
      totalRuns: totalRuns,
      totalDistanceKm: totalDistance,
      totalTimeSeconds: totalTime,
      streak: streak,
      level: level,
      levelProgress: providedProgress ??
          _computeLevelProgress(
            level: level,
            experience: experience,
            currentLevelExperience: currentLevelExperience,
            nextLevelExperience: nextLevelExperience,
          ),
      experience: experience,
      currentLevelExperience: currentLevelExperience,
      nextLevelExperience: nextLevelExperience,
      lastActivityAt: lastActivityAt,
      goalDescription: goalDescription,
    );
  }

  static double _computeLevelProgress({
    required int level,
    required double experience,
    double? currentLevelExperience,
    double? nextLevelExperience,
  }) {
    if (level <= 0) return 0;

    final lowerBound = currentLevelExperience ?? _defaultCurrentThreshold(level);
    final upperBound = nextLevelExperience ?? _defaultNextThreshold(level);
    final span = (upperBound - lowerBound).clamp(1, double.infinity);
    final normalized = (experience - lowerBound) / span;
    return normalized.clamp(0, 1);
  }

  static double _defaultCurrentThreshold(int level) {
    if (level <= 1) return 0;
    return (level - 1) * 1000.0;
  }

  static double _defaultNextThreshold(int level) {
    if (level <= 0) return 1000.0;
    return level * 1000.0;
  }

  static String _deriveInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return (first + last).toUpperCase();
  }
}

class _MapTypeLabel extends StatelessWidget {
  final MapType type;

  const _MapTypeLabel({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(type);
    final icon = _iconFor(type);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: TerritoryTokens.space8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _labelFor(MapType type) {
    switch (type) {
      case MapType.normal:
        return 'Estándar';
      case MapType.satellite:
        return 'Satélite';
      case MapType.terrain:
        return 'Terreno';
      case MapType.hybrid:
        return 'Híbrido';
      case MapType.none:
        return 'Sin mapa';
    }
  }

  IconData _iconFor(MapType type) {
    switch (type) {
      case MapType.normal:
        return Icons.map_outlined;
      case MapType.satellite:
        return Icons.satellite_alt_outlined;
      case MapType.terrain:
        return Icons.terrain_outlined;
      case MapType.hybrid:
        return Icons.layers_outlined;
      case MapType.none:
        return Icons.grid_off_outlined;
    }
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  return '$day/$month/$year';
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '--:--';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  final minuteString = minutes.toString().padLeft(2, '0');
  final secondString = secs.toString().padLeft(2, '0');

  if (hours > 0) {
    final hourString = hours.toString().padLeft(2, '0');
    return '$hourString:$minuteString:$secondString';
  }

  return '$minuteString:$secondString';
}

DateTime? _parseRunDate(Map<String, dynamic> run) {
  final startAtRaw =
      (run['startedAt'] as String?) ?? (run['startAt'] as String?);
  if (startAtRaw == null) return null;
  return DateTime.tryParse(startAtRaw);
}
