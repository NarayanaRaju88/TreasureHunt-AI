import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../domain/models/user_model.dart';

/// Best-effort platform label for activity logs.
String activityPlatformLabel() {
  if (kIsWeb) return 'web';
  try {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
  } catch (_) {}
  return 'unknown';
}

/// Writes an activity log without failing the calling auth flow.
Future<void> logUserActivity(
  Ref ref, {
  required UserModel user,
  required String action,
  Map<String, dynamic>? details,
}) async {
  try {
    await ref.read(firestoreServiceProvider).logActivity(
          user: user,
          action: action,
          platform: activityPlatformLabel(),
          details: details,
        );
  } catch (_) {
    // Audit logging must never block login/logout.
  }
}
