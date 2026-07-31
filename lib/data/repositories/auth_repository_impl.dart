import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/errors/app_exceptions.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/hive_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase implementation of [AuthRepository].
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
    return _auth.authStateStream.asyncMap((fb.User? firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        await _hive.clearUser();
        return null;
      }

      final user = await _resolveUser(firebaseUser);

      _cachedUser = user;
      await _hive.saveUser(user);

      return user;
    });
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final credential = await _auth.signInWithGoogle();

    final firebaseUser = credential?.user;

    if (firebaseUser == null) {
      throw const AuthException(
        'Google sign-in was cancelled.',
        code: 'cancelled',
      );
    }

    return _postSignIn(
      firebaseUser,
      fallbackName: firebaseUser.displayName,
    );
  }

  @override
  Future<UserModel> signInWithEmail(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailPassword(
      email,
      password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw const AuthException(
        'Sign in failed.',
        code: 'no-user',
      );
    }

    return _postSignIn(firebaseUser);
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final credential = await _auth.registerWithEmail(
      email,
      password,
      displayName: displayName,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw const AuthException(
        'Registration failed.',
        code: 'no-user',
      );
    }

    final model = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      displayName:
          displayName ??
          firebaseUser.displayName ??
          '',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.createUser(model);
    } catch (_) {
      // Firestore failure should never invalidate Firebase registration.
    }

    return _finalize(model);
  }

  @override
  Future<UserModel> signInAsGuest() async {
    final credential = await _auth.signInAsGuest();

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw const AuthException(
        'Guest sign-in failed.',
        code: 'no-user',
      );
    }

    UserModel? existing;

    try {
      existing = await _firestore.getUser(firebaseUser.uid);
    } catch (_) {
      existing = null;
    }

    if (existing != null) {
      return _finalize(existing);
    }

    final model = UserModel(
      id: firebaseUser.uid,
      email: '',
      displayName: 'Guest Explorer',
      isGuest: true,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.createUser(model);
    } catch (_) {}

    return _finalize(model);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();

    _cachedUser = null;

    await _hive.clearUser();
  }

  @override
  Future<void> sendPasswordReset(
    String email,
  ) {
    return _auth.sendPasswordReset(email);
  }
    @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final existing = currentUser;

    if (existing == null) {
      throw const AuthException(
        'No signed-in user.',
        code: 'no-current-user',
      );
    }

    await _auth.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );

    final updated = existing.copyWith(
      displayName: displayName ?? existing.displayName,
      photoUrl: photoUrl ?? existing.photoUrl,
      lastActive: DateTime.now(),
    );

    try {
      await _firestore.updateUser(
        updated.id,
        {
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          'lastActive': DateTime.now(),
        },
      );
    } catch (_) {
      // Ignore Firestore update failure.
    }

    return _finalize(updated);
  }

  @override
  Future<void> syncFcmToken() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    if (user.isGuest) {
      return;
    }

    if (_fcm == null) {
      return;
    }

    try {
      final token = await _fcm!.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      if (token == user.fcmToken) {
        return;
      }

      await _firestore.updateFcmToken(
        user.id,
        token,
      );

      final updated = user.copyWith(
        fcmToken: token,
      );

      await _finalize(updated);
    } catch (_) {
      // Best effort only.
    }
  }

  //===========================================================================
  // Private helpers
  //===========================================================================

  Future<UserModel> _postSignIn(
    fb.User firebaseUser, {
    String? fallbackName,
  }) async {
    final model = await _resolveUser(
      firebaseUser,
      fallbackName: fallbackName,
    );

    return _finalize(model);
  }

  Future<UserModel> _resolveUser(
    fb.User firebaseUser, {
    String? fallbackName,
  }) async {
    try {
      final remote = await _firestore.getUser(
        firebaseUser.uid,
      );

      if (remote != null) {
        return remote.copyWith(
          lastActive: DateTime.now(),
        );
      }
    } catch (_) {
      // Continue with local cache.
    }

    final cached = _hive.getUser();

    if (cached != null && cached.id == firebaseUser.uid) {
      return cached.copyWith(
        lastActive: DateTime.now(),
      );
    }

    final model = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName:
          fallbackName ??
          firebaseUser.displayName ??
          '',
      photoUrl: firebaseUser.photoURL,
      isGuest: firebaseUser.isAnonymous,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    try {
      await _firestore.createUser(model);
    } catch (_) {
      // Offline mode.
    }

    return model;
  }

  Future<UserModel> _finalize(
    UserModel model,
  ) async {
    _cachedUser = model;

    await _hive.saveUser(model);

    return model;
  }
}
