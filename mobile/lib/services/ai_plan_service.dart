import '../models/custom_plan.dart';

class AiPlanService {
  static final AiPlanService _instance = AiPlanService._internal();
  factory AiPlanService() => _instance;
  AiPlanService._internal();

  /// Available options for UI selection
  static const List<Map<String, String>> proteinOptions = [
    {'id': 'paneer', 'name': 'Paneer (Cottage Cheese)', 'emoji': '🧀'},
    {'id': 'soya_chunks', 'name': 'Soya Chunks & Granules', 'emoji': '🌱'},
    {'id': 'moong_dal', 'name': 'Moong Dal & Chilla', 'emoji': '🥞'},
    {'id': 'sprouts', 'name': 'Moong & Chana Sprouts', 'emoji': '🥗'},
    {'id': 'besan', 'name': 'Besan (Gram Flour)', 'emoji': '🫓'},
    {'id': 'tofu', 'name': 'Tofu (Soy Paneer)', 'emoji': '🧊'},
    {'id': 'chana_chole', 'name': 'Chole / Chickpeas', 'emoji': '🧆'},
    {'id': 'rajma', 'name': 'Rajma (Kidney Beans)', 'emoji': '🍲'},
    {'id': 'curd_yogurt', 'name': 'Curd / Greek Yogurt', 'emoji': '🥣'},
  ];

  static const List<Map<String, String>> veggieOptions = [
    {'id': 'spinach_palak', 'name': 'Spinach / Palak', 'emoji': '🥬'},
    {'id': 'lauki', 'name': 'Lauki / Bottle Gourd', 'emoji': '🥒'},
    {'id': 'mushroom', 'name': 'Mushrooms', 'emoji': '🍄'},
    {'id': 'bell_peppers', 'name': 'Bell Peppers & Capsicum', 'emoji': '🫑'},
    {'id': 'broccoli', 'name': 'Broccoli', 'emoji': '🥦'},
    {'id': 'methi', 'name': 'Methi / Fenugreek', 'emoji': '🌿'},
    {'id': 'cucumber_tomato', 'name': 'Fresh Cucumber & Tomato', 'emoji': '🥗'},
    {'id': 'sweet_corn', 'name': 'Sweet Corn', 'emoji': '🌽'},
    {'id': 'pumpkin', 'name': 'Pumpkin / Kaddu', 'emoji': '🎃'},
  ];

  static const List<Map<String, String>> grainOptions = [
    {'id': 'oats', 'name': 'Rolled Oats', 'emoji': '🥣'},
    {'id': 'dalia', 'name': 'Broken Wheat / Dalia', 'emoji': '🌾'},
    {'id': 'brown_rice', 'name': 'Brown / White Rice (Portion-controlled)', 'emoji': '🍚'},
    {'id': 'poha', 'name': 'Veg Poha', 'emoji': '🥘'},
    {'id': 'quinoa', 'name': 'Quinoa', 'emoji': '🍲'},
    {'id': 'multigrain_bread', 'name': 'Brown / Multigrain Bread', 'emoji': '🥪'},
  ];

  static const List<Map<String, String>> morningDrinkOptions = [
    {'id': 'jeera', 'name': 'Warm Jeera (Cumin) Water', 'emoji': '🌅', 'desc': 'Digestive boost'},
    {'id': 'lemon_ginger', 'name': 'Warm Lemon-Ginger Water', 'emoji': '🍋', 'desc': 'Metabolism & immunity'},
    {'id': 'saunf', 'name': 'Saunf (Fennel) Water', 'emoji': '🌿', 'desc': 'Cooling & gut-friendly'},
    {'id': 'ajwain', 'name': 'Ajwain-Methi Water', 'emoji': '✨', 'desc': 'Bloat relief & insulin health'},
    {'id': 'cinnamon', 'name': 'Cinnamon Warm Water', 'emoji': '🪵', 'desc': 'Craving suppressor'},
  ];

