class ProfileViewModel {
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
  
  // Alias para compatibilidad con sistema de niveles
  int get xp => experience.toInt();

  const ProfileViewModel({
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

  factory ProfileViewModel.fromSources({
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

    return ProfileViewModel(
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

    final lowerBound =
        currentLevelExperience ?? _defaultCurrentThreshold(level);
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
