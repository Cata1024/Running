import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/aero_widgets.dart';
import '../../../domain/entities/achievement.dart';
import '../../providers/achievements_provider.dart';
import 'widgets/achievement_card.dart';

/// Pantalla principal de logros
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initState = ref.watch(achievementsUseCaseProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.brightness == Brightness.light
                  ? const Color(0xFFF8FAFB)
                  : const Color(0xFF0A0A0A),
              theme.brightness == Brightness.light
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFF0F1F0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, theme),
              initState.when(
                data: (_) => Expanded(
                  child: Column(
                    children: [
                      _buildStatsHeader(theme),
                      _buildTabBar(theme),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCategoriesView(theme),
                            _buildAllAchievementsView(theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const Expanded(
                  child: Center(child: LoadingState()),
                ),
                error: (error, _) => Expanded(
                  child: Center(
                    child: ErrorState(
                      message: 'Error cargando logros',
                      onRetry: () =>
                          ref.refresh(achievementsUseCaseProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '🏆 Logros',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    final stats = ref.watch(achievementsStatsProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      child: AeroCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    theme,
                    icon: Icons.emoji_events,
                    label: 'Desbloqueados',
                    value: stats.progressText,
                    color: theme.colorScheme.primary,
                  ),
                  _buildStatItem(
                    theme,
                    icon: Icons.stars,
                    label: 'XP Total',
                    value: stats.totalXp.toString(),
                    color: Colors.amber,
                  ),
                  _buildStatItem(
                    theme,
                    icon: Icons.trending_up,
                    label: 'Progreso',
                    value: stats.completionText,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de progreso general
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso General',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stats.progressText,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: stats.completionPercentage,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Por Categoría'),
          Tab(text: 'Todos'),
        ],
      ),
    );
  }

  Widget _buildCategoriesView(ThemeData theme) {
    final categories = ref.watch(achievementsByCategoryProvider);

    return Column(
      children: [
        // Selector de categorías
        Container(
          height: 120,
          margin: const EdgeInsets.only(top: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategoryIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 70 : 60,
                        height: isSelected ? 70 : 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : theme.colorScheme.surface
                                  .withValues(alpha: 0.8),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category.icon,
                            style: TextStyle(fontSize: isSelected ? 32 : 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${category.unlockedAchievements}/${category.totalAchievements}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Lista de logros de la categoría seleccionada
        Expanded(
          child: categories.isEmpty
              ? const Center(child: Text('No hay logros disponibles'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount:
                      categories[_selectedCategoryIndex].achievements.length,
                  itemBuilder: (context, index) {
                    final achievement =
                        categories[_selectedCategoryIndex].achievements[index];
                    return AchievementCard(
                      achievement: achievement,
                      onTap: () =>
                          _showAchievementDetails(context, achievement),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAllAchievementsView(ThemeData theme) {
    final achievements = ref.watch(userAchievementsProvider);
    final nearCompletion = ref.watch(nearCompletionAchievementsProvider);
    final unlocked = ref.watch(unlockedAchievementsProvider);
    final locked = achievements.where((a) => !a.isUnlocked).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Logros cercanos a completar
        if (nearCompletion.isNotEmpty) ...[
          _buildSectionHeader(
              theme, '🔥 Casi lo logras', nearCompletion.length),
          ...nearCompletion.map((achievement) => AchievementCard(
                achievement: achievement,
                onTap: () => _showAchievementDetails(context, achievement),
              )),
        ],

        // Logros desbloqueados
        if (unlocked.isNotEmpty) ...[
          _buildSectionHeader(theme, '✅ Desbloqueados', unlocked.length),
          ...unlocked.map((achievement) => AchievementCard(
                achievement: achievement,
                onTap: () => _showAchievementDetails(context, achievement),
              )),
        ],

        // Logros bloqueados
        if (locked.isNotEmpty) ...[
          _buildSectionHeader(theme, '🔒 Por desbloquear', locked.length),
          ...locked.where((a) => !a.isNearCompletion).map(
                (achievement) => AchievementCard(
                  achievement: achievement,
                  onTap: () => _showAchievementDetails(context, achievement),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AeroBottomSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono grande
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: achievement.isUnlocked
                      ? LinearGradient(
                          colors: [
                            Color(int.parse(achievement.rarityColor
                                    .replaceAll('#', '0xFF')))
                                .withValues(alpha: 0.3),
                            Color(int.parse(achievement.rarityColor
                                    .replaceAll('#', '0xFF')))
                                .withValues(alpha: 0.1),
                          ],
                        )
                      : null,
                  color: achievement.isUnlocked
                      ? null
                      : Colors.grey.withValues(alpha: 0.2),
                  border: Border.all(
                    color: achievement.isUnlocked
                        ? Color(int.parse(
                            achievement.rarityColor.replaceAll('#', '0xFF')))
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Información
              Text(
                achievement.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Estadísticas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDetailChip(
                    context,
                    achievement.rarityName,
                    Color(int.parse(
                        achievement.rarityColor.replaceAll('#', '0xFF'))),
                  ),
                  const SizedBox(width: 12),
                  _buildDetailChip(
                    context,
                    '${achievement.xpReward} XP',
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),

              // Progreso o fecha de desbloqueo
              if (!achievement.isUnlocked) ...[
                const SizedBox(height: 24),
                Column(
                  children: [
                    Text(
                      'Progreso: ${achievement.currentValue}/${achievement.requiredValue}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ] else if (achievement.unlockedAt != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Desbloqueado el ${_formatDate(achievement.unlockedAt!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón cerrar
              AeroButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
