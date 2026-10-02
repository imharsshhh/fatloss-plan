import 'package:flutter/material.dart';
import '../models/custom_plan.dart';
import '../models/user_plan.dart';
import '../services/ai_plan_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AiCustomizerDialog extends StatefulWidget {
  final UserPlan userPlan;
  const AiCustomizerDialog({super.key, required this.userPlan});

  @override
  State<AiCustomizerDialog> createState() => _AiCustomizerDialogState();
}

class _AiCustomizerDialogState extends State<AiCustomizerDialog> {
  late String _wakeUpTime;
  late String _bedTime;
  late int _napDuration;
  late String _morningDrink;
  late String _middayDrink;
  late Set<String> _selectedProteins;
  late Set<String> _selectedVeggies;
  late Set<String> _selectedGrains;
  late Set<String> _selectedSnacks;

  bool _isGenerating = false;
  CustomPlan? _previewPlan;

  @override
  void initState() {
    super.initState();
    final currentPrefs = widget.userPlan.customPlan?.preferences ?? PlanPreferences();
    _wakeUpTime = currentPrefs.wakeUpTime;
    _bedTime = currentPrefs.bedTime;
    _napDuration = currentPrefs.napDuration;
    _morningDrink = currentPrefs.morningDrink;
    _middayDrink = currentPrefs.middayDrink;
    _selectedProteins = Set<String>.from(currentPrefs.proteins);
    _selectedVeggies = Set<String>.from(currentPrefs.veggies);
    _selectedGrains = Set<String>.from(currentPrefs.grains);
    _selectedSnacks = Set<String>.from(currentPrefs.snacks);
  }

