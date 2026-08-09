import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int xp;
  final int level;
  final int dailyStreak;
  final List<String> interests;
  final List<String> badges;
  final int totalDiscoveries;
  final double totalWalkingDistance;
  final bool isGuest;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime lastActive;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.xp = 0,
    this.level = 1,
    this.dailyStreak = 0,
    this.interests = const [],
    this.badges = const [],
    this.totalDiscoveries = 0,
    this.totalWalkingDistance = 0,
    this.isGuest = false,
    this.fcmToken,
    required this.createdAt,
    required this.lastActive,
  });

  String get id => uid;

  bool get hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static DateTime _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse('$v') ?? DateTime.now();
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  factory UserModel.empty() {
    final now = DateTime.now();
    return UserModel(
      uid: '',
      email: '',
      displayName: 'Guest',
      createdAt: now,
      lastActive: now,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: (map['uid'] ?? map['id'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        displayName: (map['displayName'] ?? '') as String,
        photoUrl: map['photoUrl'] as String?,
        xp: _asInt(map['xp']),
        level: _asInt(map['level'] ?? 1),
        dailyStreak: _asInt(map['dailyStreak']),
        interests: List<String>.from(map['interests'] ?? const []),
        badges: List<String>.from(map['badges'] ?? const []),
        totalDiscoveries: _asInt(map['totalDiscoveries']),
        totalWalkingDistance: _asDouble(map['totalWalkingDistance']),
        isGuest: map['isGuest'] as bool? ?? false,
        fcmToken: map['fcmToken'] as String?,
        createdAt: _date(map['createdAt']),
        lastActive: _date(map['lastActive'] ?? map['lastActiveDate']),
      );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    data.putIfAbsent('uid', () => doc.id);
    return UserModel.fromMap(data);
  }

  /// Hive-safe map. Must only contain JSON/Hive primitives — never
  /// Firestore [Timestamp] objects (those crash local caching after login).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'id': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'xp': xp,
      'level': level,
      'dailyStreak': dailyStreak,
      'interests': interests,
      'badges': badges,
      'totalDiscoveries': totalDiscoveries,
      'totalWalkingDistance': totalWalkingDistance,
      'isGuest': isGuest,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  /// Firestore document payload aligned with `firestore.rules` `isValidUser()`.
  /// Does not write `uid`/`id` into the document body (doc id is the uid).
  Map<String, dynamic> toFirestore({
    bool forCreate = false,
  }) {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'xp': xp,
      'level': level,
      'dailyStreak': dailyStreak,
      'interests': interests,
      'badges': badges,
      'totalDiscoveries': totalDiscoveries,
      'totalWalkingDistance': totalWalkingDistance,
      'isGuest': isGuest,
      'fcmToken': fcmToken,
      if (forCreate) 'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveDate': Timestamp.fromDate(lastActive),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    int? xp,
    int? level,
    int? dailyStreak,
    List<String>? interests,
    List<String>? badges,
    int? totalDiscoveries,
    double? totalWalkingDistance,
    bool? isGuest,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastActive,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        dailyStreak: dailyStreak ?? this.dailyStreak,
        interests: interests ?? this.interests,
        badges: badges ?? this.badges,
        totalDiscoveries: totalDiscoveries ?? this.totalDiscoveries,
        totalWalkingDistance:
            totalWalkingDistance ?? this.totalWalkingDistance,
        isGuest: isGuest ?? this.isGuest,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt ?? this.createdAt,
        lastActive: lastActive ?? this.lastActive,
      );

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        xp,
        level,
        dailyStreak,
        interests,
        badges,
        totalDiscoveries,
        totalWalkingDistance,
        isGuest,
        fcmToken,
        createdAt,
        lastActive,
      ];
}
