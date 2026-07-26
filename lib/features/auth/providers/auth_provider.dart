import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/service_providers.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Streams the current authenticated user (or `null` when signed out).
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Convenience: whether a user is currently signed in.
final isSignedInProvider = Provider<bool>((ref) {
  final state = ref.watch(authStateProvider);
  return state.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// State of the currently authenticated user, with async status for login flows.
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

/// Manages authentication actions and exposes the resulting [AuthState].
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(AuthState(user: _repo.currentUser));

  final AuthRepository _repo;

  /// Sets the current user from the auth stream (called by listeners).
  void setUser(UserModel? user) {
    state = state.copyWith(
      user: user,
      clearUser: user == null,
      isLoading: false,
      clearError: true,
    );
  }

  Future<bool> loginWithEmail(String email, String password) {
    return _run(() => _repo.signInWithEmail(email, password));
  }

  Future<bool> loginWithGoogle() {
    return _run(() => _repo.signInWithGoogle());
  }

  Future<bool> register(
    String email,
    String password, {
    String? displayName,
  }) {
    return _run(
      () => _repo.registerWithEmail(email, password, displayName: displayName),
    );
  }

  Future<bool> continueAsGuest() {
    return _run(() => _repo.signInAsGuest());
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.signOut();
      state = const AuthState();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile({String? displayName, String? photoUrl}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Runs an auth action returning a [UserModel], mapping errors to state.
  Future<bool> _run(Future<UserModel> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await action();
      state = state.copyWith(user: user, isLoading: false);
      // Best-effort: register/refresh the FCM token after sign-in.
      unawaited(_repo.syncFcmToken());
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// The primary auth notifier provider. Keeps [AuthNotifier] in sync with the
/// [authStateProvider] stream.
final currentUserProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repo);

  // Bridge the auth stream into the notifier so external sign-in/out events
  // (token expiry, other tabs, etc.) update the UI state.
  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (previous, next) {
    next.whenData(notifier.setUser);
  });

  return notifier;
});