  Future<void> _pickTime({required bool isWakeUp}) async {
    final initialParts = (isWakeUp ? _wakeUpTime : _bedTime).split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(initialParts[0]) ?? (isWakeUp ? 6 : 23),
      minute: int.tryParse(initialParts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isWakeUp ? "SELECT WAKE-UP TIME" : "SELECT BEDTIME",
    );

    if (picked != null) {
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = formatted;
        } else {
          _bedTime = formatted;
        }
      });
    }
  }

  String _formatTimeDisplay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final ampm = h >= 12 ? 'PM' : 'AM';
      final hour12 = (h % 12 == 0) ? 12 : (h % 12);
      return '$hour12:$m $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _generateAndPreview() async {
    if (_selectedProteins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least 1 high-protein source."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final newPrefs = PlanPreferences(
      wakeUpTime: _wakeUpTime,
      bedTime: _bedTime,
      napDuration: _napDuration,
      morningDrink: _morningDrink,
      middayDrink: _middayDrink,
      proteins: _selectedProteins.toList(),
      veggies: _selectedVeggies.toList(),
      grains: _selectedGrains.toList(),
      snacks: _selectedSnacks.toList(),
    );

    try {
      final customPlan = await AiPlanService().generateCustomPlan(newPrefs);
      if (mounted) {
        setState(() {
          _previewPlan = customPlan;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating plan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _savePlan() async {
    if (_previewPlan == null) return;

    setState(() => _isGenerating = true);
    try {
      await FirestoreService().updateCustomPlan(
        uid: widget.userPlan.uid,
        customPlanMap: _previewPlan!.toMap(),
      );

      // Reschedule local notifications for the new wake-up times and meals
      await NotificationService().scheduleAllDailyNudges();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ Custom AI Plan & Routine locked successfully!"),
            backgroundColor: Color(0xFF238B55),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save plan: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text("✨ ", style: TextStyle(fontSize: 20)),
                    Text(
                      "AI Diet & Routine Plan",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Select your daily wake-up rhythm, favorite veg proteins, and detox drinks to generate a custom 60-day fat loss roadmap.",
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.35,
              ),
            ),
            const Divider(height: 20),

            // Scrollable Options Area
            Expanded(
              child: ListView(
                children: [
                  // SECTION 1: Daily Rhythm
                  _buildSectionTitle("⏰ 1. Daily Rhythm & Timings", isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeCard(
                          title: "Wake-up Time",
                          time: _formatTimeDisplay(_wakeUpTime),
                          icon: Icons.wb_sunny_rounded,
                          iconColor: const Color(0xFFE5931E),
                          onTap: () => _pickTime(isWakeUp: true),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTimeCard(
                          title: "Bedtime",
                          time: _formatTimeDisplay(_bedTime),
                          icon: Icons.bedtime_rounded,
                          iconColor: const Color(0xFF5B6CF9),
                          onTap: () => _pickTime(isWakeUp: false),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("Afternoon Power Nap", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 20, 30, 45].map((mins) {
                      final selected = _napDuration == mins;
                      return ChoiceChip(
                        label: Text(mins == 0 ? "No Nap" : "$mins Mins"),
                        selected: selected,
                        selectedColor: const Color(0xFF238B55).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF238B55) : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _napDuration = mins);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // SECTION 2: Drinks
                  _buildSectionTitle("🍵 2. Morning Detox & Midday Drinks", isDark),
                  const SizedBox(height: 8),
                  const Text("Morning Detox Drink", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AiPlanService.morningDrinkOptions.map((opt) {
                      final selected = _morningDrink == opt['id'];
                      return ChoiceChip(
                        avatar: Text(opt['emoji']!),
                        label: Text(opt['name']!),
                        selected: selected,
                        selectedColor: const Color(0xFF238B55).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF238B55) : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _morningDrink = opt['id']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("Midday / Afternoon Drink", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AiPlanService.middayDrinkOptions.map((opt) {
                      final selected = _middayDrink == opt['id'];
                      return ChoiceChip(
                        avatar: Text(opt['emoji']!),
                        label: Text(opt['name']!),
                        selected: selected,
                        selectedColor: const Color(0xFF238B55).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF238B55) : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _middayDrink = opt['id']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // SECTION 3: Protein Sources
                  _buildSectionTitle("🧀 3. High-Protein Staples (Select all you like)", isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AiPlanService.proteinOptions.map((opt) {
                      final selected = _selectedProteins.contains(opt['id']);
                      return FilterChip(
                        avatar: Text(opt['emoji']!),
                        label: Text(opt['name']!),
                        selected: selected,
                        selectedColor: const Color(0xFF238B55).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF238B55) : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedProteins.add(opt['id']!);
                            } else if (_selectedProteins.length > 1) {
                              _selectedProteins.remove(opt['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // SECTION 4: Vegetables
                  _buildSectionTitle("🥦 4. Preferred Vegetables & Greens", isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AiPlanService.veggieOptions.map((opt) {
                      final selected = _selectedVeggies.contains(opt['id']);
                      return FilterChip(
                        avatar: Text(opt['emoji']!),
                        label: Text(opt['name']!),
                        selected: selected,
                        selectedColor: const Color(0xFF238B55).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF238B55) : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedVeggies.add(opt['id']!);
                            } else {
                              _selectedVeggies.remove(opt['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // SECTION 5: Grains & Snacks
                  _buildSectionTitle("🌾 5. Grains & Evening Snacks", isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...AiPlanService.grainOptions.map((opt) {
                        final selected = _selectedGrains.contains(opt['id']);
                        return FilterChip(
                          avatar: Text(opt['emoji']!),
                          label: Text(opt['name']!),
                          selected: selected,
                          selectedColor: const Color(0xFF238B55).withValues(alpha: 0.2),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedGrains.add(opt['id']!);
                              } else {
                                _selectedGrains.remove(opt['id']);
                              }
                            });
                          },
                        );
                      }),
                      ...AiPlanService.snackOptions.map((opt) {
                        final selected = _selectedSnacks.contains(opt['id']);
                        return FilterChip(
                          avatar: Text(opt['emoji']!),
                          label: Text(opt['name']!),
                          selected: selected,
                          selectedColor: const Color(0xFF238B55).withValues(alpha: 0.2),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedSnacks.add(opt['id']!);
                              } else {
                                _selectedSnacks.remove(opt['id']);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // PREVIEW BOX (If generated)
                  if (_previewPlan != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF13241E) : const Color(0xFFE8F5EF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF238B55)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF238B55), size: 18),
                              SizedBox(width: 6),
                              Text(
                                "AI Plan Preview Ready!",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "• Day 1 Breakfast: ${_previewPlan!.planA[0][0]}\n"
                            "• Day 1 Lunch: ${_previewPlan!.planA[0][2]}\n"
                            "• Day 1 Dinner: ${_previewPlan!.planA[0][4]}\n"
                            "• Schedule: ${_formatTimeDisplay(_wakeUpTime)} Wakeup ➔ ${_formatTimeDisplay(_bedTime)} Sleep",
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: isDark ? Colors.white70 : const Color(0xFF1E4836),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Actions
            if (_isGenerating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF238B55)),
                      ),
                      SizedBox(width: 12),
                      Text("Synthesizing custom meal plan with AI...", style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              )
            else if (_previewPlan != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _generateAndPreview,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Re-generate"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _savePlan,
                      icon: const Icon(Icons.lock_clock_rounded, size: 18),
                      label: const Text("Lock & Apply Plan", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF238B55),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _generateAndPreview,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  "Generate Custom AI Plan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238B55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String time,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF2F7F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFD1E2D8),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
