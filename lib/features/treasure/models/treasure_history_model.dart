import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'treasure_category.dart';

/// A record of a treasure the player has discovered/collected.
///
/// Stored both in Firestore (per-user `discoveries` subcollection) and cached
/// locally in Hive so the "My Discoveries" screen works offline.
class TreasureHistoryModel extends Equatable {
  const TreasureHistoryModel({
    required this.id,
    required this.treasureId,
    required this.title,
    required this.category,
    required this.collectedAt,
    this.imageUrl,
    this.xpEarned = 0,
    this.lat = 0,
    this.lng = 0,
    this.userPhotoUrl,
    this.walkingDistance = 0,
    this.wasRare = false,
    this.note,
  });

  final String id;
  final String treasureId;
  final String title;
  final TreasureCategory category;
  final DateTime collectedAt;
  final String? imageUrl;
  final int xpEarned;
  final double lat;
  final double lng;

  /// Photo the user captured at the treasure site, if any.
  final String? userPhotoUrl;

  /// Distance walked to reach the treasure, in meters.
  final double walkingDistance;
  final bool wasRare;
  final String? note;

  factory TreasureHistoryModel.fromJson(Map<String, dynamic> json) {
    return TreasureHistoryModel(
      id: (json['id'] ?? '').toString(),
      treasureId: (json['treasureId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: TreasureCategoryX.fromKey(json['category'] as String?),
      collectedAt: _asDate(json['collectedAt']) ?? DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
      xpEarned: _asInt(json['xpEarned']),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      userPhotoUrl: json['userPhotoUrl'] as String?,
      walkingDistance: _asDouble(json['walkingDistance']),
      wasRare: json['wasRare'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  factory TreasureHistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TreasureHistoryModel(
      id: doc.id,
      treasureId: (data['treasureId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      category: TreasureCategoryX.fromKey(data['category'] as String?),
      collectedAt: _asDate(data['collectedAt']) ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      xpEarned: _asInt(data['xpEarned']),
      lat: _asDouble(data['lat']),
      lng: _asDouble(data['lng']),
      userPhotoUrl: data['userPhotoUrl'] as String?,
      walkingDistance: _asDouble(data['walkingDistance']),
      wasRare: data['wasRare'] as bool? ?? false,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'treasureId': treasureId,
      'title': title,
      'category': category.key,
      'collectedAt': collectedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'xpEarned': xpEarned,
      'lat': lat,
      'lng': lng,
      'userPhotoUrl': userPhotoUrl,
      'walkingDistance': walkingDistance,
      'wasRare': wasRare,
      'note': note,
    };
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'treasureId': treasureId,
      'title': title,
      'category': category.key,
      'collectedAt': Timestamp.fromDate(collectedAt),
      'imageUrl': imageUrl,
      'xpEarned': xpEarned,
      'lat': lat,
      'lng': lng,
      'userPhotoUrl': userPhotoUrl,
      'walkingDistance': walkingDistance,
      'wasRare': wasRare,
      'note': note,
    };
  }

  TreasureHistoryModel copyWith({
    String? id,
    String? treasureId,
    String? title,
    TreasureCategory? category,
    DateTime? collectedAt,
    String? imageUrl,
    int? xpEarned,
    double? lat,
    double? lng,
    String? userPhotoUrl,
    double? walkingDistance,
    bool? wasRare,
    String? note,
  }) {
    return TreasureHistoryModel(
      id: id ?? this.id,
      treasureId: treasureId ?? this.treasureId,
      title: title ?? this.title,
      category: category ?? this.category,
      collectedAt: collectedAt ?? this.collectedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      xpEarned: xpEarned ?? this.xpEarned,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      walkingDistance: walkingDistance ?? this.walkingDistance,
      wasRare: wasRare ?? this.wasRare,
      note: note ?? this.note,
    );
  }

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

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        treasureId,
        title,
        category,
        collectedAt,
        imageUrl,
        xpEarned,
        lat,
        lng,
        userPhotoUrl,
        walkingDistance,
        wasRare,
        note,
      ];

  @override
  bool get stringify => true;
}
