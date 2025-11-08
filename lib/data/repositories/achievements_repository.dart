import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/constants/achievements_catalog.dart';
import '../../domain/repositories/i_achievements_repository.dart';

class AchievementsRepository implements IAchievementsRepository {
  AchievementsRepository({
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences;

  final FirebaseFirestore _firestore;
  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    final existing = _preferences;
    if (existing != null) return existing;
    final prefs = await SharedPreferences.getInstance();
    _preferences = prefs;
    return prefs;
  }

  static Map<String, dynamic> _progressToJson(
      Map<String, AchievementProgress> entries) {
    return entries.map((key, value) {
      return MapEntry(key, {
        'currentValue': value.currentValue,
        'isUnlocked': value.isUnlocked,
        'unlockedAt': value.unlockedAt?.toIso8601String(),
      });
    });
  }

  static AchievementsSnapshot _mapToSnapshot(Map<String, dynamic> map) {
    if (map.isEmpty) return AchievementsSnapshot.empty;
    final parsed = <String, AchievementProgress>{};
    map.forEach((key, value) {
      if (value is! Map<String, dynamic>) return;
      final unlockedAtRaw = value['unlockedAt'];
      DateTime? unlockedAt;
      if (unlockedAtRaw is Timestamp) {
        unlockedAt = unlockedAtRaw.toDate();
      } else if (unlockedAtRaw is String && unlockedAtRaw.isNotEmpty) {
        unlockedAt = DateTime.tryParse(unlockedAtRaw);
      }
      final currentValue = value['currentValue'];
      final isUnlocked = value['isUnlocked'];
      parsed[key] = AchievementProgress(
        currentValue: currentValue is int
            ? currentValue
            : (currentValue is num ? currentValue.toInt() : 0),
        isUnlocked: isUnlocked is bool ? isUnlocked : false,
        unlockedAt: unlockedAt,
      );
    });
    return AchievementsSnapshot(entries: parsed);
  }

  @override
  Future<AchievementsSnapshot> fetchRemoteSnapshot(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc('progress')
        .get();

    if (!doc.exists) {
      return AchievementsSnapshot.empty;
    }

    final data = doc.data();
    if (data == null) return AchievementsSnapshot.empty;
    final achievements = data['achievements'];
    if (achievements is! Map<String, dynamic>) {
      return AchievementsSnapshot.empty;
    }
    return _mapToSnapshot(achievements);
  }

  @override
  Future<void> saveRemoteSnapshot(
    String userId,
    AchievementsSnapshot snapshot, {
    required int totalXp,
    required int unlockedCount,
  }) async {
    final payload = _progressToJson(snapshot.entries);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc('progress')
        .set({
      'achievements': payload,
      'lastUpdated': FieldValue.serverTimestamp(),
      'totalXp': totalXp,
      'unlockedCount': unlockedCount,
    }, SetOptions(merge: true));
  }

  @override
  Future<AchievementsSnapshot?> fetchCachedSnapshot(String userId) async {
    final prefs = await _prefs();
    final jsonString = prefs.getString('achievements_$userId');
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return _mapToSnapshot(decoded);
      }
    } catch (_) {
      // ignore malformed cache
    }
    return null;
  }

  @override
  Future<void> saveCachedSnapshot(
      String userId, AchievementsSnapshot snapshot) async {
    final prefs = await _prefs();
    final jsonString = jsonEncode(_progressToJson(snapshot.entries));
    await prefs.setString('achievements_$userId', jsonString);
  }

  @override
  Future<void> bootstrapCatalogIfNeeded(String userId) async {
    final snapshot = await fetchRemoteSnapshot(userId);
    if (snapshot.entries.isNotEmpty) {
      return;
    }

    final catalogEntries = AchievementsCatalog.allAchievements.fold<
        Map<String, AchievementProgress>>({}, (acc, achievement) {
      acc[achievement.id] = const AchievementProgress(
        currentValue: 0,
        isUnlocked: false,
        unlockedAt: null,
      );
      return acc;
    });

    final bootstrapSnapshot = AchievementsSnapshot(entries: catalogEntries);
    await saveRemoteSnapshot(
      userId,
      bootstrapSnapshot,
      totalXp: 0,
      unlockedCount: 0,
    );
    await saveCachedSnapshot(userId, bootstrapSnapshot);
  }
}