  static const List<Map<String, String>> middayDrinkOptions = [
    {'id': 'green_tea', 'name': 'Green Tea / Lemon Green Tea', 'emoji': '🍵', 'desc': 'Antioxidants & fat burn'},
    {'id': 'black_coffee', 'name': 'Black Coffee (No Milk, No Sugar)', 'emoji': '☕', 'desc': 'Focus & thermogenesis'},
    {'id': 'lemon_tea', 'name': 'Warm Lemon Tea', 'emoji': '🍋', 'desc': 'Zero caffeine refresher'},
    {'id': 'buttermilk', 'name': 'Spiced Buttermilk (Chaas)', 'emoji': '🥛', 'desc': 'Hydrating probiotic'},
  ];

  static const List<Map<String, String>> snackOptions = [
    {'id': 'roasted_makhana', 'name': 'Roasted Makhana (Foxnuts)', 'emoji': '🍿'},
    {'id': 'roasted_chana', 'name': 'Roasted Chana (30g)', 'emoji': '🥜'},
    {'id': 'sprouts_chaat', 'name': 'Lemon Moong Sprouts Chaat', 'emoji': '🥗'},
    {'id': 'almonds_walnuts', 'name': '5 Soaked Almonds & Walnuts', 'emoji': '🌰'},
    {'id': 'cucumber_carrot', 'name': 'Cucumber & Carrot Sticks', 'emoji': '🥕'},
    {'id': 'fruit_bowl', 'name': 'Seasonal Fresh Fruit Bowl', 'emoji': '🍓'},
  ];

