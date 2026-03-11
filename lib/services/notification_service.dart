import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(initializationSettings);

    // Schedule all meal reminders
    await scheduleMealReminders();
  }

  Future<void> scheduleMealReminders() async {
    // 8 AM - Breakfast
    await _scheduleDailyNotification(
      id: 1,
      title: "Good morning! ☀️",
      body: "Time to fuel up with a healthy breakfast.",
      hour: 8,
      minute: 0,
    );

    // 12 PM - Lunch
    await _scheduleDailyNotification(
      id: 2,
      title: "Lunch time! 🥗",
      body: "Don't forget to log your lunch and stay on track.",
      hour: 12,
      minute: 0,
    );

    // 8 PM - Dinner
    await _scheduleDailyNotification(
      id: 3,
      title: "Dinner time! 🍽️",
      body: "It's time for dinner. Let's hit those macro goals!",
      hour: 20,
      minute: 0,
    );
  }

  Future<void> _requestExactAlarmPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final bool? granted = await androidPlugin.requestExactAlarmsPermission();
      if (granted == false) {
        // Fallback or log — exact timing will be best-effort
      }
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

    if (androidPlugin != null) {
      final bool? hasPermission = await androidPlugin
          .canScheduleExactNotifications();
      if (hasPermission == false) {
        // Try requesting once
        await _requestExactAlarmPermission();
        // If still no permission, fallback to inexact
        final bool stillNoPermission =
            !(await androidPlugin.canScheduleExactNotifications() == true);
        if (stillNoPermission) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Meal Reminders',
          channelDescription:
              'Notifications to remind you to eat and log meals',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
