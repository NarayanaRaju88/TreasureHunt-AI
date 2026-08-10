import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Audit event for admin visibility (logins, logouts, key actions).
class ActivityLogModel extends Equatable {
  const ActivityLogModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.action,
    required this.createdAt,
    this.isGuest = false,
    this.platform,
    this.details,
  });

  final String id;
  final String userId;
  final String email;
  final String displayName;
  final String action;
  final DateTime createdAt;
  final bool isGuest;
  final String? platform;
  final Map<String, dynamic>? details;

  factory ActivityLogModel.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLogModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      displayName: (map['displayName'] ?? '') as String,
      action: (map['action'] ?? 'unknown') as String,
      createdAt: _date(map['createdAt']),
      isGuest: map['isGuest'] as bool? ?? false,
      platform: map['platform'] as String?,
      details: map['details'] is Map
          ? Map<String, dynamic>.from(map['details'] as Map)
          : null,
    );
  }

  factory ActivityLogModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ActivityLogModel.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'action': action,
      'createdAt': Timestamp.fromDate(createdAt),
      'isGuest': isGuest,
      if (platform != null) 'platform': platform,
      if (details != null) 'details': details,
    };
  }

  static DateTime _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse('$v') ?? DateTime.now();
  }

  String get actionLabel {
    switch (action) {
      case 'login_email':
        return 'Email login';
      case 'login_google':
        return 'Google login';
      case 'login_guest':
        return 'Guest login';
      case 'register':
        return 'Registered';
      case 'logout':
        return 'Logout';
      case 'session_start':
        return 'Session start';
      default:
        return action;
    }
  }

  @override
  List<Object?> get props =>
      <Object?>[id, userId, email, action, createdAt, isGuest, platform];
}
