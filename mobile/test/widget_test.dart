import 'package:flutter_test/flutter_test.dart';
import 'package:fatloss_app/models/plan_data.dart';

void main() {
  test('PlanData generates 60-day schedules accurately', () {
    final start = DateTime(2026, 10, 1);
    final day1Schedule = PlanData.buildSchedule(1, start);
    expect(day1Schedule.isNotEmpty, true);
    expect(day1Schedule.first.label, "Wake up");

    final day60Schedule = PlanData.buildSchedule(60, start);
    expect(day60Schedule.isNotEmpty, true);
  });
}
