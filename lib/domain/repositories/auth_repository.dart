import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/hive_service.dart';
import 'package:ai_treasure_hunt/domain/models/user_model.dart';

/// Contract for authentication and user profile management.
abstract class AuthRepository {
  Stream<UserModel?> authStateChanges();

  UserModel? get currentUser;

  Future<UserModel> signInWithGoogle();

  Future<UserModel> signInWithEmail(
    String email,
    String password,
  );

  Future<UserModel> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  });

  Future<UserModel> signInAsGuest();

  Future<void> signOut();

  Future<void> sendPasswordReset(
    String email,
  );

  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  Future<void> syncFcmToken();
}

/// Default authentication repository backed by:
///
/// - Firebase Authentication
/// - Cloud Firestore
/// - Hive local cache
/// - Optional FCM service
