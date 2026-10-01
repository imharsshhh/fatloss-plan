import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_plan.dart';
import '../services/notification_service.dart';

class ProfileDialog extends StatefulWidget {
  final UserPlan userPlan;
  const ProfileDialog({super.key, required this.userPlan});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  bool _notificationsEnabled = true;
  bool _loadingNotifications = true;

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
            const SizedBox(height: 16),

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
                    "• 💧 Water Goal: Periodic 12-glass reminders\n"
                    "• 🍳 Meals: Nudged 30 mins before\n"
                    "• ☕ Green Tea / Coffee: Nudged 10 mins before\n"
                    "• 🚶 Walks & Workouts: 10–15 mins before\n"
                    "• 🌙 Nightly Review: 9:45 PM summary",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? Colors.white70 : const Color(0xFF2C5E47),
                    ),
                  ),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _sendTestNudge,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text(
                          "Send Test Nudge Now",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF238B55),
                          side: const BorderSide(color: Color(0xFF238B55)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

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
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: const Text("Sign Out",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
