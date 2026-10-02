import 'custom_plan.dart';

class PlanTask {
  final String time;
  final String label;
  final String text;
  final String detail;
  final String kind; // 'm' meal, 'w' walk, 'x' drink, 's' sleep, 'k' workout, 'n' nap
  final String emoji;

  PlanTask({
    required this.time,
    required this.label,
    required this.text,
    required this.detail,
    required this.kind,
    required this.emoji,
  });

  String get formattedTime {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final min = parts[1];
      final h = hour % 12 == 0 ? 12 : hour % 12;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      return '$h:$min $ampm';
    } catch (_) {
      return time;
    }
  }
}

class PlanData {
  static const List<List<String>> planA = CustomPlan.defaultPlanA;
  static const List<List<String>> planB = CustomPlan.defaultPlanB;

  static const List<String> phases = [
    "Build routine",
    "Build routine",
    "Step up",
    "Step up",
    "Intensify",
    "Intensify",
    "Final push",
    "Final push",
    "Review"
  ];

  static const List<String> stepsTarget = [
    "6–8k",
    "6–8k",
    "8–10k",
    "8–10k",
    "10k",
    "10k",
    "10–12k",
    "10–12k",
    "10k"
  ];

  static const String s1 =
      "Squats ×15, wall/incline pushups ×10–12, glute bridges ×15, plank 30–45 s. 2–3 rounds.";
  static const String s2 =
      "Squats ×15, pushups ×10–12, glute bridges ×15, lunges ×10/leg, plank 45 s. 3 rounds.";
  static const String s3 = "$s2 Add band/dumbbell rows ×12.";

  static String fruitEmoji(String t) {
    if (RegExp(r'orange', caseSensitive: false).hasMatch(t)) return "🍊";
    if (RegExp(r'apple', caseSensitive: false).hasMatch(t)) return "🍎";
    if (RegExp(r'pear', caseSensitive: false).hasMatch(t)) return "🍐";
    if (RegExp(r'banana', caseSensitive: false).hasMatch(t)) return "🍌";
    if (RegExp(r'watermelon', caseSensitive: false).hasMatch(t)) return "🍉";
    if (RegExp(r'guava|papaya', caseSensitive: false).hasMatch(t)) return "🥭";
    return "🍎";
  }

  static String breakfastEmoji(String t) {
    if (RegExp(r'chilla|cheela', caseSensitive: false).hasMatch(t)) return "🥞";
    if (RegExp(r'sandwich', caseSensitive: false).hasMatch(t)) return "🥪";
    if (RegExp(r'idli', caseSensitive: false).hasMatch(t)) return "🍙";
    return "🥣";
  }

  static String snackEmoji(String t) {
    if (RegExp(r'almond', caseSensitive: false).hasMatch(t)) return "🌰";
    if (RegExp(r'sprout', caseSensitive: false).hasMatch(t)) return "🌱";
    if (RegExp(r'cucumber|carrot', caseSensitive: false).hasMatch(t)) return "🥕";
    if (RegExp(r'fruit', caseSensitive: false).hasMatch(t)) return "🍓";
    return "🥜";
  }

  static String dinnerEmoji(String t) {
    if (RegExp(r'paneer', caseSensitive: false).hasMatch(t)) return "🧀";
    return "🍲";
  }

