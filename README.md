# 🥗 60-Day Veg Fat Loss Dashboard

A full-stack fitness and nutrition dashboard powered by a high-performance **Node.js + SQLite backend** with **Secret Key Authentication**, **One-Time Start Date Lock Onboarding**, and **Real-Time Data Persistence**.

---

## 🌟 Key Features

1. **🔒 Secret Key Authentication & Multi-User Support**:
   - Every user chooses their own **Secret Passcode/Key** during onboarding.
   - Separate accounts and progress tracking for different members in the same SQLite database.
   - Seamless session recovery across browser refreshes.

2. **🗓️ One-Time Start Date Onboarding Lock**:
   - The **Start Date** is configured **once** during onboarding.
   - Once set, the start date is permanently locked to ensure consistent 60-day roadmap calculations across all 8 phases.

3. **💾 Where User Tracking Data is Stored**:
   - All user data (daily task checkboxes, 12-glass water tracker, weigh-in history, starting & target weights) is stored directly in **`data/fatloss.db`** via Node.js built-in **SQLite database engine (`node:sqlite`)**.
   - Changes sync automatically in real-time.
   - Full **JSON Data Backup Export** is available at any time from the Member Profile.

4. **✨ Modern Aesthetics & Responsive Design**:
   - Light & Dark mode support.
   - Glassmorphic hero headers and KPI meters.
   - Interactive daily schedule with vegetarian meal options (Moong chilla, Paneer tikka, Sprouts, Dalia, etc.) and workouts.
   - 60-day interactive completion heatmap matrix.

---

## 🚀 How to Run the Website Locally

### 1. Install Dependencies
```bash
npm install
```

### 2. Start the Server
```bash
npm start
```
Or for development with automatic reload:
```bash
npm run dev
```

### 3. Open in Browser
Visit **[http://localhost:3000](http://localhost:3000)**

---

## 📁 Project Structure

```
fatloss-plan/
├── data/
│   └── fatloss.db          # Persistent SQLite database file
├── db.js                   # SQLite database models & query handlers
├── server.js               # Express API server & static file serving
├── index.html              # Frontend application & dashboard UI
├── package.json            # Node.js project configuration
└── README.md               # Documentation
```

---

## 🛡️ API Endpoints

- `POST /api/auth/register`: Create a new user profile with Name, Secret Key, Start Date, and Starting Weight.
- `POST /api/auth/login`: Authenticate with Secret Key and load all tracking records.
- `GET /api/user/me`: Fetch authenticated user profile and live tracking data.
- `POST /api/user/toggle-task`: Mark a daily task complete or incomplete.
- `POST /api/user/water`: Log daily water intake (0–12 glasses).
- `POST /api/user/weight`: Log morning weight entries.
- `GET /api/user/export`: Download complete JSON backup of the user profile and logs.
