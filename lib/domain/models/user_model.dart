import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int xp;
  final int level;
  final bool isGuest;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime lastActive;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.xp = 0,
    this.level = 1,
    this.isGuest = false,
    this.fcmToken,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      isGuest: json['isGuest'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      createdAt: _parseDate(json['createdAt']),
      lastActive: _parseDate(json['lastActive']),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw Exception('User document does not exist.');
    }

    return UserModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'xp': xp,
      'level': level,
      'isGuest': isGuest,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toFirestore({
    bool forCreate = false,
  }) {
    final map = toMap();

    if (forCreate) {
      map['createdAt'] = Timestamp.fromDate(createdAt);
    }

    map['lastActive'] = Timestamp.fromDate(lastActive);

    return map;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    int? xp,
    int? level,
    bool? isGuest,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      isGuest: isGuest ?? this.isGuest,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
