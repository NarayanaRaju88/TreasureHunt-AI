import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/errors/app_exceptions.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/hive_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

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

    final now = DateTime.now();

    final model = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      displayName:
          displayName ??
          firebaseUser.displayName ??
          '',
      photoUrl: firebaseUser.photoURL,
      xp: 0,
      level: 1,
      interests: const [],
      badges: const [],
      totalDiscoveries: 0,
      totalWalkingDistance: 0,
      isGuest: false,
      fcmToken: null,
      createdAt: now,
      lastActive: now,
    );

    try {
      await _firestore.createUser(model);
    } catch (_) {
      // Firebase account already exists even if Firestore write fails.
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

    try {
      final existing = await _firestore.getUser(firebaseUser.uid);

      if (existing != null) {
        return _finalize(existing);
      }
    } catch (_) {}

    final now = DateTime.now();

    final guest = UserModel(
      uid: firebaseUser.uid,
      email: '',
      displayName: 'Guest Explorer',
      photoUrl: null,
      xp: 0,
      level: 1,
      interests: const [],
      badges: const [],
      totalDiscoveries: 0,
      totalWalkingDistance: 0,
      isGuest: true,
      fcmToken: null,
      createdAt: now,
      lastActive: now,
    );

    try {
      await _firestore.createUser(guest);
    } catch (_) {}

    return _finalize(guest);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();

    _cachedUser = null;

    await _hive.clearUser();
  }

  @override
  Future<void> sendPasswordReset(String email) {
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
        updated.uid,
        {
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          'lastActive': DateTime.now(),
        },
      );
    } catch (_) {
      // Ignore Firestore failures.
    }

    return _finalize(updated);
  }

  @override
  Future<void> syncFcmToken() async {
    final user = currentUser;

    if (user == null || user.isGuest || _fcm == null) {
      return;
    }

    try {
      final token = await _fcm!.getToken();

      if (token == null ||
          token.isEmpty ||
          token == user.fcmToken) {
        return;
      }

      await _firestore.updateFcmToken(
        user.uid,
        token,
      );

      await _finalize(
        user.copyWith(
          fcmToken: token,
          lastActive: DateTime.now(),
        ),
      );
    } catch (_) {
      // Ignore token sync failures.
    }
  }

  // ===========================================================================
  // Private helpers
  // ===========================================================================

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
        final updated = remote.copyWith(
          lastActive: DateTime.now(),
        );

        try {
          await _firestore.updateUser(
            updated.uid,
            {
              'lastActive': updated.lastActive,
            },
          );
        } catch (_) {}

        return updated;
      }
    } catch (_) {
      // Continue with cache.
    }

    final cached = _hive.getUser();

    if (cached != null &&
        cached.uid == firebaseUser.uid) {
      return cached.copyWith(
        lastActive: DateTime.now(),
      );
    }

    final now = DateTime.now();

    final model = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName:
          fallbackName ??
          firebaseUser.displayName ??
          '',
      photoUrl: firebaseUser.photoURL,
      xp: 0,
      level: 1,
      interests: const [],
      badges: const [],
      totalDiscoveries: 0,
      totalWalkingDistance: 0,
      isGuest: firebaseUser.isAnonymous,
      fcmToken: null,
      createdAt: now,
      lastActive: now,
    );

    try {
      await _firestore.createUser(model);
    } catch (_) {
      // Ignore when offline.
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
