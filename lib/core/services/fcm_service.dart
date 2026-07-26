import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

/// Top-level background handler. Referenced from `main.dart`.
///
/// Must be a top-level or static function annotated with `@pragma`.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // Heavy work should be avoided here; log for diagnostics.
  debugPrint('FCM background message: ${message.messageId}');
}

/// Handles Firebase Cloud Messaging and on-device local notifications
/// (including the scheduled daily "morning treasure" reminder).
class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  bool _initialized = false;

  /// The Android notification channel used for all app notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    AppConstants.fcmDefaultChannelId,
    AppConstants.fcmDefaultChannelName,
    description: AppConstants.fcmDefaultChannelDesc,
    importance: Importance.high,
  );

  /// Initializes local notifications, timezone data and foreground handlers.
  ///
  /// Safe to call multiple times (idempotent). [onSelectNotification] is
  /// invoked with the payload when the user taps a local notification.
  Future<void> initialize({
    void Function(String? payload)? onSelectNotification,
  }) async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onSelectNotification?.call(response.payload);
      },
    );

    // Create the Android channel (no-op on iOS).
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Show heads-up notifications while the app is in the foreground (iOS).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages -> render as a local notification.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _initialized = true;
  }

  /// Requests notification permission from the OS. Returns whether granted.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Returns the device FCM token (or `null` if unavailable).
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e, st) {
      debugPrint('getToken failed: $e\n$st');
      return null;
    }
  }

  /// Stream of token refreshes so the app can re-persist the token.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e, st) {
      debugPrint('subscribeToTopic($topic) failed: $e\n$st');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e, st) {
      debugPrint('unsubscribeFromTopic($topic) failed: $e\n$st');
    }
  }

  /// Registers the background message handler. Call once at startup.
  void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  }

  /// Best-effort background handler passthrough (for symmetry with the API).
  Future<void> handleBackgroundMessage(RemoteMessage message) =>
      fcmBackgroundHandler(message);

  /// Shows an immediate local notification.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    await _local.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  /// Schedules a local notification to fire at [scheduledDate]. When
  /// [daily] is true it repeats every day at the same time.
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool daily = false,
    String? payload,
  }) async {
    final tzDate = _toTz(scheduledDate, ensureFuture: daily);
    await _local.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
      payload: payload,
    );
  }

  /// Convenience helper: schedule the recurring daily "morning treasure"
  /// reminder at [hour]:[minute] local time.
  Future<void> scheduleDailyTreasureReminder({
    required int hour,
    required int minute,
    int id = 1001,
    String title = 'Your daily treasure awaits! 🗺️',
    String body = 'A new hidden gem is ready to be discovered near you.',
  }) async {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await scheduleLocalNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: next,
      daily: true,
      payload: 'daily_treasure',
    );
  }

  Future<void> cancelNotification(int id) => _local.cancel(id);

  Future<void> cancelAll() => _local.cancelAll();

  // ===========================================================================
  // Internals
  // ===========================================================================

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    showLocalNotification(
      id: notification.hashCode,
      title: notification.title ?? AppConstants.appName,
      body: notification.body ?? '',
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  NotificationDetails _notificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  tz.TZDateTime _toTz(DateTime date, {bool ensureFuture = false}) {
    var scheduled = tz.TZDateTime.from(date, tz.local);
    if (ensureFuture) {
      final now = tz.TZDateTime.now(tz.local);
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    return scheduled;
  }
}
