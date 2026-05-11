import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Initialize once at app start ──────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Notification tap par kuch karna ho toh yahan
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );

    // Android 13+ mein runtime permission maango
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
    debugPrint('✅ LocalNotificationService initialized');
  }

  // ── Schedule a reminder at exact time ──────────────────────────────────────
  static Future<void> scheduleReminder({
    required int id,
    required String taskTitle,
    required DateTime scheduledTime,
    String? taskId,
  }) async {
    if (!_initialized) await init();

    // Agar scheduled time already past ho gayi hai
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Reminder time is in the past, skipping: $scheduledTime');
      return;
    }

    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',           // channel id
      'Task Reminders',           // channel name
      channelDescription: 'Reminds you about your upcoming tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      '⏰ Task Reminder',
      taskTitle,
      tzScheduled,
      notifDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: taskId,
    );

    debugPrint('✅ Reminder scheduled for $scheduledTime → "$taskTitle"');
  }

  // ── Cancel a specific reminder ─────────────────────────────────────────────
  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
    debugPrint('🗑️ Reminder cancelled: id=$id');
  }

  // ── Cancel all reminders ───────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('🗑️ All reminders cancelled');
  }

  // ── Helper: task id se unique int id banao ────────────────────────────────
  static int notifIdFromTaskId(String taskId) {
    return taskId.hashCode.abs() % 2147483647; // Dart max int safe range
  }
}
