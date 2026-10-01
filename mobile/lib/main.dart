import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'models/user_plan.dart';
import 'services/firestore_service.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FatlossPlanApp());
}

class FatlossPlanApp extends StatelessWidget {
  const FatlossPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    const leafColor = Color(0xFF238B55);

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F7F4),
      colorScheme: ColorScheme.fromSeed(
        seedColor: leafColor,
        primary: leafColor,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0D2821),
        elevation: 0,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1713),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3EC785),
        primary: const Color(0xFF3EC785),
        brightness: Brightness.dark,
        surface: const Color(0xFF13241E),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF13241E),
        foregroundColor: Color(0xFFE8F5EF),
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: '60-Day Veg Fat Loss',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF238B55)),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        // Authenticated -> listen to Firestore UserPlan
        return StreamBuilder<UserPlan?>(
          stream: FirestoreService().streamUserPlan(user.uid),
          builder: (context, planSnapshot) {
            if (planSnapshot.connectionState == ConnectionState.waiting &&
                !planSnapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF238B55)),
                ),
              );
            }

            final plan = planSnapshot.data;
            if (plan == null) {
              // New user -> show one-time Start Date Onboarding
              return OnboardingScreen(user: user);
            }

            // Existing user -> show full interactive Dashboard
            return DashboardScreen(userPlan: plan);
          },
        );
      },
    );
  }
}
