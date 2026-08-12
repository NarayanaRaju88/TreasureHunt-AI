import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../domain/models/activity_log_model.dart';
import '../../../domain/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

export 'activity_logger.dart';

/// Whether the signed-in user is an admin (custom claim or admins/{uid} doc).
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).user;
  if (user == null) return false;

  try {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return false;

    final token = await firebaseUser.getIdTokenResult();
    if (token.claims?['admin'] == true) return true;

    return ref.read(firestoreServiceProvider).isAdminDoc(user.uid);
  } catch (_) {
    return false;
  }
});

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  final isAdmin = await ref.watch(isAdminProvider.future);
  if (!isAdmin) {
    throw StateError('Admin access required');
  }
  return ref.read(firestoreServiceProvider).getAdminStats();
});

final adminUsersProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final isAdmin = await ref.watch(isAdminProvider.future);
  if (!isAdmin) {
    throw StateError('Admin access required');
  }
  return ref.read(firestoreServiceProvider).listUsers();
});

final adminActivityLogsProvider =
    StreamProvider.autoDispose<List<ActivityLogModel>>((ref) async* {
  final isAdmin = await ref.watch(isAdminProvider.future);
  if (!isAdmin) {
    yield const <ActivityLogModel>[];
    return;
  }
  yield* ref.read(firestoreServiceProvider).streamActivityLogs();
});
