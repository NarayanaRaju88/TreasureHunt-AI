import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/errors/app_exceptions.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/hive_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Default authentication repository backed by:
///
/// - Firebase Authentication
/// - Cloud Firestore
/// - Hive local cache
/// - Optional FCM service
class AuthRepositoryImpl implements AuthRepository {
