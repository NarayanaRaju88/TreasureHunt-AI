import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../../features/gamification/models/achievement_model.dart';
import '../../features/treasure/models/daily_challenge_model.dart';
import '../../features/treasure/models/treasure_history_model.dart';
import '../../features/treasure/models/treasure_model.dart';
import '../../features/auth/models/user_model.dart';

/// Centralized Firestore data access for the app.
///
/// Every method converts low-level `FirebaseException`s into the app's
/// [AppException] hierarchy. All typed collection references use
/// `withConverter` where useful, but for flexibility most reads use the raw
/// map API and hydrate models via their `fromFirestore` factories.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Collection references ----------------------------------------------------
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _treasures =>
      _db.collection(AppConstants.treasuresCollection);

  CollectionReference<Map<String, dynamic>> get _achievements =>
      _db.collection(AppConstants.achievementsCollection);

  CollectionReference<Map<String, dynamic>> _userDiscoveries(String uid) =>
      _users.doc(uid).collection(AppConstants.discoveriesCollection);

  CollectionReference<Map<String, dynamic>> _userAchievements(String uid) =>
      _users.doc(uid).collection(AppConstants.achievementsCollection);

  CollectionReference<Map<String, dynamic>> _userChallenges(String uid) =>
      _users.doc(uid).collection('daily_challenges');

  // ===========================================================================
  // Users
  // ===========================================================================

  /// Fetches a user document. Returns `null` if it does not exist.
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to load user profile.');
    }
  }

  /// Creates (or overwrites) a user document.
  Future<void> createUser(UserModel user) async {
    try {
      await _users.doc(user.id).set(
            user.toFirestore(forCreate: true),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to create user profile.');
    }
  }

  /// Updates specific fields on a user document.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _users.doc(uid).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to update user profile.');
    }
  }

  /// Persists the FCM token for a user.
  Future<void> updateFcmToken(String uid, String token) async {
    await updateUser(uid, <String, dynamic>{'fcmToken': token});
  }

  /// Real-time stream of a single user document.
  Stream<UserModel?> streamUserData(String uid) {
    return _users.doc(uid).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      },
    ).handleError((Object e, StackTrace st) {
      throw _mapFirestore(e, st, 'Failed to stream user data.');
    });
  }

  // ===========================================================================
  // Treasures
  // ===========================================================================

  /// Fetches treasures, optionally filtered by category and limited.
  Future<List<TreasureModel>> getTreasures({
    String? categoryKey,
    int limit = 50,
    bool onlyActive = true,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _treasures;
      if (categoryKey != null) {
        query = query.where('category', isEqualTo: categoryKey);
      }
      query = query.limit(limit);

      final snapshot = await query.get();
      final now = DateTime.now();
      final list = snapshot.docs
          .map(TreasureModel.fromFirestore)
          .where((t) => !onlyActive || t.expiresAt == null || t.expiresAt!.isAfter(now))
          .toList();
      return list;
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to load treasures.');
    }
  }

  /// Fetches today's daily treasure for a user, if one has been generated and
  /// stored. Returns `null` when none exists yet.
  Future<TreasureModel?> getDailyTreasure(String uid, {DateTime? date}) async {
    try {
      final day = date ?? DateTime.now();
      final id = _dailyDocId(day);
      final doc =
          await _users.doc(uid).collection('daily_treasure').doc(id).get();
      if (!doc.exists) return null;
      return TreasureModel.fromFirestore(doc);
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to load daily treasure.');
    }
  }

  /// Stores a generated daily treasure for a user.
  Future<void> saveDailyTreasure(
    String uid,
    TreasureModel treasure, {
    DateTime? date,
  }) async {
    try {
      final day = date ?? DateTime.now();
      final id = _dailyDocId(day);
      await _users
          .doc(uid)
          .collection('daily_treasure')
          .doc(id)
          .set(treasure.toFirestore(forCreate: true), SetOptions(merge: true));
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to save daily treasure.');
    }
  }

  /// Persists a treasure collection event: writes a discovery record and marks
  /// the treasure collected. Uses a batch for atomicity.
  Future<void> saveTreasureCollection(
    String uid,
    TreasureHistoryModel history,
  ) async {
    try {
      final batch = _db.batch();
      final discoveryRef = history.id.isNotEmpty
          ? _userDiscoveries(uid).doc(history.id)
          : _userDiscoveries(uid).doc();
      batch.set(discoveryRef, history.toFirestore(), SetOptions(merge: true));
      await batch.commit();
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to save your discovery.');
    }
  }

  // ===========================================================================
  // Achievements
  // ===========================================================================

  /// Loads the merged achievement list for a user: the global catalog joined
  /// with the user's per-achievement progress documents.
  Future<List<AchievementModel>> getAchievements(String uid) async {
    try {
      final results = await Future.wait([
        _achievements.get(),
        _userAchievements(uid).get(),
      ]);

      final catalog = results[0].docs;
      final progressDocs = results[1].docs;
      final progressById = <String, Map<String, dynamic>>{
        for (final d in progressDocs) d.id: d.data(),
      };

      if (catalog.isEmpty && progressDocs.isNotEmpty) {
        // No global catalog seeded — fall back to user progress docs alone.
        return progressDocs.map(AchievementModel.fromFirestore).toList();
      }

      return catalog.map((doc) {
        final base = AchievementModel.fromFirestore(doc);
        final prog = progressById[doc.id];
        if (prog == null) return base;
        return base.copyWith(
          isUnlocked: prog['isUnlocked'] as bool? ?? base.isUnlocked,
          progress: (prog['progress'] as num?)?.toInt() ?? base.progress,
          unlockedAt: _dateFrom(prog['unlockedAt']) ?? base.unlockedAt,
        );
      }).toList();
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to load achievements.');
    }
  }

  /// Writes/updates a user's progress for a single achievement.
  Future<void> updateAchievement(
    String uid,
    AchievementModel achievement,
  ) async {
    try {
      await _userAchievements(uid).doc(achievement.id).set(
        <String, dynamic>{
          'isUnlocked': achievement.isUnlocked,
          'progress': achievement.progress,
          'unlockedAt': achievement.unlockedAt != null
              ? Timestamp.fromDate(achievement.unlockedAt!)
              : null,
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to update achievement.');
    }
  }

  // ===========================================================================
  // Daily challenges
  // ===========================================================================

  Future<List<DailyChallengeModel>> getDailyChallenges(
    String uid, {
    DateTime? date,
  }) async {
    try {
      final day = date ?? DateTime.now();
      final dayKey = _dailyDocId(day);
      final snapshot = await _userChallenges(uid)
          .where('dayKey', isEqualTo: dayKey)
          .get();
      return snapshot.docs.map(DailyChallengeModel.fromFirestore).toList();
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to load daily challenges.');
    }
  }

  Future<void> saveDailyChallenge(
    String uid,
    DailyChallengeModel challenge, {
    DateTime? date,
  }) async {
    try {
      final day = date ?? DateTime.now();
      final data = challenge.toFirestore()..['dayKey'] = _dailyDocId(day);
      final ref = challenge.id.isNotEmpty
          ? _userChallenges(uid).doc(challenge.id)
          : _userChallenges(uid).doc();
      await ref.set(data, SetOptions(merge: true));
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to save daily challenge.');
    }
  }

  // ===========================================================================
  // History / discoveries
  // ===========================================================================

  Future<void> saveTreasureHistory(
    String uid,
    TreasureHistoryModel history,
  ) async {
    try {
      final ref = history.id.isNotEmpty
          ? _userDiscoveries(uid).doc(history.id)
          : _userDiscoveries(uid).doc();
      await ref.set(history.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to save discovery history.');
    }
  }

  Future<List<TreasureHistoryModel>> getUserHistory(
    String uid, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _userDiscoveries(uid)
          .orderBy('collectedAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map(TreasureHistoryModel.fromFirestore).toList();
    } on FirebaseException catch (e, st) {
      throw _mapFirestore(e, st, 'Failed to load discovery history.');
    }
  }

  /// Real-time stream of a user's discovery history.
  Stream<List<TreasureHistoryModel>> streamUserHistory(
    String uid, {
    int limit = 100,
  }) {
    return _userDiscoveries(uid)
        .orderBy('collectedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(TreasureHistoryModel.fromFirestore).toList());
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// Deterministic per-day document id, e.g. `2026-07-18`.
  String _dailyDocId(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _dateFrom(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  AppException _mapFirestore(Object e, StackTrace st, String friendly) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return AuthException(
            'You do not have permission to perform this action.',
            code: e.code,
            cause: e,
            stackTrace: st,
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return NetworkException(
            'Service is temporarily unavailable. Please try again.',
            code: e.code,
            cause: e,
            stackTrace: st,
          );
        case 'not-found':
          return NotFoundException(friendly, code: e.code, cause: e, stackTrace: st);
        default:
          return ServerException(friendly, code: e.code, cause: e, stackTrace: st);
      }
    }
    return UnknownException(friendly, e, st);
  }
}
