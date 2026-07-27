import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/hive_service.dart';
import 'package:treasure_hunt_ai/domain/models/user_model.dart';

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
  UserModel? get currentUser {
    return _cachedUser ?? _hive.getUser();
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateStream.asyncMap(
      (fb.User? firebaseUser) async {
        if (firebaseUser == null) {
          _cachedUser = null;
          await _hive.clearUser();
          return null;
        }

        final user = await _resolveUser(
          firebaseUser,
        );

        _cachedUser = user;

        await _hive.saveUser(
          user,
        );

        return user;
      },
    );
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final credential =
        await _auth.signInWithGoogle();

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
    final credential =
        await _auth.signInWithEmailPassword(
      email,
      password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw const AuthException(
        'Sign-in failed.',
        code: 'no-user',
      );
    }

    return _postSignIn(
      firebaseUser,
    );
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final credential =
        await _auth.registerWithEmail(
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
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      displayName:
          displayName ??
          firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    // Firebase registration succeeded.
    // Firestore failure should not invalidate the Firebase account.
    try {
      await _firestore.createUser(
        model,
      );
    } catch (_) {
      // Continue with local cache and Firebase authentication.
    }

    return _finalize(
      model,
    );
  }

  @override
  Future<UserModel> signInAsGuest() async {
    final credential =
        await _auth.signInAsGuest();

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw const AuthException(
        'Guest sign-in failed.',
        code: 'no-user',
      );
    }

    // Try to load an existing profile first.
    UserModel? existing;

    try {
      existing = await _firestore.getUser(
        firebaseUser.uid,
      );
    } catch (_) {
      existing = null;
    }

    if (existing != null) {
      return _finalize(
        existing,
      );
    }

    final model = UserModel(
      uid: firebaseUser.uid,
      email: '',
      displayName: 'Guest Explorer',
      isGuest: true,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    try {
      await _firestore.createUser(
        model,
      );
    } catch (_) {
      // Continue with local cache.
    }

    return _finalize(
      model,
    );
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
    return _auth.sendPasswordReset(
      email,
    );
  }

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final existing = currentUser;

    if (existing == null) {
      throw const AuthException(
        'No signed-in user to update.',
        code: 'no-current-user',
      );
    }

    await _auth.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );

    final updated = existing.copyWith(
      displayName:
          displayName ??
          existing.displayName,
      photoUrl:
          photoUrl ??
          existing.photoUrl,
    );

    await _firestore.updateUser(
      updated.uid,
      <String, dynamic>{
        if (displayName != null)
          'displayName': displayName,
        if (photoUrl != null)
          'photoUrl': photoUrl,
      },
    );

    return _finalize(
      updated,
    );
  }

  @override
  Future<void> syncFcmToken() async {
    final user = currentUser;
    final fcm = _fcm;

    if (user == null ||
        fcm == null ||
        user.isGuest) {
      return;
    }

    try {
      final token = await fcm.getToken();

      if (token == null ||
          token.isEmpty ||
          token == user.fcmToken) {
        return;
      }

      await _firestore.updateFcmToken(
        user.uid,
        token,
      );

      final updated = user.copyWith(
        fcmToken: token,
      );

      await _finalize(
        updated,
      );
    } catch (_) {
      // FCM synchronization is best effort.
      // Authentication should never fail because FCM is unavailable.
    }
  }

  // ===========================================================================
  // Internal helpers
  // ===========================================================================

  Future<UserModel> _postSignIn(
    fb.User firebaseUser, {
    String? fallbackName,
  }) async {
    final model = await _resolveUser(
      firebaseUser,
      fallbackName: fallbackName,
    );

    return _finalize(
      model,
    );
  }

  Future<UserModel> _resolveUser(
    fb.User firebaseUser, {
    String? fallbackName,
  }) async {
    UserModel? remote;

    try {
      remote = await _firestore.getUser(
        firebaseUser.uid,
      );
    } catch (_) {
      final cached = _hive.getUser();

      if (cached != null &&
          cached.uid == firebaseUser.uid) {
        return cached;
      }
    }

    if (remote != null) {
      return remote;
    }

    final model = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName:
          fallbackName ??
          firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isGuest: firebaseUser.isAnonymous,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    try {
      await _firestore.createUser(
        model,
      );
    } catch (_) {
      // Offline mode:
      // local Hive cache will still be used.
    }

    return model;
  }

  Future<UserModel> _finalize(
    UserModel model,
  ) async {
    _cachedUser = model;

    await _hive.saveUser(
      model,
    );

    return model;
  }
}
