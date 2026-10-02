import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_plan.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'ai_customizer_dialog.dart';

class ProfileDialog extends StatefulWidget {
  final UserPlan userPlan;
  const ProfileDialog({super.key, required this.userPlan});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  bool _notificationsEnabled = true;
  bool _loadingNotifications = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    final enabled = await NotificationService().areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _loadingNotifications = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService().setNotificationsEnabled(value);
    if (value && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Daily meal, drink & water nudges activated!"),
          backgroundColor: Color(0xFF238B55),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendTestNudge() async {
    await NotificationService().sendInstantTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔔 Test reminder sent! Check your notification bar."),
          backgroundColor: Color(0xFF238B55),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Option 1: Change Start Date & Clear Stored Data (Keep Account)
  Future<void> _changeStartDateAndReset() async {
    DateTime initialDate = DateTime.now();
    try {
      initialDate = DateTime.parse(widget.userPlan.startDate);
    } catch (_) {}

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: "SELECT NEW DAY 1 START DATE",
      confirmText: "SELECT DATE",
    );

    if (pickedDate == null || !mounted) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
    final displayDate = DateFormat('dd MMMM yyyy').format(pickedDate);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restart_alt, color: Color(0xFF238B55)),
            SizedBox(width: 8),
            Text("Reset & Change Date"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Start Date: $displayDate",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            const Text(
              "⚠️ This action will:\n"
              "• Keep your Google account active.\n"
              "• Reset your Day 1 to the new date.\n"
              "• Clear all previous 60-day task checkmarks, water logs, and weigh-in records.",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF238B55),
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm & Reset"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await FirestoreService().resetPlanDataAndStartDate(
        uid: widget.userPlan.uid,
        newStartDate: dateStr,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✨ Plan reset successfully! New Start Date: $displayDate"),
            backgroundColor: const Color(0xFF238B55),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to reset plan: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Option 2: Delete Account & Wipe All Stored Data
  Future<void> _deleteAccountAndAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Account?"),
          ],
        ),
        content: const Text(
          "🚨 Permanent Action:\n\n"
          "This will permanently delete your cloud profile, all 60-day progress, water logs, and delete your account from Firebase.\n\n"
          "Are you sure you want to proceed?",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete Everything"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirestoreService().deleteUserPlanAndAccount(widget.userPlan.uid);
      if (user != null) {
        await user.delete();
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        // If reauthentication is needed
        if (e.toString().contains('requires-recent-login')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please sign in again before deleting your account for security."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting account: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    DateTime? startDate;
    try {
      startDate = DateTime.parse(widget.userPlan.startDate);
    } catch (_) {}

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "👤 Member Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF2F7F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFD1E2D8),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: widget.userPlan.photoURL.isNotEmpty
                            ? NetworkImage(widget.userPlan.photoURL)
                            : null,
                        backgroundColor:
                            const Color(0xFF238B55).withValues(alpha: 0.15),
                        child: widget.userPlan.photoURL.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF238B55))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userPlan.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (widget.userPlan.email.isNotEmpty)
                              Text(
                                widget.userPlan.email,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Start Date",
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(
                        startDate != null
                            ? DateFormat('dd MMM yyyy').format(startDate)
                            : widget.userPlan.startDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Cloud Database",
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(
                        "Cloud Firestore",
                        style: TextStyle(
                          color: Color(0xFF238B55),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Daily Nudges & Reminders Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13241E) : const Color(0xFFE8F5EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF238B55).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_active,
                              color: Color(0xFF238B55), size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Daily Nudges & Reminders",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (_loadingNotifications)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch.adaptive(
                          value: _notificationsEnabled,
                          activeTrackColor: const Color(0xFF238B55),
                          onChanged: _toggleNotifications,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• 💧 Daily Water: Exact timed intervals for all 12 glasses (3.5L)\n"
                    "• 🍳 Meals: Nudged 30 mins before\n"
                    "• ☕ Green Tea / Coffee: Nudged 10 mins before\n"
                    "• 🚶 Walks & Workouts: 10–15 mins before\n"
                    "• 🌙 Nightly Review: 9:45 PM roadmap check",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? Colors.white70 : const Color(0xFF2C5E47),
                    ),
                  ),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _sendTestNudge,
                        icon: const Icon(Icons.send_rounded, size: 15),
                        label: const Text(
                          "Send Test Nudge Now",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF238B55),
                          side: const BorderSide(color: Color(0xFF238B55)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF238B55)),
                ),
              )
            else ...[
              // AI Diet & Routine Customizer Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AiCustomizerDialog(userPlan: widget.userPlan),
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  "Customize Diet & Routine with AI",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238B55),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
              const SizedBox(height: 10),

              // Option 1: Change Start Date & Clear Records (Keep Account)
              OutlinedButton.icon(
                onPressed: _changeStartDateAndReset,
                icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF238B55)),
                label: const Text(
                  "Change Start Date & Reset Data",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF238B55)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF238B55), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
              const SizedBox(height: 10),

              // Sign Out Button
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Sign Out"),
                      content: const Text("Are you sure you want to sign out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Sign Out",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (context.mounted) Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.blueGrey, size: 18),
                label: const Text("Sign Out",
                    style: TextStyle(
                        color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueGrey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Delete Account & Wipe All Data
              OutlinedButton.icon(
                onPressed: _deleteAccountAndAllData,
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                label: const Text("Delete Account & All Data",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
