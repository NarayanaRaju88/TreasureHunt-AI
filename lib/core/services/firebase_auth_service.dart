import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../errors/app_exceptions.dart';

/// Thin wrapper around [FirebaseAuth] and [GoogleSignIn].
///
/// Translates low-level `FirebaseAuthException`s into the app's
/// [AuthException] surface so the presentation layer stays clean. This service
/// only concerns itself with *authentication* — user profile documents in
/// Firestore are managed by [FirestoreService]/[AuthRepository].
class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: <String>['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// The currently signed-in user, or `null`.
  User? getCurrentUser() => _auth.currentUser;

  /// Emits the current [User] whenever auth state changes (login/logout).
  Stream<User?> get authStateStream => _auth.authStateChanges();

  /// Emits on token refresh & profile updates in addition to auth changes.
  Stream<User?> get userChangesStream => _auth.userChanges();

  bool get isSignedIn => _auth.currentUser != null;

  /// Signs in using the native Google account picker.
  ///
  /// Returns `null` if the user cancels the Google chooser.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted the sign-in flow.
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e, st) {
      throw AuthException(
        'Google sign-in failed. Please try again.',
        code: 'google-sign-in-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Email/password sign-in.
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

  /// Registers a new account with email/password and sets the display name.
  Future<UserCredential> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) {
        await cred.user?.updateDisplayName(name);
        await cred.user?.reload();
      }
      return cred;
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

  /// Anonymous (guest) sign-in.
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
      await Future.wait<void>([
        _auth.signOut(),
        _googleSignIn.isSignedIn().then(
              (signedIn) => signedIn ? _googleSignIn.signOut() : Future.value(),
            ),
      ]);
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
      await _auth.sendPasswordResetEmail(email: email.trim());
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

  /// Updates the current user's display name and/or photo URL.
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user to update.',
          code: 'no-current-user');
    }
    try {
      if (displayName != null) await user.updateDisplayName(displayName.trim());
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
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

  /// Sends an email verification link to the current user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } catch (e, st) {
      debugPrint('sendEmailVerification failed: $e\n$st');
    }
  }

  /// Stores/updates the FCM token stub on the auth side (no-op placeholder;
  /// the token is persisted to Firestore via [FirestoreService.updateUser]).
  ///
  /// Kept here so callers have a single obvious entry point; returns the token
  /// that should be written to the user's Firestore document.
  Future<String?> updateFcmToken(String? token) async {
    // The auth layer does not persist the token itself, but we expose this so
    // the repository can coordinate the write. Returning the token keeps the
    // contract explicit and testable.
    return token;
  }

  /// Reloads the current user from the server (e.g. after verification).
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e, st) {
      debugPrint('reloadUser failed: $e\n$st');
    }
  }
}
