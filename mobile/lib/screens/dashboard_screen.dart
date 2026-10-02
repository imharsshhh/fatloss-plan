import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_plan.dart';
import '../models/plan_data.dart';
import '../services/firestore_service.dart';
import 'profile_dialog.dart';
import 'ai_customizer_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final UserPlan userPlan;
  const DashboardScreen({super.key, required this.userPlan});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedDay;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _weightInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.userPlan.currentDay;
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedDay > 60) _selectedDay = 60;
    if (_selectedDay < 1) _selectedDay = 1;
  }

  @override
  void dispose() {
    _weightInputController.dispose();
    super.dispose();
  }

  Future<void> _toggleTask(int taskIndex, bool currentStatus) async {
    await _firestoreService.toggleTask(
      uid: widget.userPlan.uid,
      dayNumber: _selectedDay,
      taskIndex: taskIndex,
      completed: !currentStatus,
      currentDone: widget.userPlan.done,
    );
  }

  Future<void> _setWater(int glasses) async {
    final currentVal = widget.userPlan.water['$_selectedDay'] ?? 0;
    final newVal = (currentVal == glasses) ? glasses - 1 : glasses;
    await _firestoreService.updateWater(
      uid: widget.userPlan.uid,
      dayNumber: _selectedDay,
      glasses: newVal,
      currentWater: widget.userPlan.water,
    );
  }

  Future<void> _saveWeight() async {
    final val = double.tryParse(_weightInputController.text.trim());
    if (val == null || val <= 0) return;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _firestoreService.logWeight(
      uid: widget.userPlan.uid,
      date: todayStr,
      weight: val,
      currentWts: widget.userPlan.wts,
    );
    _weightInputController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Weight saved to cloud!"),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (context) => ProfileDialog(userPlan: widget.userPlan),
    );
  }

  void _showAiCustomizer() {
    showDialog(
      context: context,
      builder: (context) => AiCustomizerDialog(userPlan: widget.userPlan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plan = widget.userPlan;
    final schedule = PlanData.buildSchedule(
      _selectedDay,
      plan.startDateTime,
      customPlan: plan.customPlan,
    );
    final currentDayDate = PlanData.getDateForDay(_selectedDay, plan.startDateTime);
    final weekNum = ((_selectedDay - 1) ~/ 7) + 1;
    final phaseName = PlanData.phases[(weekNum - 1).clamp(0, PlanData.phases.length - 1)];

    // Completed tasks count for current selected day
    int completedCount = 0;
    for (int i = 0; i < schedule.length; i++) {
      if (plan.done['$_selectedDay:$i'] == 1) completedCount++;
    }

    final waterCount = plan.water['$_selectedDay'] ?? 0;

    // Weight difference calculation
    final sortedWts = List<WeightEntry>.from(plan.wts)
      ..sort((a, b) => a.date.compareTo(b.date));
    String weightChangeText = "-";
    if (sortedWts.length > 1) {
      final diff = sortedWts.last.weight - sortedWts.first.weight;
      weightChangeText = "${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg";
    } else if (sortedWts.length == 1) {
      weightChangeText = "${sortedWts.first.weight} kg";
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/icon.png',
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, color: Color(0xFF238B55)),
            ),
            const SizedBox(width: 8),
            const Text(
              "60-Day Veg Fat Loss",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // AI Customizer Button
          IconButton(
            tooltip: "✨ AI Diet & Routine Customizer",
            onPressed: _showAiCustomizer,
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF238B55), size: 21),
          ),
          // Notification Nudges Button
          IconButton(
            tooltip: "Daily Nudges & Reminders",
            onPressed: _showProfile,
            icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFF238B55), size: 22),
          ),
          // User Avatar Button
          IconButton(
            onPressed: _showProfile,
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: plan.photoURL.isNotEmpty
                  ? NetworkImage(plan.photoURL)
                  : null,
              backgroundColor: const Color(0xFF238B55).withValues(alpha: 0.2),
              child: plan.photoURL.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Color(0xFF238B55))
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Day Navigation Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.outlined(
                        onPressed: _selectedDay > 1
                            ? () => setState(() => _selectedDay--)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Column(
                        children: [
                          Text(
                            "Day $_selectedDay of 60",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, dd MMM').format(currentDayDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: _selectedDay < 60
                                ? () => setState(() => _selectedDay++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDay = plan.currentDay;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF238B55),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text("Today"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hero Progress Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF104330), Color(0xFF207D4E), Color(0xFF2E9F65)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF238B55).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Day $_selectedDay",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Week $weekNum: $phaseName",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Target: ${PlanData.stepsTarget[(weekNum - 1).clamp(0, PlanData.stepsTarget.length - 1)]} steps/day",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _selectedDay / 60.0,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD27A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4 KPIs Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _buildKpiCard(
                        title: "Tasks Done",
                        value: "$completedCount/${schedule.length}",
                        subtitle: completedCount == schedule.length ? "All done 🎉" : "Keep going!",
                        progress: schedule.isNotEmpty ? completedCount / schedule.length : 0,
                        isDark: isDark,
                      ),
                      _buildKpiCard(
                        title: "Water Intake",
                        value: "$waterCount/12",
                        subtitle: "Goal: ~3.5 Litres",
                        progress: (waterCount / 12.0).clamp(0.0, 1.0),
                        isDark: isDark,
                      ),
                      _buildKpiCard(
                        title: "Steps Goal",
                        value: PlanData.stepsTarget[(weekNum - 1).clamp(0, PlanData.stepsTarget.length - 1)],
                        subtitle: "Recommended",
                        progress: null,
                        isDark: isDark,
                      ),
                      _buildKpiCard(
                        title: "Weight Diff",
                        value: weightChangeText,
                        subtitle: sortedWts.isNotEmpty ? "Since ${sortedWts.first.date}" : "Log below",
                        progress: null,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Today's Plan Schedule
                  const Text(
                    "🍽️ Daily Nutrition & Activity Plan",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap any item to mark it completed",
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: schedule.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = schedule[index];
                      final isDone = plan.done['$_selectedDay:$index'] == 1;

                      Color tileBg;
                      if (isDone) {
                        tileBg = isDark ? const Color(0xFF16251E) : const Color(0xFFE8F2EC);
                      } else {
                        switch (item.kind) {
                          case 'w':
                            tileBg = isDark ? const Color(0xFF142436) : const Color(0xFFE3EFFC);
                            break;
                          case 'x':
                            tileBg = isDark ? const Color(0xFF132B28) : const Color(0xFFDAF2EE);
                            break;
                          case 's':
                            tileBg = isDark ? const Color(0xFF221E38) : const Color(0xFFEAE8FB);
                            break;
                          case 'k':
                            tileBg = isDark ? const Color(0xFF332014) : const Color(0xFFFFE9DC);
                            break;
                          default:
                            tileBg = isDark ? const Color(0xFF152A22) : const Color(0xFFE4F5EC);
                        }
                      }

                      return InkWell(
                        onTap: () => _toggleTask(index, isDone),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: tileBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDone ? const Color(0xFF238B55) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.black38 : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.formattedTime,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            decoration: isDone ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDone ? Colors.grey : null,
                                      ),
                                    ),
                                    if (item.detail.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.detail,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                isDone ? Icons.check_circle : Icons.circle_outlined,
                                color: isDone ? const Color(0xFF238B55) : Colors.grey,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Water Tracker Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "💧 Water Tracker",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text("1 glass ≈ 300 ml", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(12, (index) {
                              final glassNum = index + 1;
                              final isDrank = glassNum <= waterCount;
                              return InkWell(
                                onTap: () => _setWater(glassNum),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 44,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDrank ? const Color(0xFF238B55) : Colors.transparent,
                                    border: Border.all(color: const Color(0xFF238B55), width: 1.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isDrank ? "✓" : "💧",
                                    style: TextStyle(
                                      fontSize: isDrank ? 16 : 14,
                                      color: isDrank ? Colors.white : Colors.blueGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weight Logger Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "⚖️ Daily Weight Logger",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _weightInputController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: "Enter kg (e.g. 74.5)",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _saveWeight,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF238B55),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                child: const Text("Save"),
                              ),
                            ],
                          ),
                          if (sortedWts.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const Text("Recent Weigh-Ins:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Column(
                              children: sortedWts.reversed.take(4).map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.date, style: const TextStyle(fontSize: 13)),
                                      Text("${entry.weight} kg", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // All 60 Days Heatmap Grid
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📅 All 60 Days Matrix",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text(
                            "Tap any day to inspect & log",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 60,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 10,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemBuilder: (context, idx) {
                              final dNum = idx + 1;
                              final isSelected = dNum == _selectedDay;
                              
                              // Calculate completion for that day
                              final dSchedule = PlanData.buildSchedule(dNum, plan.startDateTime);
                              int dDone = 0;
                              for (int i = 0; i < dSchedule.length; i++) {
                                if (plan.done['$dNum:$i'] == 1) dDone++;
                              }
                              final ratio = dSchedule.isNotEmpty ? (dDone / dSchedule.length) : 0.0;

                              Color dayBg;
                              if (ratio > 0.8) {
                                dayBg = const Color(0xFF238B55);
                              } else if (ratio > 0) {
                                dayBg = const Color(0xFF238B55).withValues(alpha: 0.25);
                              } else {
                                dayBg = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);
                              }

                              return InkWell(
                                onTap: () => setState(() => _selectedDay = dNum),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: dayBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFFE5931E), width: 2)
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$dNum",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: ratio > 0.8 ? Colors.white : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("🔒 Start Date: ${plan.startDate}", style: const TextStyle(fontSize: 12)),
                                const Text("Day 1 Locked", style: TextStyle(fontSize: 11, color: Color(0xFF238B55), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required double? progress,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16251E) : const Color(0xFFF9FCFB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1E2D8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            if (progress != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF238B55)),
                ),
              )
            else
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
