import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/service_providers.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';

/// Streams the currently authenticated user.
///
/// Emits:
/// - [UserModel] when a user is signed in.
/// - `null` when the user is signed out.
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Convenience provider that indicates whether the user is authenticated.
///
/// Note:
/// While the auth stream is still loading, this returns `false`.
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Holds the current authentication state and authentication action status.
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const AuthState initial = AuthState();
}

/// Manages authentication actions and exposes [AuthState].
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo)
      : super(
          AuthState(
            user: _repo.currentUser,
          ),
        );

  final AuthRepository _repo;

  /// Updates the state when the authentication stream changes.
  void setUser(UserModel? user) {
    if (user == null) {
      state = state.copyWith(
        clearUser: true,
        isLoading: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      user: user,
      isLoading: false,
      clearError: true,
    );
  }

  /// Signs in with email and password.
  Future<bool> loginWithEmail(
    String email,
    String password,
  ) {
    return _run(
      () => _repo.signInWithEmail(
        email,
        password,
      ),
    );
  }

  /// Signs in using Google.
  Future<bool> loginWithGoogle() {
    return _run(
      () => _repo.signInWithGoogle(),
    );
  }

  /// Registers a new account.
  Future<bool> register(
    String email,
    String password, {
    String? displayName,
  }) {
    return _run(
      () => _repo.registerWithEmail(
        email,
        password,
        displayName: displayName,
      ),
    );
  }

  /// Signs in anonymously as a guest.
  Future<bool> continueAsGuest() {
    return _run(
      () => _repo.signInAsGuest(),
    );
  }

  /// Signs the current user out.
  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _repo.signOut();

      state = const AuthState();
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sends a password reset email.
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _repo.sendPasswordReset(email);

      state = state.copyWith(
        isLoading: false,
      );

      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  /// Updates the signed-in user's profile.
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final user = await _repo.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
      );

      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  /// Clears the current authentication error.
  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  /// Executes an authentication action and maps errors to [AuthState].
  Future<bool> _run(
    Future<UserModel> Function() action,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final user = await action();

      state = state.copyWith(
        user: user,
        isLoading: false,
      );

      // Best effort only.
      // Failure to sync the FCM token must not make authentication fail.
      unawaited(
        _repo.syncFcmToken().catchError(
          (_) {},
        ),
      );

      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }
}

/// Primary authentication notifier provider.
final currentUserProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);

  final notifier = AuthNotifier(repo);

  /// Keep the notifier synchronized with Firebase auth state.
  ref.listen<AsyncValue<UserModel?>>(
    authStateProvider,
    (previous, next) {
      next.whenData(notifier.setUser);
    },
  );

  ref.onDispose(notifier.dispose);

  return notifier;
});
