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
