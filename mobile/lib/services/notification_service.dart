import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification Channel IDs
  static const String taskChannelId = 'fatloss_tasks_channel';
  static const String taskChannelName = 'Meal & Task Nudges';
  static const String taskChannelDesc =
      '30-min meal prep, 10-min drink & routine reminders';

  static const String waterChannelId = 'fatloss_water_channel';
  static const String waterChannelName = 'Daily Water Goal';
  static const String waterChannelDesc =
      'Hydration reminders to hit 12 glasses (3.5L) daily';

  // Preference keys
  static const String prefNotificationsEnabled = 'pref_notifications_enabled';

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Timezones
    tz_data.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final locationName = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      if (kDebugMode) {
        print("Warning: Could not get local timezone: $e. Falling back to UTC/Local.");
      }
      try {
        tz.setLocalLocation(tz.local);
      } catch (_) {}
    }

    // Android Initialization Settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / Darwin Initialization Settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print("Notification tapped with payload: ${response.payload}");
        }
      },
    );

    _isInitialized = true;

    // Automatically reschedule daily nudges if enabled
    final isEnabled = await areNotificationsEnabled();
    if (isEnabled) {
      await scheduleAllDailyNudges();
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  // Check Settings
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefNotificationsEnabled, enabled);
    if (enabled) {
      await scheduleAllDailyNudges();
    } else {
      await cancelAll();
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Schedule all daily recurring nudges (meals 30 mins before, drinks 10 mins before, water checks)
  Future<void> scheduleAllDailyNudges() async {
    if (!_isInitialized) await init();
    await cancelAll();

    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    // -------------------------------------------------------------
    // 1. DRINK & HERBAL NUDGES (10 mins before timetable)
    // -------------------------------------------------------------
    // Timetable 06:00 (Jeera Water) -> Nudge at 05:50
    await _scheduleDailyNotification(
      id: 101,
      hour: 5,
      minute: 50,
      title: "🌅 Morning Hydration in 10 mins",
      body: "Start your day with 1 warm glass of Jeera water to boost digestion.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Timetable 11:00 (Black Coffee / Green / Lemon Tea) -> Nudge at 10:50
    await _scheduleDailyNotification(
      id: 102,
      hour: 10,
      minute: 50,
      title: "☕ Green Tea / Coffee in 10 mins",
      body: "Time for your metabolism boost! Black coffee or green/lemon tea (no sugar, no milk).",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Timetable 16:00 / 16:30 (Snack & Lemon Tea) -> Nudge at 15:50
    await _scheduleDailyNotification(
      id: 103,
      hour: 15,
      minute: 50,
      title: "🍵 Evening Green Tea & Snack in 10 mins",
      body: "Prepare your light afternoon roasted chana / makhana + green/lemon tea.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // -------------------------------------------------------------
    // 2. MEAL PREPARATION & MEAL NUDGES (30 mins before timetable)
    // -------------------------------------------------------------
    // Breakfast Prep & Eat (Timetable 07:45 / 08:30) -> Nudge at 07:15
    await _scheduleDailyNotification(
      id: 201,
      hour: 7,
      minute: 15,
      title: "🍳 Breakfast Prep in 30 mins",
      body: "Get your high-protein veg breakfast ready! Remember: eat your protein first.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Mid-morning Fruit (Timetable 11:30) -> Nudge at 11:15
    await _scheduleDailyNotification(
      id: 202,
      hour: 11,
      minute: 15,
      title: "🍎 Fresh Fruit Break in 15 mins",
      body: "Grab 1 fresh whole fruit (Apple, Pear, Orange, Papaya) for natural fiber.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Lunch Prep & Meal (Timetable 13:00) -> Nudge at 12:30 (30 mins before)
    await _scheduleDailyNotification(
      id: 203,
      hour: 12,
      minute: 30,
      title: "🥗 Lunch Prep in 30 mins",
      body: "Time to prep lunch! Golden Rule: Big fresh salad & protein first, rice last.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Dinner Prep & Meal (Timetable 19:30) -> Nudge at 19:00 (30 mins before)
    await _scheduleDailyNotification(
      id: 204,
      hour: 19,
      minute: 0,
      title: "🍲 Dinner Prep in 30 mins",
      body: "Time for light evening dinner (Soup + Paneer/Soya). Zero carbs, roti or rice!",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // -------------------------------------------------------------
    // 3. WORKOUT & ACTIVITY NUDGES
    // -------------------------------------------------------------
    // Fasted Walk (Timetable 06:15) -> Nudge at 06:05 (10 mins before)
    await _scheduleDailyNotification(
      id: 301,
      hour: 6,
      minute: 5,
      title: "🚶 Fasted Morning Walk in 10 mins",
      body: "Lace up your shoes for a 30-min steady fat-burning walk.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Evening Walk (Timetable 18:00) -> Nudge at 17:45 (15 mins before)
    await _scheduleDailyNotification(
      id: 302,
      hour: 17,
      minute: 45,
      title: "🌇 Evening Walk in 15 mins",
      body: "15–20 minutes evening walk to reach today's step count target.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // -------------------------------------------------------------
    // 4. DAILY WATER GOAL NUDGES (Periodic 12-glass reminders)
    // -------------------------------------------------------------
    // 09:00 AM
    await _scheduleDailyNotification(
      id: 401,
      hour: 9,
      minute: 0,
      title: "💧 Water Goal: Morning Hydration",
      body: "Log your morning glasses of water! Daily target is 12 glasses (3.5 Liters).",
      channelId: waterChannelId,
      channelName: waterChannelName,
      channelDesc: waterChannelDesc,
    );

    // 11:30 AM
    await _scheduleDailyNotification(
      id: 402,
      hour: 11,
      minute: 30,
      title: "💧 Water Goal: Pre-Lunch Glass",
      body: "Drink a full glass of water 30 mins before lunch to aid satiety and digestion.",
      channelId: waterChannelId,
      channelName: waterChannelName,
      channelDesc: waterChannelDesc,
    );

    // 02:30 PM
    await _scheduleDailyNotification(
      id: 403,
      hour: 14,
      minute: 30,
      title: "💧 Water Goal: Afternoon Boost",
      body: "Keep your energy high and cravings low. Have a fresh glass of water now.",
      channelId: waterChannelId,
      channelName: waterChannelName,
      channelDesc: waterChannelDesc,
    );

    // 05:00 PM
    await _scheduleDailyNotification(
      id: 404,
      hour: 17,
      minute: 0,
      title: "💧 Water Goal: Pre-Workout Hydration",
      body: "Drink 1-2 glasses of water before your evening walk/workout.",
      channelId: waterChannelId,
      channelName: waterChannelName,
      channelDesc: waterChannelDesc,
    );

    // 07:00 PM
    await _scheduleDailyNotification(
      id: 405,
      hour: 19,
      minute: 0,
      title: "💧 Water Goal: Evening Check-in",
      body: "Almost there! How many glasses logged today? Push towards the 12-glass mark.",
      channelId: waterChannelId,
      channelName: waterChannelName,
      channelDesc: waterChannelDesc,
    );

    // 09:15 PM
    await _scheduleDailyNotification(
      id: 406,
      hour: 21,
      minute: 15,
      title: "💧 Water Goal: Final Daily Review",
      body: "Wrap up today's 12 glasses (3.5L) and check off all tasks for 100% completion!",
      channelId: waterChannelId,
      channelName: waterChannelName,
      channelDesc: waterChannelDesc,
    );

    // -------------------------------------------------------------
    // 5. NIGHTLY REVIEW & WEIGH-IN PREP (21:45)
    // -------------------------------------------------------------
    await _scheduleDailyNotification(
      id: 501,
      hour: 21,
      minute: 45,
      title: "🌙 Daily Roadmap Check",
      body: "Great job today! Make sure all tasks are checked off before sleep. Ready for tomorrow!",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );
  }

  /// Sends a test instant notification right away to verify permissions and system alerts
  Future<void> sendInstantTestNotification() async {
    if (!_isInitialized) await init();

    final androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: taskChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 999,
      title: "🥗 60-Day Veg Fat Loss Nudges Active!",
      body: "You'll get reminders for water goals, meals (30m before), and green tea/coffee (10m before).",
      notificationDetails: details,
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    try {
      final scheduledTime = _nextInstanceOfTime(hour, minute);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error scheduling notification $id ($title): $e");
      }
    }
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
