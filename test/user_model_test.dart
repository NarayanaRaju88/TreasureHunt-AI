import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_treasure_hunt/domain/models/user_model.dart';

void main() {
  test('UserModel.toJson is Hive-safe (no Timestamp values)', () {
    final now = DateTime.utc(2026, 8, 9, 12);
    final user = UserModel(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'Explorer',
      createdAt: now,
      lastActive: now,
    );

    final json = user.toJson();
    expect(json['createdAt'], isA<String>());
    expect(json['lastActive'], isA<String>());
    expect(json.values.whereType<Timestamp>(), isEmpty);

    final roundTrip = UserModel.fromJson(json);
    expect(roundTrip.uid, 'u1');
    expect(roundTrip.createdAt.toUtc(), now);
    expect(roundTrip.lastActive.toUtc(), now);
  });

  test('UserModel.toFirestore uses rule-friendly fields', () {
    final now = DateTime.utc(2026, 8, 9, 12);
    final user = UserModel(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'Explorer',
      isGuest: true,
      createdAt: now,
      lastActive: now,
    );

    final payload = user.toFirestore(forCreate: true);
    expect(payload.containsKey('uid'), isFalse);
    expect(payload.containsKey('id'), isFalse);
    expect(payload['lastActiveDate'], isA<Timestamp>());
    expect(payload.containsKey('lastActive'), isFalse);
    expect(payload['isGuest'], isTrue);
  });
}
