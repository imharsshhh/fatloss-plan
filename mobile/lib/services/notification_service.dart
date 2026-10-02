import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

    try {
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

      // Android Initialization Settings with custom monochrome notification silhouette
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

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

      // Create High-Priority Notification Channels explicitly for Android
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final androidImpl = _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          if (androidImpl != null) {
            const taskChannel = AndroidNotificationChannel(
              taskChannelId,
              taskChannelName,
              description: taskChannelDesc,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            );

            const waterChannel = AndroidNotificationChannel(
              waterChannelId,
              waterChannelName,
              description: waterChannelDesc,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            );

            await androidImpl.createNotificationChannel(taskChannel);
            await androidImpl.createNotificationChannel(waterChannel);
          }
        } catch (e) {
          if (kDebugMode) {
            print("Warning: Error creating notification channels: $e");
          }
        }
      }

      _isInitialized = true;

      // Automatically reschedule daily nudges if enabled
      final isEnabled = await areNotificationsEnabled();
      if (isEnabled) {
        await scheduleAllDailyNudges();
      }
    } catch (e) {
      if (kDebugMode) {
        print("NotificationService init error: $e");
      }
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final granted = await androidImpl.requestNotificationsPermission();
          try {
            await androidImpl.requestExactAlarmsPermission();
          } catch (_) {}
          return granted ?? false;
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
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
    } catch (e) {
      if (kDebugMode) {
        print("NotificationService requestPermissions error: $e");
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

  static int _timeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    } catch (_) {
      return 360; // 06:00
    }
  }

  static (int, int) _minuteToHourMin(int totalMinutes) {
    final normalized = (totalMinutes % 1440 + 1440) % 1440;
    return (normalized ~/ 60, normalized % 60);
  }

  /// Schedule all daily recurring nudges (meals 30 mins before, drinks 10 mins before, exact 12-glass water intervals)
  Future<void> scheduleAllDailyNudges({
    String wakeUpTime = "06:00",
    String bedTime = "23:00",
    int napDuration = 0,
    String morningDrink = "jeera",
    String middayDrink = "green_tea",
  }) async {
    if (!_isInitialized) await init();
    await cancelAll();

    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    final tWake = _timeToMinutes(wakeUpTime);
    final tBed = _timeToMinutes(bedTime);

    // -------------------------------------------------------------
    // 1. DRINK & HERBAL NUDGES (10 mins before timetable)
    // -------------------------------------------------------------
    // Morning Detox Drink (10 mins before wake-up / drink slot)
    final (dh1, dm1) = _minuteToHourMin(tWake - 10);
    String morningDrinkTitle = "🌅 Morning Detox Drink in 10 mins";
    String morningDrinkBody = "Start your day with 1 warm glass of Jeera water to boost digestion.";
    if (morningDrink == 'lemon_ginger') {
      morningDrinkTitle = "🍋 Lemon-Ginger Water in 10 mins";
      morningDrinkBody = "Warm lemon-ginger water to activate digestion and immunity.";
    } else if (morningDrink == 'saunf') {
      morningDrinkTitle = "🌿 Saunf Water in 10 mins";
      morningDrinkBody = "Cooling saunf water to soothe digestion and beat bloating.";
    } else if (morningDrink == 'ajwain') {
      morningDrinkTitle = "✨ Ajwain-Methi Water in 10 mins";
      morningDrinkBody = "Warm ajwain water to boost insulin sensitivity and fat burn.";
    } else if (morningDrink == 'cinnamon') {
      morningDrinkTitle = "🪵 Cinnamon Warm Water in 10 mins";
      morningDrinkBody = "Warm cinnamon water to stabilize blood sugar and cravings.";
    }

    await _scheduleDailyNotification(
      id: 101,
      hour: dh1,
      minute: dm1,
      title: morningDrinkTitle,
      body: morningDrinkBody,
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Midday Drink (10 mins before ~5h post wake-up)
    final (dh2, dm2) = _minuteToHourMin(tWake + 290);
    String middayTitle = "☕ Green Tea / Coffee in 10 mins";
    String middayBody = "Time for your metabolism boost! No sugar, no milk.";
    if (middayDrink == 'black_coffee') {
      middayTitle = "☕ Black Coffee in 10 mins";
      middayBody = "Time for your zero-calorie caffeine & focus boost.";
    } else if (middayDrink == 'lemon_tea') {
      middayTitle = "🍋 Warm Lemon Tea in 10 mins";
      middayBody = "Refreshing antioxidant lemon tea break without milk/sugar.";
    } else if (middayDrink == 'buttermilk') {
      middayTitle = "🥛 Spiced Chaas (Buttermilk) in 10 mins";
      middayBody = "Chilled gut-friendly probiotic hydration.";
    }

    await _scheduleDailyNotification(
      id: 102,
      hour: dh2,
      minute: dm2,
      title: middayTitle,
      body: middayBody,
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Evening Snack & Tea (10 mins before ~10h post wake-up)
    final (dh3, dm3) = _minuteToHourMin(tWake + 590);
    await _scheduleDailyNotification(
      id: 103,
      hour: dh3,
      minute: dm3,
      title: "🍵 Evening Green Tea & Snack in 10 mins",
      body: "Prepare your light roasted chana / makhana + green or lemon tea.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // -------------------------------------------------------------
    // 2. MEAL PREPARATION & MEAL NUDGES (30 mins before timetable)
    // -------------------------------------------------------------
    // Breakfast Prep & Eat (30 mins before ~1h 45m post wake-up)
    final (mh1, mm1) = _minuteToHourMin(tWake + 75);
    await _scheduleDailyNotification(
      id: 201,
      hour: mh1,
      minute: mm1,
      title: "🍳 Breakfast Prep in 30 mins",
      body: "Get your high-protein veg breakfast ready! Remember: eat your protein first.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Mid-morning Fruit (15 mins before ~5h 30m post wake-up)
    final (mh2, mm2) = _minuteToHourMin(tWake + 315);
    await _scheduleDailyNotification(
      id: 202,
      hour: mh2,
      minute: mm2,
      title: "🍎 Fresh Fruit Break in 15 mins",
      body: "Grab 1 fresh whole fruit (Apple, Pear, Orange, Papaya) for natural fiber.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Lunch Prep & Meal (30 mins before ~7h post wake-up)
    final (mh3, mm3) = _minuteToHourMin(tWake + 390);
    await _scheduleDailyNotification(
      id: 203,
      hour: mh3,
      minute: mm3,
      title: "🥗 Lunch Prep in 30 mins",
      body: "Time to prep lunch! Golden Rule: Big fresh salad & protein first, rice last.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Optional Power Nap (5 mins before ~8h post wake-up)
    if (napDuration > 0) {
      final (nh, nm) = _minuteToHourMin(tWake + 475);
      await _scheduleDailyNotification(
        id: 205,
        hour: nh,
        minute: nm,
        title: "💤 Power Nap in 5 mins",
        body: "Time for a $napDuration-min restorative nap to lower cortisol and recharge!",
        channelId: taskChannelId,
        channelName: taskChannelName,
        channelDesc: taskChannelDesc,
      );
    }

    // Dinner Prep & Meal (30 mins before ~13h 30m post wake-up)
    final (mh4, mm4) = _minuteToHourMin(tWake + 780);
    await _scheduleDailyNotification(
      id: 204,
      hour: mh4,
      minute: mm4,
      title: "🍲 Dinner Prep in 30 mins",
      body: "Time for light evening dinner (Soup + Paneer/Soya). Zero carbs, roti or rice!",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // -------------------------------------------------------------
    // 3. WORKOUT & ACTIVITY NUDGES
    // -------------------------------------------------------------
    // Fasted Walk (10 mins before ~15m post wake-up)
    final (wh1, wm1) = _minuteToHourMin(tWake + 5);
    await _scheduleDailyNotification(
      id: 301,
      hour: wh1,
      minute: wm1,
      title: "🚶 Fasted Morning Walk in 10 mins",
      body: "Lace up your shoes for a 30-min steady fat-burning walk.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // Evening Walk (15 mins before ~12h post wake-up)
    final (wh2, wm2) = _minuteToHourMin(tWake + 705);
    await _scheduleDailyNotification(
      id: 302,
      hour: wh2,
      minute: wm2,
      title: "🌇 Evening Walk in 15 mins",
      body: "15–20 minutes evening walk to reach today's step count target.",
      channelId: taskChannelId,
      channelName: taskChannelName,
      channelDesc: taskChannelDesc,
    );

    // -------------------------------------------------------------
    // 4. DAILY WATER GOAL INTERVAL NUDGES (Exact 12-Glass Dynamic Schedule)
    // -------------------------------------------------------------
    int wakeWindow = tBed - tWake;
    if (wakeWindow < 600) wakeWindow = 960; // 16 hrs fallback

    const waterGlassLabels = [
      ("Morning Kickstart", "Drink your 1st glass to wake up metabolism and rehydrate!"),
      ("Post-Breakfast Rehydrate", "Glass #2! Keep digestive fluids moving smoothly."),
      ("Morning Energy", "Time for glass #3! Stay sharp and curb premature cravings."),
      ("Mid-Morning Hydration", "Sip glass #4 now! 1 liter mark reached — keep going!"),
      ("Pre-Lunch Satiety", "Drink glass #5 ~45m before lunch for appetite control."),
      ("Halfway Mark - 1.75L!", "Glass #6! You are 50% through your daily water goal!"),
      ("Afternoon Revive", "Defeat the 3 PM afternoon slump with crisp glass #7."),
      ("Pre-Snack Refresh", "Glass #8! Drink a full glass before evening tea/snack."),
      ("Pre-Workout / Walk", "Fuel your evening walk/workout with glass #9 stamina."),
      ("Pre-Dinner Hydration", "Glass #10! Almost there — only 2 glasses left to 3.5L."),
      ("Evening Hydration", "Penultimate glass #11! Smooth finish to daily intake."),
      ("Daily Goal Complete!", "Final glass #12! Congratulations on crushing 3.5L today!"),
    ];

    for (int i = 0; i < 12; i++) {
      final targetMinute = tWake + ((wakeWindow * (i + 0.5)) ~/ 12);
      final (waterH, waterM) = _minuteToHourMin(targetMinute);
      await _scheduleDailyNotification(
        id: 401 + i,
        hour: waterH,
        minute: waterM,
        title: "💧 Glass ${i + 1}/12 (${waterGlassLabels[i].$1})",
        body: waterGlassLabels[i].$2,
        channelId: waterChannelId,
        channelName: waterChannelName,
        channelDesc: waterChannelDesc,
      );
    }

    // -------------------------------------------------------------
    // 5. NIGHTLY REVIEW & WEIGH-IN PREP (45 mins before bedtime)
    // -------------------------------------------------------------
    final (nh, nm) = _minuteToHourMin(tBed - 45);
    await _scheduleDailyNotification(
      id: 501,
      hour: nh,
      minute: nm,
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

    const androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: taskChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@drawable/ic_notification',
      color: Color(0xFF238B55),
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 999,
      title: "🥗 60-Day Veg Fat Loss Nudges Active!",
      body: "You'll get reminders for water goals (12 glasses), meals (30m before), and drinks (10m before).",
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
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/ic_notification',
        color: const Color(0xFF238B55),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (exactErr) {
        // Fallback to inexact if exact alarm permission is not granted on this device
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
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
