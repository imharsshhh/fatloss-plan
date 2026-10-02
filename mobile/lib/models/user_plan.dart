import 'custom_plan.dart';

class WeightEntry {
  final String date;
  final double weight;

  WeightEntry({required this.date, required this.weight});

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      date: map['d'] as String? ?? '',
      weight: (map['w'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {'d': date, 'w': weight};
}

class UserPlan {
  final String uid;
  final String name;
  final String email;
  final String photoURL;
  final String startDate;
  final double? initialWeight;
  final double? targetWeight;
  final String createdAt;
  final Map<String, int> done; // e.g. "1:0": 1
  final Map<String, int> water; // e.g. "1": 8
  final List<WeightEntry> wts;
  final CustomPlan? customPlan;

  UserPlan({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoURL,
    required this.startDate,
    this.initialWeight,
    this.targetWeight,
    required this.createdAt,
    required this.done,
    required this.water,
    required this.wts,
    this.customPlan,
  });

  factory UserPlan.fromMap(String uid, Map<String, dynamic> map) {
    final rawDone = map['done'] as Map<String, dynamic>? ?? {};
    final parsedDone = <String, int>{};
    rawDone.forEach((k, v) {
      parsedDone[k] = (v as num?)?.toInt() ?? 1;
    });

    final rawWater = map['water'] as Map<String, dynamic>? ?? {};
    final parsedWater = <String, int>{};
    rawWater.forEach((k, v) {
      parsedWater[k] = (v as num?)?.toInt() ?? 0;
    });

    final rawWts = map['wts'] as List<dynamic>? ?? [];
    final parsedWts = rawWts
        .map((e) => WeightEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final customPlanMap = map['customPlan'] as Map<String, dynamic>?;
    final parsedCustomPlan = customPlanMap != null
        ? CustomPlan.fromMap(customPlanMap)
        : null;

    return UserPlan(
      uid: uid,
      name: map['name'] as String? ?? 'Member',
      email: map['email'] as String? ?? '',
      photoURL: map['photoURL'] as String? ?? '',
      startDate: map['startDate'] as String? ??
          DateTime.now().toIso8601String().substring(0, 10),
      initialWeight: (map['initialWeight'] as num?)?.toDouble(),
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      done: parsedDone,
      water: parsedWater,
      wts: parsedWts,
      customPlan: parsedCustomPlan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'startDate': startDate,
      'initialWeight': initialWeight,
      'targetWeight': targetWeight,
      'createdAt': createdAt,
      'done': done,
      'water': water,
      'wts': wts.map((e) => e.toMap()).toList(),
      if (customPlan != null) 'customPlan': customPlan!.toMap(),
    };
  }

  DateTime get startDateTime {
    try {
      return DateTime.parse(startDate);
    } catch (_) {
      return DateTime.now();
    }
  }

  int get currentDay {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final startOnly = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );
    final diff = todayOnly.difference(startOnly).inDays + 1;
    return diff.clamp(1, 60);
  }
}
