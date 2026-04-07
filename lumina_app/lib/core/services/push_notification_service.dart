import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ═══════════════════════════════════════════════════════════════
// PUSH NOTIFICATION SERVICE — FCM + Local Notifications
// ═══════════════════════════════════════════════════════════════

/// Top-level background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[PushNotification] Background message: ${message.messageId}');
}

/// Notification channel for Android (high importance).
const _androidChannel = AndroidNotificationChannel(
  'airamd_high_importance',
  'airaMD Notifications',
  description: 'แจ้งเตือนสำคัญจาก airaMD',
  importance: Importance.high,
  playSound: true,
);

/// Complete push notification service with FCM + local notifications.
class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage();
  static const _fcmTokenKey = 'aira_fcm_token';
  static const _notifEnabledKey = 'aira_notif_enabled';
  static const _apptReminderKey = 'aira_appt_reminder';
  static const _followUpReminderKey = 'aira_followup_reminder';

  static bool _initialized = false;

  /// Initialize Firebase + FCM + Local Notifications.
  /// Call this from main() after WidgetsFlutterBinding.ensureInitialized().
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase (if not already)
      try {
        await Firebase.initializeApp();
      } catch (e) {
        // Firebase may already be initialized or not configured yet
        debugPrint('[PushNotification] Firebase init: $e');
      }

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize local notifications
      await _initLocalNotifications();

      // Create Android notification channel
      if (Platform.isAndroid) {
        await _localPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }

      // Request permission
      await requestPermission();

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps (app was in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle notification tap when app was terminated
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Get and store FCM token
      await _updateFcmToken();

      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _saveFcmToken(token);
      });

      _initialized = true;
      debugPrint('[PushNotification] Initialized successfully');
    } catch (e) {
      debugPrint('[PushNotification] Init error (Firebase may not be configured): $e');
    }
  }

  /// Initialize local notification plugin.
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // ─── Permission ──────────────────────────────────────────

  /// Request notification permission.
  static Future<bool> requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('[PushNotification] Permission: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      debugPrint('[PushNotification] Permission error: $e');
      return false;
    }
  }

  // ─── FCM Token ──────────────────────────────────────────

  /// Get and store the current FCM token.
  static Future<String?> _updateFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('[PushNotification] Token error: $e');
      return null;
    }
  }

  /// Save FCM token locally and to Supabase.
  static Future<void> _saveFcmToken(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);

    // Also store in Supabase for server-side push
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('push_tokens')
            .upsert({
              'user_id': user.id,
              'token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,platform');
      }
    } catch (e) {
      // Table may not exist yet — non-blocking
      debugPrint('[PushNotification] Token save to Supabase: $e');
    }
  }

  /// Get the stored FCM token.
  static Future<String?> getFcmToken() async {
    return _storage.read(key: _fcmTokenKey);
  }

  // ─── Message Handlers ──────────────────────────────────

  /// Handle foreground messages — show local notification.
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[PushNotification] Foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    _localPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Handle message opened (tap from background).
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[PushNotification] Opened: ${message.data}');
    // Navigate based on data payload
    _processNotificationNavigation(message.data);
  }

  /// Handle local notification tap.
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[PushNotification] Local tap: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _processNotificationNavigation(data);
      } catch (_) {}
    }
  }

  /// Route navigation based on notification data.
  static void _processNotificationNavigation(Map<String, dynamic> data) {
    // Navigation is handled by the app's notification handler provider
    _pendingNavigation = data;
  }

  /// Pending navigation data from a notification tap.
  static Map<String, dynamic>? _pendingNavigation;

  /// Consume pending navigation (called by the app to navigate).
  static Map<String, dynamic>? consumePendingNavigation() {
    final nav = _pendingNavigation;
    _pendingNavigation = null;
    return nav;
  }

  // ─── Local Notifications (Scheduled) ────────────────────

  /// Schedule a local notification for an appointment reminder.
  static Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String patientName,
    required String treatmentName,
    required DateTime appointmentTime,
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    final enabled = await isAppointmentReminderEnabled();
    if (!enabled) return;

    final scheduledTime = appointmentTime.subtract(reminderBefore);
    if (scheduledTime.isBefore(DateTime.now())) return;

    final id = appointmentId.hashCode.abs() % 2147483647;

    try {
      await _localPlugin.zonedSchedule(
        id,
        'นัดหมาย — $patientName',
        '$treatmentName เวลา ${_formatTime(appointmentTime)}',
        _convertToTZDateTime(scheduledTime),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({
          'type': 'appointment_reminder',
          'appointment_id': appointmentId,
        }),
      );

      debugPrint('[PushNotification] Scheduled reminder for $patientName at $scheduledTime');
    } catch (e) {
      debugPrint('[PushNotification] Schedule error: $e');
    }
  }

  /// Schedule a follow-up reminder.
  static Future<void> scheduleFollowUpReminder({
    required String patientId,
    required String patientName,
    required String treatmentName,
    required DateTime followUpDate,
  }) async {
    final enabled = await isFollowUpReminderEnabled();
    if (!enabled) return;

    // Remind at 9 AM on the follow-up day
    final reminderTime = DateTime(followUpDate.year, followUpDate.month, followUpDate.day, 9, 0);
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = ('followup_$patientId$treatmentName').hashCode.abs() % 2147483647;

    try {
      await _localPlugin.zonedSchedule(
        id,
        'ติดตามผล — $patientName',
        'วันนี้เป็นวัน Follow-up: $treatmentName',
        _convertToTZDateTime(reminderTime),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({
          'type': 'follow_up',
          'patient_id': patientId,
        }),
      );
    } catch (e) {
      debugPrint('[PushNotification] Follow-up schedule error: $e');
    }
  }

  /// Cancel a specific notification.
  static Future<void> cancelNotification(String id) async {
    await _localPlugin.cancel(id.hashCode.abs() % 2147483647);
  }

  /// Cancel all notifications.
  static Future<void> cancelAll() async {
    await _localPlugin.cancelAll();
  }

  /// Show an immediate local notification.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // ─── Settings ──────────────────────────────────────────

  /// Check if notifications are globally enabled.
  static Future<bool> isNotificationsEnabled() async {
    final v = await _storage.read(key: _notifEnabledKey);
    return v != 'false'; // Default: enabled
  }

  /// Toggle notifications on/off.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _storage.write(key: _notifEnabledKey, value: enabled.toString());
  }

  /// Check if appointment reminders are enabled.
  static Future<bool> isAppointmentReminderEnabled() async {
    final v = await _storage.read(key: _apptReminderKey);
    return v != 'false';
  }

  /// Toggle appointment reminders.
  static Future<void> setAppointmentReminderEnabled(bool enabled) async {
    await _storage.write(key: _apptReminderKey, value: enabled.toString());
  }

  /// Check if follow-up reminders are enabled.
  static Future<bool> isFollowUpReminderEnabled() async {
    final v = await _storage.read(key: _followUpReminderKey);
    return v != 'false';
  }

  /// Toggle follow-up reminders.
  static Future<void> setFollowUpReminderEnabled(bool enabled) async {
    await _storage.write(key: _followUpReminderKey, value: enabled.toString());
  }

  // ─── Helpers ──────────────────────────────────────────

  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Riverpod Providers ─────────────────────────────────────

/// Whether push notifications are enabled.
final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  return PushNotificationService.isNotificationsEnabled();
});

/// Whether appointment reminders are enabled.
final appointmentReminderEnabledProvider = FutureProvider<bool>((ref) async {
  return PushNotificationService.isAppointmentReminderEnabled();
});

/// Whether follow-up reminders are enabled.
final followUpReminderEnabledProvider = FutureProvider<bool>((ref) async {
  return PushNotificationService.isFollowUpReminderEnabled();
});

/// The stored FCM token (for debug/display).
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  return PushNotificationService.getFcmToken();
});
