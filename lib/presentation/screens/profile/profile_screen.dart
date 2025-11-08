import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shimmer/shimmer.dart";

import '../../../core/design_system/territory_tokens.dart';
import '../../../core/responsive/responsive_builder.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../providers/app_providers.dart';
import '../../providers/territory_provider.dart';
import 'widgets/profile_view_model.dart';
import 'widgets/profile_header.dart';
import 'widgets/level_section.dart';
import 'widgets/main_stats_section.dart';
import 'widgets/goal_section.dart';
import 'widgets/territory_section.dart';
import 'widgets/profile_actions_section.dart';
import 'widgets/recent_runs_section.dart';
import 'widgets/achievements_section.dart';
import 'widgets/personal_info_section.dart';

/// ProfileScreen refactorizado con widgets modulares y shimmer loading
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin<ProfileScreen> {
  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshProfile() async {
    // Invalidar los providers para forzar recarga
    ref.invalidate(userProfileDtoProvider);
    ref.invalidate(territoryUseCaseProvider);
    ref.invalidate(userTerritoryProvider);
    ref.invalidate(userRunsDtoProvider);

    // Esperar a que se complete la recarga
    await Future.wait([
      ref.read(userProfileDtoProvider.future),
      ref.read(userTerritoryProvider.future),
      ref.read(userRunsDtoProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profileAsync = ref.watch(userProfileDtoProvider);
    final territoryAsync = ref.watch(userTerritoryProvider);
    final runsAsync = ref.watch(userRunsDtoProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);
    final theme = Theme.of(context);
    final navBarHeight = ref.watch(navBarHeightProvider);
    final navBarClearance = navBarHeight > TerritoryTokens.space16
        ? navBarHeight - TerritoryTokens.space16
        : navBarHeight;

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
            child: profileAsync.when(
              data: (profileDto) {
                final viewModel = ProfileViewModel.fromDto(
                  dto: profileDto,
                  fallbackName: currentUser?.displayName,
                  fallbackEmail: currentUser?.email,
                  fallbackPhotoUrl: currentUser?.photoURL,
                );

                return RefreshIndicator(
                  onRefresh: _refreshProfile,
                  edgeOffset: 0,
                  displacement: 40,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: ResponsiveContainer(
                          mobileMaxWidth: double.infinity,
                          tabletMaxWidth: 720,
                          desktopMaxWidth: 960,
                          padding: TerritoryTokens.getAdaptivePadding(context),
                          child: StaggeredColumn(
                            staggerDelay: const Duration(milliseconds: 100),
                            itemDuration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProfileHeader(profile: viewModel),
                              const SizedBox(height: TerritoryTokens.space24),
                              LevelSection(profile: viewModel),
                              const SizedBox(height: TerritoryTokens.space24),
                              MainStatsSection(profile: viewModel),
                              const SizedBox(height: TerritoryTokens.space24),
                              const AchievementsSection(),
                              const SizedBox(height: TerritoryTokens.space24),
                              PersonalInfoSection(profile: profileDto),
                              if (viewModel.goalDescription != null &&
                                  viewModel.goalDescription!.isNotEmpty) ...[
                                const SizedBox(height: TerritoryTokens.space24),
                                GoalSection(goal: viewModel.goalDescription!),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: ResponsiveContainer(
                          mobileMaxWidth: double.infinity,
                          tabletMaxWidth: 720,
                          desktopMaxWidth: 960,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                TerritoryTokens.getAdaptivePadding(context)
                                    .left,
                          ),
                          child:
                              TerritorySection(territoryAsync: territoryAsync),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: ResponsiveContainer(
                          mobileMaxWidth: double.infinity,
                          tabletMaxWidth: 720,
                          desktopMaxWidth: 960,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                TerritoryTokens.getAdaptivePadding(context)
                                    .left,
                            vertical: TerritoryTokens.space16,
                          ),
                          child: RecentRunsSection(runsAsync: runsAsync),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: ResponsiveContainer(
                          mobileMaxWidth: double.infinity,
                          tabletMaxWidth: 720,
                          desktopMaxWidth: 960,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                TerritoryTokens.getAdaptivePadding(context)
                                    .left,
                          ),
                          child: const ProfileActionsSection(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: navBarClearance + TerritoryTokens.space24,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => _ProfileShimmer(navBarClearance: navBarClearance),
              error: (error, _) => Center(
                child: Text(
                  "Error al cargar perfil\n$error",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  final double navBarClearance;

  const _ProfileShimmer({required this.navBarClearance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ResponsiveContainer(
            mobileMaxWidth: double.infinity,
            tabletMaxWidth: 720,
            desktopMaxWidth: 960,
            padding: TerritoryTokens.getAdaptivePadding(context),
            child: Shimmer.fromColors(
              baseColor: theme.colorScheme.surfaceContainerHighest,
              highlightColor: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header shimmer
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: TerritoryTokens.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 24,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: TerritoryTokens.space8),
                            Container(
                              height: 16,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TerritoryTokens.space24),
                  const LevelSectionShimmer(),
                  const SizedBox(height: TerritoryTokens.space24),
                  const MainStatsSectionShimmer(),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: navBarClearance),
        ),
      ],
    );
  }
}
