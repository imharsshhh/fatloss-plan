# 📱 60-Day Veg Fat Loss - Flutter Android & Mobile App

A companion mobile application built with **Flutter 3** and **Firebase** (Google/Apple Auth & Cloud Firestore).

---

## 🌟 Features

- **🔐 Google & Apple Authentication**: One-tap sign-in with your Google or Apple ID.
- **🗓️ One-Time Start Date Lock**: Set your Day 1 start date during onboarding. Permanently locked to calculate your exact 60-day roadmap.
- **🔥 Live Cloud Firestore Sync**: Changes to tasks, water intake, and weigh-ins sync instantly between the Android app and the Web dashboard.
- **🍽️ Daily Schedule**: Time-stamped vegetarian meal plans, walking schedules, strength & yoga workouts.
- **💧 12-Glass Water Tracker**: Interactive liquid tracking (3.5L daily target).
- **⚖️ Daily Weight Logger**: Track your weight progression with automatic weight diff calculation.
- **📅 60-Day Completion Matrix**: Interactive heatmap grid showing progress across all 60 days.
- **🌓 Dark & Light Mode**: Auto-adapts to your device's system theme.

---

## 🚀 How to Run on Android

### Prerequisites
- Flutter SDK (Installed: Flutter 3.35.2 / Dart 3.9.0)
- Android Studio / Android SDK or an active Android device / emulator

### 1. Navigate to Mobile Directory
```bash
cd mobile
```

### 2. Fetch Dependencies
```bash
flutter pub get
```

### 3. Run on Device / Emulator
```bash
flutter run
```

### 4. Build Release APK for Android
```bash
flutter build apk --release
```
The generated APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`
