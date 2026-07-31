import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int xp;
  final int level;
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

  factory UserModel.empty() {
    final now = DateTime.now();
    return UserModel(uid:'',email:'',displayName:'Guest',createdAt:now,lastActive:now);
  }

  factory UserModel.fromMap(Map<String,dynamic> map)=>UserModel(
    uid:(map['uid']??map['id']??'') as String,
    email:(map['email']??'') as String,
    displayName:(map['displayName']??'') as String,
    photoUrl:map['photoUrl'] as String?,
    xp:(map['xp']??0) as int,
    level:(map['level']??1) as int,
    interests:List<String>.from(map['interests']??const[]),
    badges:List<String>.from(map['badges']??const[]),
    totalDiscoveries:(map['totalDiscoveries']??0) as int,
    totalWalkingDistance:(map['totalWalkingDistance']??0).toDouble(),
    isGuest:(map['isGuest']??false) as bool,
    fcmToken:map['fcmToken'] as String?,
    createdAt:_date(map['createdAt']),
    lastActive:_date(map['lastActive']),
  );

  factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel.fromMap(json);
 }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String,dynamic>> doc){
    final data=doc.data()??<String,dynamic>{};
    data.putIfAbsent('uid',()=>doc.id);
    return UserModel.fromMap(data);
  }

  Map<String,dynamic> toMap()=>{
    'uid':uid,
    'id':uid,
    'email':email,
    'displayName':displayName,
    'photoUrl':photoUrl,
    'xp':xp,
    'level':level,
    'interests':interests,
    'badges':badges,
    'totalDiscoveries':totalDiscoveries,
    'totalWalkingDistance':totalWalkingDistance,
    'isGuest':isGuest,
    'fcmToken':fcmToken,
    'createdAt':Timestamp.fromDate(createdAt),
    'lastActive':Timestamp.fromDate(lastActive),
  };

  Map<String, dynamic> toJson() {
  return toMap();
  }

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
    String? uid,String? email,String? displayName,String? photoUrl,
    int? xp,int? level,List<String>? interests,List<String>? badges,
    int? totalDiscoveries,double? totalWalkingDistance,bool? isGuest,
    String? fcmToken,DateTime? createdAt,DateTime? lastActive,
  })=>UserModel(
    uid:uid??this.uid,
    email:email??this.email,
    displayName:displayName??this.displayName,
    photoUrl:photoUrl??this.photoUrl,
    xp:xp??this.xp,
    level:level??this.level,
    interests:interests??this.interests,
    badges:badges??this.badges,
    totalDiscoveries:totalDiscoveries??this.totalDiscoveries,
    totalWalkingDistance:totalWalkingDistance??this.totalWalkingDistance,
    isGuest:isGuest??this.isGuest,
    fcmToken:fcmToken??this.fcmToken,
    createdAt:createdAt??this.createdAt,
    lastActive:lastActive??this.lastActive,
  );

  @override
  List<Object?> get props=>[
    uid,email,displayName,photoUrl,xp,level,interests,badges,
    totalDiscoveries,totalWalkingDistance,isGuest,fcmToken,
    createdAt,lastActive,
  ];
}
