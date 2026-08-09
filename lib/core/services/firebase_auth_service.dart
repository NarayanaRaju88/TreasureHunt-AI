import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../errors/app_exceptions.dart';

/// Thin wrapper around Firebase Authentication and Google Sign-In.
///
/// This service is responsible only for authentication.
/// User profile documents are managed by [AuthRepository] and
/// [FirestoreService].
class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: <String>['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Returns the currently signed-in Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Returns whether a Firebase user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Emits whenever Firebase authentication state changes.
  Stream<User?> get authStateStream => _auth.authStateChanges();

  /// Emits whenever the Firebase user changes.
  Stream<User?> get userChangesStream => _auth.userChanges();

  /// Signs in using Google.
  ///
  /// Returns `null` when the user cancels the Google account picker.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(
        credential,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e, st) {
      final raw = e.toString();
      // Common Android misconfiguration: missing SHA-1 / empty oauth_client.
      if (raw.contains('ApiException: 10') ||
          raw.contains('DEVELOPER_ERROR')) {
        throw AuthException(
          'Google Sign-In is not configured. Add this app\'s SHA-1 in Firebase and re-download google-services.json.',
          code: 'google-sign-in-config',
          cause: e,
          stackTrace: st,
        );
      }
      throw AuthException(
        'Google sign-in failed. Please try again.',
        code: 'google-sign-in-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Signs in using email and password.
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e, st) {
      throw AuthException(
        'Sign-in failed. Please try again.',
        code: 'sign-in-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Creates a new email/password account.
  Future<UserCredential> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final name = displayName?.trim();

      if (name != null && name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
        await credential.user?.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e, st) {
      throw AuthException(
        'Registration failed. Please try again.',
        code: 'register-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Signs in anonymously.
  Future<UserCredential> signInAsGuest() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e, st) {
      throw AuthException(
        'Guest sign-in failed. Please try again.',
        code: 'guest-sign-in-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Signs the user out of Firebase and Google.
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      final bool googleSignedIn =
          await _googleSignIn.isSignedIn();

      if (googleSignedIn) {
        await _googleSignIn.signOut();
      }
    } catch (e, st) {
      throw AuthException(
        'Sign-out failed. Please try again.',
        code: 'sign-out-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Sends a password reset email.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e, st) {
      throw AuthException(
        'Could not send reset email. Please try again.',
        code: 'password-reset-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Updates the current Firebase user's profile.
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'No signed-in user to update.',
        code: 'no-current-user',
      );
    }

    try {
      if (displayName != null) {
        await user.updateDisplayName(
          displayName.trim(),
        );
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(
          photoUrl,
        );
      }

      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e, st) {
      throw AuthException(
        'Could not update profile. Please try again.',
        code: 'profile-update-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Sends email verification to the current user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null || user.emailVerified) {
      return;
    }

    try {
      await user.sendEmailVerification();
    } catch (e, st) {
      debugPrint(
        'sendEmailVerification failed: $e\n$st',
      );
    }
  }

  /// Returns the supplied FCM token.
  ///
  /// FCM persistence is handled by the repository and Firestore service.
  Future<String?> updateFcmToken(String? token) async {
    return token;
  }

  /// Reloads the current Firebase user.
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e, st) {
      debugPrint(
        'reloadUser failed: $e\n$st',
      );
    }
  }
}