  static int timeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    } catch (_) {
      return 360; // 06:00
    }
  }

  static String minutesToTime(int totalMinutes) {
    final normalized = (totalMinutes % 1440 + 1440) % 1440;
    final h = (normalized ~/ 60).toString().padLeft(2, '0');
    final m = (normalized % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static DateTime getDateForDay(int dayNumber, DateTime startDate) {
    return startDate.add(Duration(days: dayNumber - 1));
  }

  static List<PlanTask> buildSchedule(
    int dayNumber,
    DateTime startDate, {
    CustomPlan? customPlan,
  }) {
    final d = getDateForDay(dayNumber, startDate);
    final wd = d.weekday; // 1 = Mon, 7 = Sun
    final w = ((dayNumber - 1) ~/ 7) + 1;
    final mi = (wd - 1) % 7;

    final planSourceA = customPlan?.planA ?? planA;
    final planSourceB = customPlan?.planB ?? planB;
    final menu = (w % 2 != 0 ? planSourceA : planSourceB)[mi % 7];

    final isWeekday = wd >= 1 && wd <= 5;
    final isSaturday = wd == 6;

    final sw = w <= 2 ? s1 : w <= 4 ? s2 : s3;
    final mins = w <= 2 ? 20 : w <= 4 ? 28 : w <= 6 ? 30 : 35;
    final isStrengthDay = wd == 1 || wd == 3 || wd == 5; // Mon, Wed, Fri

    // Dynamic Time Calculation based on user preferences
    final prefs = customPlan?.preferences ?? PlanPreferences();
    final tWake = timeToMinutes(prefs.wakeUpTime);
    final tBed = timeToMinutes(prefs.bedTime);

    String morningDrinkTitle = "Jeera water, 1 glass";
    String morningDrinkEmoji = "🌅";
    switch (prefs.morningDrink) {
      case 'lemon_ginger':
        morningDrinkTitle = "Warm Lemon-Ginger water, 1 glass";
        morningDrinkEmoji = "🍋";
        break;
      case 'saunf':
        morningDrinkTitle = "Warm Saunf (Fennel) water, 1 glass";
        morningDrinkEmoji = "🌿";
        break;
      case 'ajwain':
        morningDrinkTitle = "Warm Ajwain-Methi water, 1 glass";
        morningDrinkEmoji = "✨";
        break;
      case 'cinnamon':
        morningDrinkTitle = "Warm Cinnamon water, 1 glass";
        morningDrinkEmoji = "🪵";
        break;
      default:
        morningDrinkTitle = "Warm Jeera water, 1 glass";
        morningDrinkEmoji = "🌅";
    }

    String middayDrinkTitle = "Green tea / lemon tea";
    String middayDrinkEmoji = "🍵";
    switch (prefs.middayDrink) {
      case 'black_coffee':
        middayDrinkTitle = "Black coffee (no milk, no sugar)";
        middayDrinkEmoji = "☕";
        break;
      case 'lemon_tea':
        middayDrinkTitle = "Warm lemon tea (no sugar)";
        middayDrinkEmoji = "🍋";
        break;
      case 'buttermilk':
        middayDrinkTitle = "Chilled spiced buttermilk (chaas)";
        middayDrinkEmoji = "🥛";
        break;
      default:
        middayDrinkTitle = "Green tea or lemon tea";
        middayDrinkEmoji = "🍵";
    }

    final list = <PlanTask>[
      PlanTask(
        time: minutesToTime(tWake),
        label: "Wake up",
        text: morningDrinkTitle,
        detail: "Start of your eating-window clock.",
        kind: "x",
        emoji: morningDrinkEmoji,
      ),
    ];

    if (isWeekday) {
      list.addAll([
        PlanTask(
          time: minutesToTime(tWake + 15),
          label: "Fasted walk",
          text: "30 minutes",
          detail: "Easy pace, no running.",
          kind: "w",
          emoji: "🚶",
        ),
        PlanTask(
          time: minutesToTime(tWake + 45),
          label: isStrengthDay ? "Strength" : "Yoga",
          text: isStrengthDay ? "$mins min" : "20 min stretching",
          detail: isStrengthDay ? sw : "Light stretching and breathing.",
          kind: "k",
          emoji: isStrengthDay ? "🏋️" : "🧘",
        ),
        PlanTask(
          time: minutesToTime(tWake + 105), // ~1h 45m post wakeup
          label: "Breakfast",
          text: menu[0],
          detail: "Protein first, then the rest.",
          kind: "m",
          emoji: breakfastEmoji(menu[0]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 300), // ~5h post wakeup
          label: "Mid-day Drink",
          text: middayDrinkTitle,
          detail: "No sugar, no milk. Pure metabolism boost.",
          kind: "x",
          emoji: middayDrinkEmoji,
        ),
        PlanTask(
          time: minutesToTime(tWake + 330), // ~5h 30m post wakeup
          label: "Fruit",
          text: menu[1],
          detail: "1 serving.",
          kind: "m",
          emoji: fruitEmoji(menu[1]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 420), // ~7h post wakeup (e.g. 13:00)
          label: "Lunch",
          text: menu[2],
          detail: "Salad and protein first, rice last.",
          kind: "m",
          emoji: "🍛",
        ),
        PlanTask(
          time: minutesToTime(tWake + 440),
          label: "Walk",
          text: "10–15 minutes",
          detail: "Helps digestion, adds steps.",
          kind: "w",
          emoji: "🚶",
        ),
      ]);

      // Optional Nap slot
      if (prefs.napDuration > 0) {
        list.add(
          PlanTask(
            time: minutesToTime(tWake + 480), // ~8h post wakeup (e.g. 14:00)
            label: "Power Nap",
            text: "${prefs.napDuration} minutes restorative rest",
            detail: "Quick power nap to lower cortisol and recharge focus.",
            kind: "s",
            emoji: "💤",
          ),
        );
      }

      list.addAll([
        PlanTask(
          time: minutesToTime(tWake + 600), // ~10h post wakeup (e.g. 16:00)
          label: "Snack",
          text: "${menu[3]} + lemon tea",
          detail: "No sugar.",
          kind: "m",
          emoji: snackEmoji(menu[3]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 720), // ~12h post wakeup (e.g. 18:00)
          label: "Evening walk",
          text: "15–20 minutes",
          detail: "On the way home or at home.",
          kind: "w",
          emoji: "🌇",
        ),
        PlanTask(
          time: minutesToTime(tWake + 810), // ~13h 30m post wakeup (e.g. 19:30)
          label: "Dinner",
          text: menu[4],
          detail: "No roti, rice, fruit or namkeen.",
          kind: "m",
          emoji: dinnerEmoji(menu[4]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 840),
          label: "Slow walk",
          text: "10 minutes",
          detail: "",
          kind: "w",
          emoji: "👟",
        ),
      ]);
    } else {
      // Weekend Schedule
      list.addAll([
        PlanTask(
          time: minutesToTime(tWake + 15),
          label: isSaturday ? "Fasted walk" : "Brisk walk / hike",
          text: isSaturday ? "40 minutes" : "45–60 minutes",
          detail: w >= 5 && isSaturday
              ? "Add 5 × 1 min brisk intervals."
              : "Steady pace.",
          kind: "w",
          emoji: "🚶",
        ),
        PlanTask(
          time: minutesToTime(tWake + 60),
          label: isSaturday ? "Strength" : "Yoga",
          text: isSaturday ? "30 min" : "20 min stretching",
          detail: isSaturday ? sw : "Stretch and relax.",
          kind: "k",
          emoji: isSaturday ? "🏋️" : "🧘",
        ),
        PlanTask(
          time: minutesToTime(tWake + 150),
          label: "Breakfast",
          text: menu[0],
          detail: "Protein first.",
          kind: "m",
          emoji: breakfastEmoji(menu[0]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 300),
          label: "Mid-day Drink",
          text: middayDrinkTitle,
          detail: "No sugar, no milk",
          kind: "x",
          emoji: middayDrinkEmoji,
        ),
        PlanTask(
          time: minutesToTime(tWake + 330),
          label: "Fruit",
          text: menu[1],
          detail: "1 serving.",
          kind: "m",
          emoji: fruitEmoji(menu[1]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 420),
          label: "Lunch",
          text: menu[2],
          detail: "Salad and protein first, rice last.",
          kind: "m",
          emoji: "🍛",
        ),
      ]);

      if (prefs.napDuration > 0) {
        list.add(
          PlanTask(
            time: minutesToTime(tWake + 480),
            label: "Weekend Nap",
            text: "${prefs.napDuration} minutes afternoon sleep",
            detail: "Rest and muscle recovery.",
            kind: "s",
            emoji: "💤",
          ),
        );
      }

      list.addAll([
        PlanTask(
          time: minutesToTime(tWake + 630),
          label: "Snack",
          text: "${menu[3]} + lemon tea",
          detail: "No sugar.",
          kind: "m",
          emoji: snackEmoji(menu[3]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 690),
          label: isSaturday ? "Evening walk" : "Meal prep",
          text: isSaturday ? "30 minutes" : "Boil sprouts, make soup, soak soya",
          detail: isSaturday ? "" : "Sets up the week.",
          kind: isSaturday ? "w" : "x",
          emoji: isSaturday ? "🌇" : "🥘",
        ),
        PlanTask(
          time: minutesToTime(tWake + 810),
          label: "Dinner",
          text: menu[4],
          detail: "No roti, rice, fruit or namkeen.",
          kind: "m",
          emoji: dinnerEmoji(menu[4]),
        ),
        PlanTask(
          time: minutesToTime(tWake + 840),
          label: "Slow walk",
          text: "10 minutes",
          detail: "",
          kind: "w",
          emoji: "👟",
        ),
      ]);
    }

    // Night wind down and bedtime
    list.addAll([
      PlanTask(
        time: minutesToTime(tBed - 60),
        label: "Lemon-honey / Saunf water",
        text: "1 warm glass, 1 tsp honey max",
        detail: "Calming digestif before sleep.",
        kind: "x",
        emoji: "🍋",
      ),
      PlanTask(
        time: minutesToTime(tBed - 45),
        label: "Wind down",
        text: "Phone off, read or meditate",
        detail: "Lower blue light exposure.",
        kind: "s",
        emoji: "📵",
      ),
      PlanTask(
        time: minutesToTime(tBed),
        label: "Sleep",
        text: "7–8 hours restorative sleep",
        detail: "Poor sleep slows fat loss.",
        kind: "s",
        emoji: "😴",
      ),
    ]);

    return list;
  }
}
