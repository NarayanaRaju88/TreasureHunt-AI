import 'package:ai_treasure_hunt/domain/models/user_model.dart';

/// Contract for authentication and user profile management.
///
/// This file belongs to the Domain layer.
/// It must NEVER contain Firebase implementation.
abstract class AuthRepository {
  /// Emits the current authenticated user.
  Stream<UserModel?> authStateChanges();

  /// Cached authenticated user.
  UserModel? get currentUser;

  /// Google Sign In
  Future<UserModel> signInWithGoogle();

  /// Email Sign In
  Future<UserModel> signInWithEmail(
    String email,
    String password,
  );

  /// Email Registration
  Future<UserModel> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  });

  /// Anonymous Login
  Future<UserModel> signInAsGuest();

  /// Logout
  Future<void> signOut();

  /// Forgot Password
  Future<void> sendPasswordReset(
    String email,
  );

  /// Update profile
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Sync FCM token
  Future<void> syncFcmToken();
}
