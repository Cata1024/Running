import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/run.dart';
import '../../domain/services/achievements_service.dart';
import 'app_providers.dart';

/// Provider del servicio de logros
final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  
  final user = authState.when(
    data: (u) => u,
    loading: () => null,
    error: (_, __) => null,
  );
  
  if (user == null) {
    throw Exception('Usuario no autenticado');
  }
  
  return AchievementsService(
    firestore: FirebaseFirestore.instance,
    userId: user.uid,
  );
});

/// Estado de inicialización del servicio de logros
final achievementsInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(achievementsServiceProvider);
  await service.initialize();
});

/// Provider para obtener todos los logros del usuario
final userAchievementsProvider = Provider<List<Achievement>>((ref) {
  // Asegurar que el servicio esté inicializado
  final initState = ref.watch(achievementsInitializationProvider);
  
  if (initState.isLoading || initState.hasError) {
    return [];
  }
  
  final service = ref.watch(achievementsServiceProvider);
  return service.getUserAchievements();
});

/// Provider para obtener logros por categoría
final achievementsByCategoryProvider = Provider<List<AchievementCategory>>((ref) {
  final initState = ref.watch(achievementsInitializationProvider);
  
  if (initState.isLoading || initState.hasError) {
    return [];
  }
  
  final service = ref.watch(achievementsServiceProvider);
  return service.getAchievementsByCategory();
});

/// Provider para obtener logros desbloqueados
final unlockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final initState = ref.watch(achievementsInitializationProvider);
  
  if (initState.isLoading || initState.hasError) {
    return [];
  }
  
  final service = ref.watch(achievementsServiceProvider);
  return service.getUnlockedAchievements();
});

/// Provider para obtener logros cercanos a completar
final nearCompletionAchievementsProvider = Provider<List<Achievement>>((ref) {
  final initState = ref.watch(achievementsInitializationProvider);
  
  if (initState.isLoading || initState.hasError) {
    return [];
  }
  
  final service = ref.watch(achievementsServiceProvider);
  return service.getNearCompletionAchievements();
});

/// Provider para estadísticas de logros
final achievementsStatsProvider = Provider<AchievementsStats>((ref) {
  final initState = ref.watch(achievementsInitializationProvider);
  
  if (initState.isLoading || initState.hasError) {
    return AchievementsStats.empty();
  }
  
  final service = ref.watch(achievementsServiceProvider);
  
  return AchievementsStats(
    totalXp: service.getTotalXp(),
    unlockedCount: service.getUnlockedCount(),
    totalCount: service.getUserAchievements().length,
    completionPercentage: service.getCompletionPercentage(),
  );
});

/// Provider para procesar logros después de una carrera
final processRunAchievementsProvider = FutureProvider.family<List<Achievement>, Run>(
  (ref, run) async {
    final service = ref.watch(achievementsServiceProvider);
    return await service.processRunForAchievements(run);
  },
);

/// Provider para desbloquear un logro social
final unlockSocialAchievementProvider = FutureProvider.family<Achievement?, String>(
  (ref, achievementId) async {
    final service = ref.watch(achievementsServiceProvider);
    return await service.unlockSocialAchievement(achievementId);
  },
);

/// Notifier para mostrar notificaciones de logros desbloqueados
class AchievementNotificationNotifier extends Notifier<Achievement?> {
  Timer? _autoHideTimer;
  
  @override
  Achievement? build() => null;
  
  void showAchievement(Achievement achievement) {
    // Cancelar timer anterior si existe
    _autoHideTimer?.cancel();
    
    state = achievement;
    
    // Auto-hide después de 5 segundos con Timer cancelable
    _autoHideTimer = Timer(const Duration(seconds: 5), () {
      if (state?.id == achievement.id) {
        state = null;
      }
    });
  }
  
  void hideAchievement() {
    _autoHideTimer?.cancel();
    state = null;
  }
}

/// Provider para notificaciones de logros
final achievementNotificationProvider = 
    NotifierProvider<AchievementNotificationNotifier, Achievement?>(
  AchievementNotificationNotifier.new,
);

/// Clase para estadísticas de logros
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
  
  factory AchievementsStats.empty() {
    return const AchievementsStats(
      totalXp: 0,
      unlockedCount: 0,
      totalCount: 0,
      completionPercentage: 0.0,
    );
  }
  
  String get completionText => '${(completionPercentage * 100).toInt()}%';
  String get progressText => '$unlockedCount/$totalCount';
}
