# 🥗 60-Day Veg Fat Loss Dashboard

A modern, serverless fitness and nutrition tracking web application powered by **Google Firebase Authentication** (Google & Apple Sign-In), **Cloud Firestore Database**, and **Firebase Hosting**.

---

## 🌟 Architecture & Features

1. **🔥 Cloud Firestore Database (Zero Server, 100% Cloud-Backed)**:
   - **No local `fatloss.db` or server required**.
   - All user data (daily checklists, 12-glass water intake, weigh-ins, starting & target weights) is stored in Google Cloud Firestore under the `users/{userId}` collection.
   - Real-time live synchronization across phones, laptops, and tablets using Firestore `onSnapshot` listeners.

2. **🔑 Google & Apple Authentication**:
   - One-tap sign-in with Google or Apple accounts.
   - Auto-populates verified member profile name and avatar.

3. **🗓️ One-Time Start Date Onboarding Lock**:
   - Users select their Day 1 Start Date once during onboarding.
   - The start date is permanently locked to calculate accurate 60-day roadmap progression across all 8 phases.

4. **🚀 Hosted on Firebase Global CDN**:
   - Live URL: **[https://fatloss-plan.web.app](https://fatloss-plan.web.app)**
   - Fast loading with automatic HTTPS encryption.

---

## 📁 Project Structure

```
fatloss-plan/
├── index.html              # Frontend app with Firebase Modular SDK & Firestore sync
├── firestore.rules         # Firestore security rules (per-user isolation)
├── firebase.json           # Firebase Hosting & Firestore configuration
├── .firebaserc             # Firebase project definition (fatloss-plan)
└── README.md               # Project documentation
```

---

## 🚀 How to Deploy Updates

```bash
# Deploy latest frontend and firestore rules
npx firebase-tools deploy
```
