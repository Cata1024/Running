import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/constants/level_system.dart';
import '../../domain/entities/level_progress.dart';
import '../../domain/repositories/i_level_progress_repository.dart';

/// Firebase-backed implementation that also caches snapshots locally using
/// [SharedPreferences].
class LevelProgressRepository implements ILevelProgressRepository {
  LevelProgressRepository({FirebaseFirestore? firestore, SharedPreferences? preferences})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences;

  final FirebaseFirestore _firestore;
  SharedPreferences? _preferences;

  static const _cacheKeyPrefix = 'level_progress_';

  Future<SharedPreferences> _prefs() async {
    final existing = _preferences;
    if (existing != null) return existing;
    final prefs = await SharedPreferences.getInstance();
    _preferences = prefs;
    return prefs;
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _usersCollection.doc(userId);
  }

  CollectionReference<Map<String, dynamic>> _milestonesCollection(String userId) {
    return _userDoc(userId).collection('level_history');
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  LevelProgressSnapshot _snapshotFromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return LevelProgressSnapshot.initial;
    }

    final totalXp = (data['xp'] as num?)?.toInt() ?? 0;
    final level = (data['level'] as num?)?.toInt() ?? LevelSystem.levelFromXP(totalXp);
    final updatedAt = _parseDate(data['updatedAt']);

    return LevelProgressSnapshot(
      level: level,
      totalXp: totalXp,
      updatedAt: updatedAt,
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _snapshotToJson(LevelProgressSnapshot snapshot) {
    return {
      'level': snapshot.level,
      'totalXp': snapshot.totalXp,
      'updatedAt': snapshot.updatedAt?.toIso8601String(),
      'cachedAt': snapshot.cachedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  LevelProgressSnapshot? _snapshotFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return LevelProgressSnapshot(
      level: (json['level'] as num?)?.toInt() ?? 1,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      updatedAt: _parseDate(json['updatedAt']),
      cachedAt: _parseDate(json['cachedAt']) ?? DateTime.now(),
    );
  }

  LevelMilestoneEntry _milestoneFromMap(Map<String, dynamic> data) {
    final rewardTypeString = data['rewardType'] as String?;
    RewardType? rewardType;
    if (rewardTypeString != null) {
      rewardType = RewardType.values.firstWhere(
        (value) => value.name == rewardTypeString,
        orElse: () => RewardType.milestone,
      );
    }

    return LevelMilestoneEntry(
      oldLevel: (data['oldLevel'] as num?)?.toInt() ?? 0,
      newLevel: (data['newLevel'] as num?)?.toInt() ?? 0,
      xpGained: (data['xpGained'] as num?)?.toInt() ?? 0,
      totalXp: (data['totalXP'] as num?)?.toInt() ?? 0,
      rewardType: rewardType,
      achievedAt: _parseDate(data['achievedAt']),
    );
  }

  Map<String, dynamic> _milestoneToMap(LevelMilestoneEntry entry) {
    return {
      'oldLevel': entry.oldLevel,
      'newLevel': entry.newLevel,
      'xpGained': entry.xpGained,
      'totalXP': entry.totalXp,
      'rewardType': entry.rewardType?.name,
      'achievedAt': entry.achievedAt != null
          ? Timestamp.fromDate(entry.achievedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  @override
  Future<LevelProgressSnapshot> fetchProgress(String userId) async {
    final doc = await _userDoc(userId).get();
    final snapshot = _snapshotFromMap(doc.data());
    await saveCachedProgress(userId, snapshot);
    return snapshot;
  }

  @override
  Future<LevelProgressSnapshot> incrementXp({required String userId, required int xpDelta}) async {
    final docRef = _userDoc(userId);
    final now = DateTime.now();

    final snapshot = await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      final currentData = doc.data() ?? <String, dynamic>{};
      final currentXp = (currentData['xp'] as num?)?.toInt() ?? 0;
      final newXp = (currentXp + xpDelta).clamp(0, 1 << 31);
      final newLevel = LevelSystem.levelFromXP(newXp);

      transaction.set(
        docRef,
        {
          'xp': newXp,
          'level': newLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return LevelProgressSnapshot(
        level: newLevel,
        totalXp: newXp,
        updatedAt: now,
        cachedAt: now,
      );
    });

    await saveCachedProgress(userId, snapshot);
    return snapshot;
  }

  @override
  Future<void> initializeUser(String userId) async {
    await _userDoc(userId).set(
      {
        'xp': 0,
        'level': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await saveCachedProgress(userId, LevelProgressSnapshot.initial);
  }

  @override
  Future<LevelProgressSnapshot?> readCachedProgress(String userId) async {
    final prefs = await _prefs();
    final jsonString = prefs.getString('$_cacheKeyPrefix$userId');
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return _snapshotFromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Future<void> saveCachedProgress(String userId, LevelProgressSnapshot snapshot) async {
    final prefs = await _prefs();
    final jsonString = jsonEncode(_snapshotToJson(snapshot));
    await prefs.setString('$_cacheKeyPrefix$userId', jsonString);
  }

  @override
  Future<List<LevelMilestoneEntry>> fetchRecentMilestones(String userId, {int limit = 20}) async {
    final query = await _milestonesCollection(userId)
        .orderBy('achievedAt', descending: true)
        .limit(limit)
        .get();
    return query.docs
        .map((doc) => _milestoneFromMap(doc.data()))
        .toList(growable: false);
  }

  @override
  Future<void> saveMilestone(String userId, LevelMilestoneEntry milestone) async {
    await _milestonesCollection(userId).add(_milestoneToMap(milestone));
  }
}
