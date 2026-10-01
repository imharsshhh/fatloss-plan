class PlanTask {
  final String time;
  final String label;
  final String text;
  final String detail;
  final String kind; // 'm' meal, 'w' walk, 'x' drink, 's' sleep, 'k' workout
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
  static const List<List<String>> planA = [
    [
      "2 moong dal chilla + mint chutney",
      "Apple",
      "Big salad first, then 1 katori dal, ¾ cup rice, stir-fried veggies",
      "Roasted chana (30 g)",
      "Tomato soup + 100 g paneer bhurji"
    ],
    [
      "Sprouts salad (1 bowl) + buttermilk",
      "Orange",
      "Salad, soya chunk curry (30 g dry), ¾ cup rice",
      "Cucumber + carrot sticks",
      "Mixed veg soup + sprouts chaat"
    ],
    [
      "Veg oats (½ cup) with soya granules",
      "Guava or papaya",
      "Salad, rajma/chana (1 katori), ¾ cup rice",
      "5 almonds",
      "Palak soup + grilled paneer 80 g"
    ],
    [
      "2 besan chilla + ½ cup curd",
      "Pear or apple",
      "Salad, soya pulao (30 g soya, ¾ cup rice), raita",
      "Sprouts (½ bowl)",
      "Clear veg soup + 2 soya tikki (air-fried)"
    ],
    [
      "Paneer-veg sandwich (2 brown bread)",
      "Watermelon or papaya",
      "Salad, dal + lauki/tinda sabzi, ¾ cup rice",
      "Roasted makhana (1 cup)",
      "Sweet corn veg soup + moong sprouts salad"
    ],
    [
      "Veg poha with peanuts (1 cup) + curd",
      "Orange",
      "Salad, chole (1 katori), ¾ cup rice",
      "Fruit bowl",
      "Mushroom/tomato soup + air-fried paneer tikka"
    ],
    [
      "2 moong dal cheela + chutney",
      "Small banana",
      "Salad, dal, ¾ cup rice, sabzi (1 small treat OK)",
      "Roasted chana",
      "Pumpkin soup + soya chunk stir-fry"
    ]
  ];

  static const List<List<String>> planB = [
    [
      "Veg upma with soya granules (1 bowl)",
      "Pear",
      "Salad, chana dal, ¾ cup rice, bhindi sabzi",
      "Roasted makhana",
      "Spinach soup + air-fried paneer tikka"
    ],
    [
      "2 paneer-stuffed besan chilla",
      "Orange",
      "Salad, soya keema (30 g dry), ¾ cup rice",
      "Sprouts chaat (½ bowl)",
      "Tomato-carrot soup + sautéed paneer veggies 80 g"
    ],
    [
      "Veg dalia (1 bowl) + moong sprouts",
      "Papaya bowl",
      "Salad, rajma, ¾ cup rice",
      "5 almonds",
      "Mixed veg soup + soya chunk stir-fry"
    ],
    [
      "3 idli + sambar",
      "Apple",
      "Salad, dal tadka, ¾ cup rice, lauki sabzi",
      "Cucumber + roasted chana",
      "Pumpkin soup + paneer bhurji 80 g"
    ],
    [
      "2 oats chilla + ½ cup curd",
      "Guava",
      "Salad, chole, ¾ cup rice",
      "Roasted makhana",
      "Sweet corn soup + sprouts salad"
    ],
    [
      "Veg dalia (1 bowl) + curd",
      "Orange",
      "Salad, soya pulao (¾ cup rice), raita",
      "Fruit bowl",
      "Mushroom soup + air-fried paneer tikka"
    ],
    [
      "2 besan chilla + chutney",
      "Small banana",
      "Salad, dal, ¾ cup rice, sabzi (1 small treat OK)",
      "Roasted chana",
      "Clear veg soup + 2 soya tikki (air-fried)"
    ]
  ];

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

  static DateTime getDateForDay(int dayNumber, DateTime startDate) {
    return startDate.add(Duration(days: dayNumber - 1));
  }

  static List<PlanTask> buildSchedule(int dayNumber, DateTime startDate) {
    final d = getDateForDay(dayNumber, startDate);
    final wd = d.weekday; // 1 = Mon, 7 = Sun
    final w = ((dayNumber - 1) ~/ 7) + 1;
    final mi = (wd - 1) % 7;
    final menu = (w % 2 != 0 ? planA : planB)[mi];
    final isWeekday = wd >= 1 && wd <= 5;
    final isSaturday = wd == 6;

    final sw = w <= 2 ? s1 : w <= 4 ? s2 : s3;
    final mins = w <= 2 ? 20 : w <= 4 ? 28 : w <= 6 ? 30 : 35;
    final isStrengthDay = wd == 1 || wd == 3 || wd == 5; // Mon, Wed, Fri

    final list = <PlanTask>[
      PlanTask(
        time: "06:00",
        label: "Wake up",
        text: "Jeera water, 1 glass",
        detail: "Start of your eating-window clock.",
        kind: "x",
        emoji: "🌅",
      ),
    ];

    if (isWeekday) {
      list.addAll([
        PlanTask(
          time: "06:15",
          label: "Fasted walk",
          text: "30 minutes",
          detail: "Easy pace, no running.",
          kind: "w",
          emoji: "🚶",
        ),
        PlanTask(
          time: "06:45",
          label: isStrengthDay ? "Strength" : "Yoga",
          text: isStrengthDay ? "$mins min" : "20 min stretching",
          detail: isStrengthDay ? sw : "Light stretching and breathing.",
          kind: "k",
          emoji: isStrengthDay ? "🏋️" : "🧘",
        ),
        PlanTask(
          time: "07:45",
          label: "Breakfast",
          text: menu[0],
          detail: "Protein first, then the rest.",
          kind: "m",
          emoji: breakfastEmoji(menu[0]),
        ),
        PlanTask(
          time: "11:00",
          label: "Coffee / lemon tea",
          text: "Black coffee or lemon tea",
          detail: "No sugar, no milk. Max 2 coffees.",
          kind: "x",
          emoji: "☕",
        ),
        PlanTask(
          time: "11:30",
          label: "Fruit",
          text: menu[1],
          detail: "1 serving.",
          kind: "m",
          emoji: fruitEmoji(menu[1]),
        ),
        PlanTask(
          time: "13:00",
          label: "Lunch",
          text: menu[2],
          detail: "Salad and protein first, rice last.",
          kind: "m",
          emoji: "🍛",
        ),
        PlanTask(
          time: "13:20",
          label: "Walk",
          text: "10–15 minutes",
          detail: "Helps digestion, adds steps.",
          kind: "w",
          emoji: "🚶",
        ),
        PlanTask(
          time: "16:00",
          label: "Snack",
          text: "${menu[3]} + lemon tea",
          detail: "No sugar.",
          kind: "m",
          emoji: snackEmoji(menu[3]),
        ),
        PlanTask(
          time: "18:00",
          label: "Evening walk",
          text: "15–20 minutes",
          detail: "On the way home or at home.",
          kind: "w",
          emoji: "🌇",
        ),
        PlanTask(
          time: "19:30",
          label: "Dinner",
          text: menu[4],
          detail: "No roti, rice, fruit or namkeen.",
          kind: "m",
          emoji: dinnerEmoji(menu[4]),
        ),
        PlanTask(
          time: "20:00",
          label: "Slow walk",
          text: "10 minutes",
          detail: "",
          kind: "w",
          emoji: "👟",
        ),
      ]);
    } else {
      list.addAll([
        PlanTask(
          time: "06:15",
          label: isSaturday ? "Fasted walk" : "Brisk walk / hike",
          text: isSaturday ? "40 minutes" : "45–60 minutes",
          detail: w >= 5 && isSaturday
              ? "Add 5 × 1 min brisk intervals."
              : "Steady pace.",
          kind: "w",
          emoji: "🚶",
        ),
        PlanTask(
          time: "07:00",
          label: isSaturday ? "Strength" : "Yoga",
          text: isSaturday ? "30 min" : "20 min stretching",
          detail: isSaturday ? sw : "Stretch and relax.",
          kind: "k",
          emoji: isSaturday ? "🏋️" : "🧘",
        ),
        PlanTask(
          time: "08:30",
          label: "Breakfast",
          text: menu[0],
          detail: "Protein first.",
          kind: "m",
          emoji: breakfastEmoji(menu[0]),
        ),
        PlanTask(
          time: "11:00",
          label: "Black coffee",
          text: "No sugar, no milk",
          detail: "",
          kind: "x",
          emoji: "☕",
        ),
        PlanTask(
          time: "11:30",
          label: "Fruit",
          text: menu[1],
          detail: "1 serving.",
          kind: "m",
          emoji: fruitEmoji(menu[1]),
        ),
        PlanTask(
          time: "13:00",
          label: "Lunch",
          text: menu[2],
          detail: "Salad and protein first, rice last.",
          kind: "m",
          emoji: "🍛",
        ),
        PlanTask(
          time: "16:30",
          label: "Snack",
          text: "${menu[3]} + lemon tea",
          detail: "No sugar.",
          kind: "m",
          emoji: snackEmoji(menu[3]),
        ),
        PlanTask(
          time: "17:30",
          label: isSaturday ? "Evening walk" : "Meal prep",
          text: isSaturday ? "30 minutes" : "Boil sprouts, make soup, soak soya",
          detail: isSaturday ? "" : "Sets up the week.",
          kind: isSaturday ? "w" : "x",
          emoji: isSaturday ? "🌇" : "🥘",
        ),
        PlanTask(
          time: "19:30",
          label: "Dinner",
          text: menu[4],
          detail: "No roti, rice, fruit or namkeen.",
          kind: "m",
          emoji: dinnerEmoji(menu[4]),
        ),
        PlanTask(
          time: "20:00",
          label: "Slow walk",
          text: "10 minutes",
          detail: "",
          kind: "w",
          emoji: "👟",
        ),
      ]);
    }

    list.addAll([
      PlanTask(
        time: "21:00",
        label: "Lemon-honey water",
        text: "1 glass, 1 tsp honey max",
        detail: "",
        kind: "x",
        emoji: "🍋",
      ),
      PlanTask(
        time: "22:15",
        label: "Wind down",
        text: "Phone off",
        detail: "",
        kind: "s",
        emoji: "📵",
      ),
      PlanTask(
        time: "23:00",
        label: "Sleep",
        text: "About 7 hours",
        detail: "Poor sleep slows fat loss.",
        kind: "s",
        emoji: "😴",
      ),
    ]);

    return list;
  }
}