  /// Generates a customized 14-day rotational fat-loss plan (Plan A & Plan B)
  /// using the user's selected preferences.
  Future<CustomPlan> generateCustomPlan(PlanPreferences prefs) async {
    // Artificial small delay for smooth AI generation UX
    await Future.delayed(const Duration(milliseconds: 600));

    final hasPaneer = prefs.proteins.contains('paneer');
    final hasSoya = prefs.proteins.contains('soya_chunks');
    final hasMoong = prefs.proteins.contains('moong_dal');
    final hasSprouts = prefs.proteins.contains('sprouts');
    final hasBesan = prefs.proteins.contains('besan');
    final hasTofu = prefs.proteins.contains('tofu');
    final hasOats = prefs.grains.contains('oats');
    final hasDalia = prefs.grains.contains('dalia');
    final hasPoha = prefs.grains.contains('poha');
    final hasBread = prefs.grains.contains('multigrain_bread');

    // Build curated breakfast pool
    final breakfastPool = <String>[];
    if (hasMoong) breakfastPool.add("2 moong dal chilla + mint chutney");
    if (hasBesan && hasPaneer) breakfastPool.add("2 paneer-stuffed besan chilla");
    if (hasBesan) breakfastPool.add("2 besan chilla + ½ cup curd");
    if (hasOats && hasSoya) breakfastPool.add("Veg oats (½ cup) with soya granules");
    if (hasOats) breakfastPool.add("2 oats chilla + ½ cup curd");
    if (hasSprouts) breakfastPool.add("Sprouts salad (1 bowl) + buttermilk");
    if (hasBread && hasPaneer) breakfastPool.add("Paneer-veg sandwich (2 brown bread)");
    if (hasBread && hasTofu) breakfastPool.add("Grilled tofu sandwich (2 brown bread)");
    if (hasDalia) breakfastPool.add("Veg dalia (1 bowl) + moong sprouts");
    if (hasPoha) breakfastPool.add("Veg poha with roasted peanuts (1 cup) + curd");
    if (hasSoya) breakfastPool.add("Veg upma with soya granules (1 bowl)");
    if (breakfastPool.isEmpty) {
      breakfastPool.addAll([
        "2 moong dal chilla + mint chutney",
        "Sprouts salad (1 bowl) + buttermilk",
        "2 besan chilla + ½ cup curd",
        "Veg oats with soya granules",
        "Paneer-veg sandwich (2 brown bread)",
        "3 idli + sambar",
        "Veg dalia (1 bowl) + moong sprouts",
      ]);
    }

    // Build fruit pool
    final fruitPool = [
      "Apple",
      "Orange",
      "Guava or papaya",
      "Pear or apple",
      "Watermelon or papaya",
      "Sweet orange / kiwi",
      "Small banana or peach",
    ];

    // Build lunch pool
    final lunchPool = <String>[];
    if (hasPaneer) lunchPool.add("Salad first, paneer bhurji (100 g), ¾ cup rice, stir-fried veggies");
    if (hasSoya) lunchPool.add("Salad, soya chunk curry (30 g dry), ¾ cup rice");
    if (hasSoya) lunchPool.add("Salad, soya pulao (30 g soya, ¾ cup rice), cucumber raita");
    lunchPool.add("Salad, rajma/chana (1 katori), ¾ cup rice");
    lunchPool.add("Salad, dal + lauki/tinda sabzi, ¾ cup rice");
    lunchPool.add("Salad, chole (1 katori), ¾ cup rice");
    lunchPool.add("Salad, chana dal tadka, ¾ cup rice, bhindi/capsicum sabzi");
    if (hasTofu) lunchPool.add("Salad, stir-fried tofu veggies (100 g), ¾ cup rice");

    // Build snack pool
    final snackPool = <String>[];
    if (prefs.snacks.contains('roasted_chana')) snackPool.add("Roasted chana (30 g)");
    if (prefs.snacks.contains('roasted_makhana')) snackPool.add("Roasted makhana (1 cup)");
    if (prefs.snacks.contains('sprouts_chaat')) snackPool.add("Sprouts chaat (½ bowl)");
    if (prefs.snacks.contains('almonds_walnuts')) snackPool.add("5 soaked almonds & walnuts");
    if (prefs.snacks.contains('cucumber_carrot')) snackPool.add("Cucumber + carrot sticks with hummus");
    if (prefs.snacks.contains('fruit_bowl')) snackPool.add("Small mixed fruit bowl");
    if (snackPool.isEmpty) {
      snackPool.addAll(["Roasted chana (30 g)", "Roasted makhana", "Sprouts chaat", "5 almonds"]);
    }

    // Build dinner pool
    final dinnerPool = <String>[];
    if (hasPaneer) dinnerPool.add("Tomato soup + 100 g paneer bhurji (No carbs)");
    if (hasPaneer) dinnerPool.add("Palak soup + grilled paneer 80 g (No carbs)");
    if (hasPaneer) dinnerPool.add("Mushroom/tomato soup + air-fried paneer tikka");
    if (hasSoya) dinnerPool.add("Clear veg soup + 2 soya tikki (air-fried)");
    if (hasSoya) dinnerPool.add("Pumpkin soup + soya chunk stir-fry");
    if (hasSprouts) dinnerPool.add("Mixed veg soup + sprouts chaat");
    if (hasTofu) dinnerPool.add("Sweet corn veg soup + grilled tofu & broccoli");
    if (dinnerPool.isEmpty) {
      dinnerPool.addAll([
        "Tomato soup + 100 g paneer bhurji",
        "Mixed veg soup + sprouts chaat",
        "Palak soup + grilled paneer 80 g",
        "Clear veg soup + 2 soya tikki (air-fried)",
        "Sweet corn veg soup + moong sprouts salad",
        "Mushroom/tomato soup + air-fried paneer tikka",
        "Pumpkin soup + soya chunk stir-fry",
      ]);
    }

    // Synthesize 7 days of Plan A
    final planA = <List<String>>[];
    for (int i = 0; i < 7; i++) {
      planA.add([
        breakfastPool[i % breakfastPool.length],
        fruitPool[i % fruitPool.length],
        lunchPool[i % lunchPool.length],
        snackPool[i % snackPool.length],
        dinnerPool[i % dinnerPool.length],
      ]);
    }

    // Synthesize 7 days of Plan B (shifted/varied)
    final planB = <List<String>>[];
    for (int i = 0; i < 7; i++) {
      final bIdx = (i + 3) % breakfastPool.length;
      final fIdx = (i + 2) % fruitPool.length;
      final lIdx = (i + 4) % lunchPool.length;
      final sIdx = (i + 1) % snackPool.length;
      final dIdx = (i + 3) % dinnerPool.length;

      planB.add([
        breakfastPool[bIdx],
        fruitPool[fIdx],
        lunchPool[lIdx],
        snackPool[sIdx],
        dinnerPool[dIdx],
      ]);
    }

    return CustomPlan(
      preferences: prefs,
      planA: planA,
      planB: planB,
      generatedAt: DateTime.now().toIso8601String(),
    );
  }
}
