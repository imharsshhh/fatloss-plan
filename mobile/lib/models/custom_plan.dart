class PlanPreferences {
  final String wakeUpTime; // "06:00"
  final String bedTime; // "23:00"
  final int napDuration; // 0, 20, 30, 45 mins
  final String morningDrink; // "jeera", "lemon_ginger", "saunf", "ajwain", "cinnamon"
  final String middayDrink; // "green_tea", "black_coffee", "lemon_tea", "buttermilk"
  final List<String> proteins; // ["paneer", "soya_chunks", "moong_dal", ...]
  final List<String> veggies; // ["spinach_palak", "lauki", "mushroom", ...]
  final List<String> grains; // ["oats", "dalia", "brown_rice", ...]
  final List<String> snacks; // ["roasted_makhana", "roasted_chana", ...]
  final String dietGoal; // "fat_loss_high_protein"

  PlanPreferences({
    this.wakeUpTime = "06:00",
    this.bedTime = "23:00",
    this.napDuration = 0,
    this.morningDrink = "jeera",
    this.middayDrink = "green_tea",
    this.proteins = const ["paneer", "soya_chunks", "moong_dal", "sprouts", "besan"],
    this.veggies = const ["spinach_palak", "lauki", "mushroom", "bell_peppers", "cucumber_tomato"],
    this.grains = const ["oats", "dalia", "brown_rice", "poha"],
    this.snacks = const ["roasted_makhana", "roasted_chana", "almonds_walnuts"],
    this.dietGoal = "fat_loss_high_protein",
  });

  factory PlanPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PlanPreferences();
    return PlanPreferences(
      wakeUpTime: map['wakeUpTime'] as String? ?? "06:00",
      bedTime: map['bedTime'] as String? ?? "23:00",
      napDuration: (map['napDuration'] as num?)?.toInt() ?? 0,
      morningDrink: map['morningDrink'] as String? ?? "jeera",
      middayDrink: map['middayDrink'] as String? ?? "green_tea",
      proteins: List<String>.from(map['proteins'] ?? const ["paneer", "soya_chunks", "moong_dal", "sprouts", "besan"]),
      veggies: List<String>.from(map['veggies'] ?? const ["spinach_palak", "lauki", "mushroom", "bell_peppers", "cucumber_tomato"]),
      grains: List<String>.from(map['grains'] ?? const ["oats", "dalia", "brown_rice", "poha"]),
      snacks: List<String>.from(map['snacks'] ?? const ["roasted_makhana", "roasted_chana", "almonds_walnuts"]),
      dietGoal: map['dietGoal'] as String? ?? "fat_loss_high_protein",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wakeUpTime': wakeUpTime,
      'bedTime': bedTime,
      'napDuration': napDuration,
      'morningDrink': morningDrink,
      'middayDrink': middayDrink,
      'proteins': proteins,
      'veggies': veggies,
      'grains': grains,
      'snacks': snacks,
      'dietGoal': dietGoal,
    };
  }

  PlanPreferences copyWith({
    String? wakeUpTime,
    String? bedTime,
    int? napDuration,
    String? morningDrink,
    String? middayDrink,
    List<String>? proteins,
    List<String>? veggies,
    List<String>? grains,
    List<String>? snacks,
    String? dietGoal,
  }) {
    return PlanPreferences(
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      bedTime: bedTime ?? this.bedTime,
      napDuration: napDuration ?? this.napDuration,
      morningDrink: morningDrink ?? this.morningDrink,
      middayDrink: middayDrink ?? this.middayDrink,
      proteins: proteins ?? this.proteins,
      veggies: veggies ?? this.veggies,
      grains: grains ?? this.grains,
      snacks: snacks ?? this.snacks,
      dietGoal: dietGoal ?? this.dietGoal,
    );
  }
}

class CustomPlan {
  final PlanPreferences preferences;
  final List<List<String>> planA; // 7 days, each 5 meals
  final List<List<String>> planB; // 7 days, each 5 meals
  final String generatedAt;

  CustomPlan({
    required this.preferences,
    required this.planA,
    required this.planB,
    required this.generatedAt,
  });

  factory CustomPlan.fromMap(Map<String, dynamic>? map) {
    if (map == null) return CustomPlan.defaultPlan();

    final prefsMap = map['preferences'] as Map<String, dynamic>?;
    final prefs = PlanPreferences.fromMap(prefsMap);

    List<List<String>> parsePlanList(dynamic raw) {
      final parsed = <List<String>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map && item.containsKey('meals') && item['meals'] is List) {
            parsed.add((item['meals'] as List).map((e) => e.toString()).toList());
          } else if (item is List) {
            parsed.add(item.map((e) => e.toString()).toList());
          }
        }
      } else if (raw is Map) {
        final sortedKeys = raw.keys.toList()..sort();
        for (final k in sortedKeys) {
          final val = raw[k];
          if (val is List) {
            parsed.add(val.map((e) => e.toString()).toList());
          } else if (val is Map && val.containsKey('meals') && val['meals'] is List) {
            parsed.add((val['meals'] as List).map((e) => e.toString()).toList());
          }
        }
      }
      return parsed;
    }

    final parsedPlanA = parsePlanList(map['planA']);
    final parsedPlanB = parsePlanList(map['planB']);

    return CustomPlan(
      preferences: prefs,
      planA: parsedPlanA.isNotEmpty ? parsedPlanA : defaultPlanA,
      planB: parsedPlanB.isNotEmpty ? parsedPlanB : defaultPlanB,
      generatedAt: map['generatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferences': preferences.toMap(),
      'planA': planA.map((day) => {'meals': day}).toList(),
      'planB': planB.map((day) => {'meals': day}).toList(),
      'generatedAt': generatedAt,
    };
  }

  static const List<List<String>> defaultPlanA = [
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

  static const List<List<String>> defaultPlanB = [
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

  factory CustomPlan.defaultPlan() {
    return CustomPlan(
      preferences: PlanPreferences(),
      planA: defaultPlanA,
      planB: defaultPlanB,
      generatedAt: DateTime.now().toIso8601String(),
    );
  }
}
