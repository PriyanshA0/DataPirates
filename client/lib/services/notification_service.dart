import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Notification IDs
  static const int lowActivityId = 1;
  static const int highHeartRateId = 2;
  static const int abnormalSleepId = 3;
  static const int scheduledCheckId = 100;

  // Thresholds for alerts
  static const int lowActivityThreshold = 3000; // steps
  static const int highHeartRateThreshold = 120; // bpm (resting)
  static const double minSleepHours = 5.0; // hours
  static const double maxSleepHours = 10.0; // hours

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    print('NotificationService initialized');
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate to relevant screen based on payload
    // This can be expanded to handle navigation
  }

  /// Request notification permissions (call on app start)
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        final bool? granted = await androidPlugin
            .requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        final bool? granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Check if notification type is enabled in settings
  static Future<bool> _isNotificationEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true; // Default enabled
  }

  /// Save notification setting
  static Future<void> setNotificationEnabled(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }

  /// Cache health data for background notification checks
  static Future<void> cacheHealthData({
    required int steps,
    required int heartRate,
    required double sleepHours,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'steps': steps,
      'heartRate': heartRate,
      'sleepHours': sleepHours,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('cached_health_data', jsonEncode(data));
    print('Health data cached for background notifications');
  }

  /// Get cached health data
  static Future<Map<String, dynamic>?> getCachedHealthData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_health_data');
    if (cached != null) {
      return jsonDecode(cached);
    }
    return null;
  }

  /// Schedule periodic health check notifications (e.g., evening reminder)
  static Future<void> scheduleEveningHealthCheck() async {
    await initialize();

    // Schedule for 8 PM daily
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 20, 0); // 8 PM

    // If it's already past 8 PM, schedule for tomorrow
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          channelDescription: 'Daily health check reminders from SwasthSetu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF45A191),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      scheduledCheckId,
      '📊 Daily Health Check',
      'Open SwasthSetu to review your health metrics and sync your latest data.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at same time
      payload: 'daily_check',
    );

    print('Evening health check scheduled for $scheduledTime');
  }

  /// Check cached data and send notifications immediately
  static Future<void> checkCachedDataAndNotify() async {
    final cachedData = await getCachedHealthData();
    if (cachedData == null) {
      print('No cached health data available for notification check');
      return;
    }

    final steps = cachedData['steps'] as int? ?? 0;
    final heartRate = cachedData['heartRate'] as int? ?? 0;
    final sleepHours = (cachedData['sleepHours'] as num?)?.toDouble() ?? 0.0;

    print(
      'Checking cached data: steps=$steps, heartRate=$heartRate, sleep=$sleepHours',
    );

    await checkHealthAndNotify(
      steps: steps,
      heartRate: heartRate,
      sleepHours: sleepHours,
    );
  }

  /// Check health data and show appropriate notifications
  static Future<void> checkHealthAndNotify({
    required int steps,
    required int heartRate,
    required double sleepHours,
  }) async {
    await initialize();

    // Check Low Activity
    if (await _isNotificationEnabled('notify_low_activity')) {
      if (steps < lowActivityThreshold && steps > 0) {
        await _showLowActivityNotification(steps);
      }
    }

    // Check High Heart Rate
    if (await _isNotificationEnabled('notify_high_heart_rate')) {
      if (heartRate > highHeartRateThreshold) {
        await _showHighHeartRateNotification(heartRate);
      }
    }

    // Check Abnormal Sleep
    if (await _isNotificationEnabled('notify_abnormal_sleep')) {
      if (sleepHours > 0 &&
          (sleepHours < minSleepHours || sleepHours > maxSleepHours)) {
        await _showAbnormalSleepNotification(sleepHours);
      }
    }
  }

  /// Show Low Activity Notification
  /// Only shows after 6 PM to give users a full day to meet their step goal
  static Future<void> _showLowActivityNotification(int steps) async {
    // Only show low activity notifications after 6 PM (18:00)
    final now = DateTime.now();
    if (now.hour < 18) {
      print(
        'Low activity notification skipped: before 6 PM (current hour: ${now.hour})',
      );
      return;
    }

    // Check cooldown to avoid spam (once per 6 hours)
    if (!await _shouldShowNotification('low_activity', 6)) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'health_alerts',
          'Health Alerts',
          channelDescription: 'Important health alerts from SwasthSetu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF45A191),
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final remaining = lowActivityThreshold - steps;

    await _notifications.show(
      lowActivityId,
      '🚶 Low Activity Alert',
      'You\'ve only taken $steps steps today. Try to get $remaining more steps to stay healthy!',
      details,
      payload: 'low_activity',
    );

    await _markNotificationShown('low_activity');
    print('Low activity notification sent: $steps steps');
  }

  /// Show High Heart Rate Notification
  static Future<void> _showHighHeartRateNotification(int heartRate) async {
    // Check cooldown (once per 2 hours for urgent alerts)
    if (!await _shouldShowNotification('high_heart_rate', 2)) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'health_alerts',
          'Health Alerts',
          channelDescription: 'Important health alerts from SwasthSetu',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFE53935),
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      highHeartRateId,
      '❤️ High Heart Rate Detected',
      'Your resting heart rate is $heartRate BPM, which is above normal. Consider resting and consult a doctor if this persists.',
      details,
      payload: 'high_heart_rate',
    );

    await _markNotificationShown('high_heart_rate');
    print('High heart rate notification sent: $heartRate BPM');
  }

  /// Show Abnormal Sleep Notification
  static Future<void> _showAbnormalSleepNotification(double sleepHours) async {
    // Check cooldown (once per day)
    if (!await _shouldShowNotification('abnormal_sleep', 24)) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'health_alerts',
          'Health Alerts',
          channelDescription: 'Important health alerts from SwasthSetu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF7C4DFF),
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String message;
    if (sleepHours < minSleepHours) {
      message =
          'You only slept ${sleepHours.toStringAsFixed(1)} hours last night. Aim for 7-9 hours for optimal health.';
    } else {
      message =
          'You slept ${sleepHours.toStringAsFixed(1)} hours last night. Oversleeping can affect your energy levels.';
    }

    await _notifications.show(
      abnormalSleepId,
      '😴 Abnormal Sleep Pattern',
      message,
      details,
      payload: 'abnormal_sleep',
    );

    await _markNotificationShown('abnormal_sleep');
    print('Abnormal sleep notification sent: $sleepHours hours');
  }

  /// Check if enough time has passed since last notification
  static Future<bool> _shouldShowNotification(
    String type,
    int cooldownHours,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt('last_notification_$type') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldownMs = cooldownHours * 60 * 60 * 1000;

    return (now - lastShown) > cooldownMs;
  }

  /// Mark notification as shown
  static Future<void> _markNotificationShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_notification_$type',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show a test notification (for debugging)
  static Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notifications for SwasthSetu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(99, title, body, details);
  }
}
