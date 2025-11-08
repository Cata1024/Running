import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:running/domain/entities/achievement.dart';
import 'package:running/domain/entities/run.dart';

import '../../application/achievements/achievements_use_case.dart';
import 'app_providers.dart';

/// Carga el caso de uso de logros para el usuario actual.
final achievementsUseCaseProvider =
    FutureProvider.autoDispose<AchievementsUseCase>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) {
    throw StateError('Usuario no autenticado');
  }

  final repository = ref.watch(achievementsRepositoryProvider);
  final useCase = AchievementsUseCase(
    userId: user.uid,
    repository: repository,
  );
  await useCase.initialize();
  return useCase;
});

List<Achievement> _guardAchievements(List<Achievement> achievements) =>
    List<Achievement>.unmodifiable(achievements);

List<AchievementCategory> _guardCategories(List<AchievementCategory> categories) =>
    List<AchievementCategory>.unmodifiable(categories);

final userAchievementsProvider = Provider.autoDispose<List<Achievement>>((ref) {
  final asyncUseCase = ref.watch(achievementsUseCaseProvider);
  return asyncUseCase.maybeWhen(
    data: (useCase) => _guardAchievements(useCase.getUserAchievements()),
    orElse: () => const <Achievement>[],
  );
});

final achievementsByCategoryProvider = Provider.autoDispose<List<AchievementCategory>>((ref) {
  final asyncUseCase = ref.watch(achievementsUseCaseProvider);
  return asyncUseCase.maybeWhen(
    data: (useCase) => _guardCategories(useCase.getAchievementsByCategory()),
    orElse: () => const <AchievementCategory>[],
  );
});

final unlockedAchievementsProvider = Provider.autoDispose<List<Achievement>>((ref) {
  final asyncUseCase = ref.watch(achievementsUseCaseProvider);
  return asyncUseCase.maybeWhen(
    data: (useCase) => _guardAchievements(useCase.getUnlockedAchievements()),
    orElse: () => const <Achievement>[],
  );
});

final nearCompletionAchievementsProvider = Provider.autoDispose<List<Achievement>>((ref) {
  final asyncUseCase = ref.watch(achievementsUseCaseProvider);
  return asyncUseCase.maybeWhen(
    data: (useCase) =>
        _guardAchievements(useCase.getNearCompletionAchievements()),
    orElse: () => const <Achievement>[],
  );
});

class AchievementsStats {
  final int totalXp;
  final int unlockedCount;
  final int totalCount;
  final double completionPercentage;

  const AchievementsStats({
    required this.totalXp,
    required this.unlockedCount,
    required this.totalCount,
    required this.completionPercentage,
  });

  factory AchievementsStats.empty() => const AchievementsStats(
        totalXp: 0,
        unlockedCount: 0,
        totalCount: 0,
        completionPercentage: 0,
      );

  String get completionText => '${(completionPercentage * 100).toInt()}%';
  String get progressText => '$unlockedCount/$totalCount';
}

final achievementsStatsProvider = Provider.autoDispose<AchievementsStats>((ref) {
  final asyncUseCase = ref.watch(achievementsUseCaseProvider);
  return asyncUseCase.maybeWhen(
    data: (useCase) => AchievementsStats(
      totalXp: useCase.getTotalXp(),
      unlockedCount: useCase.getUnlockedCount(),
      totalCount: useCase.getUserAchievements().length,
      completionPercentage: useCase.getCompletionPercentage(),
    ),
    orElse: AchievementsStats.empty,
  );
});

final achievementNotificationProvider = NotifierProvider.autoDispose<
  AchievementNotificationNotifier,
  Achievement?
>(AchievementNotificationNotifier.new);

class AchievementNotificationNotifier extends Notifier<Achievement?> {
  Timer? _timer;

  @override
  Achievement? build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return null;
  }

  void show(Achievement achievement) {
    state = achievement;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), hideAchievement);
  }

  void hideAchievement() {
    state = null;
  }
}

void showAchievement(Ref ref, Achievement achievement) {
  ref.read(achievementNotificationProvider.notifier).show(achievement);
}

Future<void> processRunAchievements(Ref ref, Run run) async {
  final useCase = await ref.read(achievementsUseCaseProvider.future);
  final newAchievements = await useCase.processRunForAchievements(run);
  for (final achievement in newAchievements) {
    showAchievement(ref, achievement);
  }
  if (newAchievements.isNotEmpty) {
    ref.invalidate(achievementsUseCaseProvider);
  }
}

Future<void> unlockSocialAchievement(Ref ref, String achievementId) async {
  final useCase = await ref.read(achievementsUseCaseProvider.future);
  final achievement = await useCase.unlockSocialAchievement(achievementId);
  if (achievement != null) {
    showAchievement(ref, achievement);
    ref.invalidate(achievementsUseCaseProvider);
  }
}
