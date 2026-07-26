import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Immutable domain model representing an authenticated (or guest) player.
///
/// Persisted to Firestore under the `users` collection and cached locally in
/// Hive. All (de)serialization is defensive so malformed/legacy documents can
/// never crash the app.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.level = 1,
    this.xp = 0,
    this.dailyStreak = 0,
    this.lastActiveDate,
    this.badges = const <String>[],
    this.achievements = const <String>[],
    this.totalDiscoveries = 0,
    this.totalWalkingDistance = 0,
    this.createdAt,
    this.fcmToken,
    this.interests = const <String>[],
    this.isGuest = false,
  });

  /// Firebase Auth UID (also the Firestore document id).
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  // Gamification -------------------------------------------------------------
  final int level;
  final int xp;
  final int dailyStreak;
  final DateTime? lastActiveDate;
  final List<String> badges;
  final List<String> achievements;
  final int totalDiscoveries;

  /// Total walking distance in meters.
  final double totalWalkingDistance;

  // Meta ---------------------------------------------------------------------
  final DateTime? createdAt;
  final String? fcmToken;
  final List<String> interests;
  final bool isGuest;

  /// Convenience: an anonymous/guest placeholder user.
  factory UserModel.guest({String id = 'guest'}) => UserModel(
        id: id,
        email: '',
        displayName: 'Guest Explorer',
        isGuest: true,
        createdAt: DateTime.now(),
      );

  /// Builds a [UserModel] from a plain JSON map (Hive cache, API, etc.).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      photoUrl: json['photoUrl'] as String?,
      level: _asInt(json['level'], fallback: 1),
      xp: _asInt(json['xp']),
      dailyStreak: _asInt(json['dailyStreak']),
      lastActiveDate: _asDate(json['lastActiveDate']),
      badges: _asStringList(json['badges']),
      achievements: _asStringList(json['achievements']),
      totalDiscoveries: _asInt(json['totalDiscoveries']),
      totalWalkingDistance: _asDouble(json['totalWalkingDistance']),
      createdAt: _asDate(json['createdAt']),
      fcmToken: json['fcmToken'] as String?,
      interests: _asStringList(json['interests']),
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  /// Builds a [UserModel] from a Firestore document snapshot.
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      id: doc.id,
      email: (data['email'] ?? '').toString(),
      displayName: (data['displayName'] ?? '').toString(),
      photoUrl: data['photoUrl'] as String?,
      level: _asInt(data['level'], fallback: 1),
      xp: _asInt(data['xp']),
      dailyStreak: _asInt(data['dailyStreak']),
      lastActiveDate: _asDate(data['lastActiveDate']),
      badges: _asStringList(data['badges']),
      achievements: _asStringList(data['achievements']),
      totalDiscoveries: _asInt(data['totalDiscoveries']),
      totalWalkingDistance: _asDouble(data['totalWalkingDistance']),
      createdAt: _asDate(data['createdAt']),
      fcmToken: data['fcmToken'] as String?,
      interests: _asStringList(data['interests']),
      isGuest: data['isGuest'] as bool? ?? false,
    );
  }

  /// JSON representation for local caching (dates as ISO-8601 strings).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'level': level,
      'xp': xp,
      'dailyStreak': dailyStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'badges': badges,
      'achievements': achievements,
      'totalDiscoveries': totalDiscoveries,
      'totalWalkingDistance': totalWalkingDistance,
      'createdAt': createdAt?.toIso8601String(),
      'fcmToken': fcmToken,
      'interests': interests,
      'isGuest': isGuest,
    };
  }

  /// Firestore representation. Uses [Timestamp] for date fields and
  /// [FieldValue.serverTimestamp] for [createdAt] on first write.
  Map<String, dynamic> toFirestore({bool forCreate = false}) {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'level': level,
      'xp': xp,
      'dailyStreak': dailyStreak,
      'lastActiveDate':
          lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'badges': badges,
      'achievements': achievements,
      'totalDiscoveries': totalDiscoveries,
      'totalWalkingDistance': totalWalkingDistance,
      'createdAt': forCreate
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : null),
      'fcmToken': fcmToken,
      'interests': interests,
      'isGuest': isGuest,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool clearPhotoUrl = false,
    int? level,
    int? xp,
    int? dailyStreak,
    DateTime? lastActiveDate,
    List<String>? badges,
    List<String>? achievements,
    int? totalDiscoveries,
    double? totalWalkingDistance,
    DateTime? createdAt,
    String? fcmToken,
    bool clearFcmToken = false,
    List<String>? interests,
    bool? isGuest,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      level: level ?? this.level,
      xp: xp ?? this.xp,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      badges: badges ?? this.badges,
      achievements: achievements ?? this.achievements,
      totalDiscoveries: totalDiscoveries ?? this.totalDiscoveries,
      totalWalkingDistance: totalWalkingDistance ?? this.totalWalkingDistance,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: clearFcmToken ? null : (fcmToken ?? this.fcmToken),
      interests: interests ?? this.interests,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  /// Display initials, e.g. "Ada Lovelace" -> "AL".
  String get initials {
    final source = displayName.trim().isNotEmpty
        ? displayName.trim()
        : (email.isNotEmpty ? email : 'Explorer');
    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'E';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Defensive parsing helpers
  // ---------------------------------------------------------------------------
  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        email,
        displayName,
        photoUrl,
        level,
        xp,
        dailyStreak,
        lastActiveDate,
        badges,
        achievements,
        totalDiscoveries,
        totalWalkingDistance,
        createdAt,
        fcmToken,
        interests,
        isGuest,
      ];

  @override
  bool get stringify => true;
}
