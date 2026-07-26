import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/hive_service.dart';
import '../models/user_model.dart';

/// Contract for authentication + user profile management.
abstract class AuthRepository {
  /// Emits the app's [UserModel] on auth-state changes (`null` when signed out).
  Stream<UserModel?> authStateChanges();

  /// The currently cached/known user, if any.
  UserModel? get currentUser;

  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  });
  Future<UserModel> signInAsGuest();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<UserModel> updateProfile({String? displayName, String? photoUrl});
  Future<void> syncFcmToken();
}

/// Default [AuthRepository] backed by Firebase Auth + Firestore, with a Hive
/// cache for offline access to the current user.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthService authService,
    required FirestoreService firestoreService,
    required HiveService hiveService,
    FcmService? fcmService,
  })  : _auth = authService,
        _firestore = firestoreService,
        _hive = hiveService,
        _fcm = fcmService;

  final FirebaseAuthService _auth;
  final FirestoreService _firestore;
  final HiveService _hive;
  final FcmService? _fcm;

  UserModel? _cachedUser;

  @override
  UserModel? get currentUser => _cachedUser ?? _hive.getUser();

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateStream.asyncMap((fb.User? fbUser) async {
      if (fbUser == null) {
        _cachedUser = null;
        return null;
      }
      final user = await _resolveUser(fbUser);
      _cachedUser = user;
      await _hive.saveUser(user);
      return user;
    });
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final cred = await _auth.signInWithGoogle();
    if (cred?.user == null) {
      throw const AuthException('Google sign-in was cancelled.',
          code: 'cancelled');
    }
    return _postSignIn(cred!.user!, fallbackName: cred.user!.displayName);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailPassword(email, password);
    final user = cred.user;
    if (user == null) {
      throw const AuthException('Sign-in failed.', code: 'no-user');
    }
    return _postSignIn(user);
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final cred = await _auth.registerWithEmail(
      email,
      password,
      displayName: displayName,
    );
    final user = cred.user;
    if (user == null) {
      throw const AuthException('Registration failed.', code: 'no-user');
    }
    // Always create a fresh profile document on registration.
    final model = UserModel(
      id: user.uid,
      email: user.email ?? email,
      displayName: displayName ?? user.displayName ?? '',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await _firestore.createUser(model);
    return _finalize(model);
  }

  @override
  Future<UserModel> signInAsGuest() async {
    final cred = await _auth.signInAsGuest();
    final user = cred.user;
    if (user == null) {
      throw const AuthException('Guest sign-in failed.', code: 'no-user');
    }
    final model = UserModel(
      id: user.uid,
      email: '',
      displayName: 'Guest Explorer',
      isGuest: true,
      createdAt: DateTime.now(),
    );
    await _firestore.createUser(model);
    return _finalize(model);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _cachedUser = null;
    await _hive.clearUser();
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  @override
  Future<UserModel> updateProfile({String? displayName, String? photoUrl}) async {
    final existing = currentUser;
    if (existing == null) {
      throw const AuthException('No signed-in user to update.',
          code: 'no-current-user');
    }
    await _auth.updateProfile(displayName: displayName, photoUrl: photoUrl);
    final updated = existing.copyWith(
      displayName: displayName ?? existing.displayName,
      photoUrl: photoUrl ?? existing.photoUrl,
    );
    await _firestore.updateUser(updated.id, <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    return _finalize(updated);
  }

  @override
  Future<void> syncFcmToken() async {
    final user = currentUser;
    final fcm = _fcm;
    if (user == null || fcm == null || user.isGuest) return;
    final token = await fcm.getToken();
    if (token == null || token.isEmpty || token == user.fcmToken) return;
    await _firestore.updateFcmToken(user.id, token);
    final updated = user.copyWith(fcmToken: token);
    await _finalize(updated);
  }

  // ===========================================================================
  // Internals
  // ===========================================================================

  /// Ensures a Firestore profile exists for [fbUser], creating one if missing,
  /// then caches and returns the [UserModel].
  Future<UserModel> _postSignIn(fb.User fbUser, {String? fallbackName}) async {
    final model = await _resolveUser(fbUser, fallbackName: fallbackName);
    return _finalize(model);
  }

  Future<UserModel> _resolveUser(fb.User fbUser, {String? fallbackName}) async {
    UserModel? remote;
    try {
      remote = await _firestore.getUser(fbUser.uid);
    } catch (_) {
      // Offline or transient — fall back to cache/auth data below.
      remote = _hive.getUser();
      if (remote != null && remote.id == fbUser.uid) return remote;
      remote = null;
    }

    if (remote != null) return remote;

    // First-time login for this uid — create a profile document.
    final model = UserModel(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fallbackName ?? fbUser.displayName ?? '',
      photoUrl: fbUser.photoURL,
      isGuest: fbUser.isAnonymous,
      createdAt: DateTime.now(),
    );
    try {
      await _firestore.createUser(model);
    } catch (_) {
      // Ignore create failure when offline; local cache still works.
    }
    return model;
  }

  Future<UserModel> _finalize(UserModel model) async {
    _cachedUser = model;
    await _hive.saveUser(model);
    return model;
  }
}
