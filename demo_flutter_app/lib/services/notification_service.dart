import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int _dailyRoutineNotificationId = 7001;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    tz.initializeTimeZones();
    // Keep scheduling stable across devices/build flavors without relying
    // on an extra platform plugin that can break Android release builds.
    tz.setLocalLocation(tz.UTC);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> showPromoNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'delix_promotions',
        'Promotions',
        channelDescription: 'Campaigns and new arrivals from Delix.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> scheduleDailyRoutineReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'delix_routine_reminders',
        'Routine Reminders',
        channelDescription: 'Daily reminders for AM and PM skincare routines.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _dailyRoutineNotificationId,
      title,
      body,
      _nextInstanceOfTime(time),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelDailyRoutineReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_dailyRoutineNotificationId);
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
