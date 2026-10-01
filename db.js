const { DatabaseSync } = require('node:sqlite');
const fs = require('fs');
const path = require('path');

// Ensure data directory exists
const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbPath = path.join(dataDir, 'fatloss.db');
const db = new DatabaseSync(dbPath);

// Enable foreign keys and initialize schema
db.exec('PRAGMA foreign_keys = ON;');
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    secret_key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    start_date TEXT NOT NULL,
    initial_weight REAL,
    target_weight REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS daily_tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    task_index INTEGER NOT NULL,
    completed INTEGER DEFAULT 1,
    updated_at TEXT NOT NULL,
    UNIQUE(user_id, day_number, task_index)
  );

  CREATE TABLE IF NOT EXISTS water_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    glasses INTEGER NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE(user_id, day_number)
  );

  CREATE TABLE IF NOT EXISTS weight_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date TEXT NOT NULL,
    weight REAL NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE(user_id, log_date)
  );
`);

// Helper Statements
const stmtGetUserBySecret = db.prepare('SELECT * FROM users WHERE secret_key = ?');
const stmtGetUserById = db.prepare('SELECT * FROM users WHERE id = ?');
const stmtInsertUser = db.prepare(`
  INSERT INTO users (secret_key, name, start_date, initial_weight, target_weight, created_at, updated_at)
  VALUES (?, ?, ?, ?, ?, ?, ?)
`);

const stmtGetTasks = db.prepare('SELECT day_number, task_index, completed FROM daily_tasks WHERE user_id = ? AND completed = 1');
const stmtUpsertTask = db.prepare(`
  INSERT INTO daily_tasks (user_id, day_number, task_index, completed, updated_at)
  VALUES (?, ?, ?, ?, ?)
  ON CONFLICT(user_id, day_number, task_index) DO UPDATE SET
    completed = excluded.completed,
    updated_at = excluded.updated_at
`);
const stmtDeleteTask = db.prepare('DELETE FROM daily_tasks WHERE user_id = ? AND day_number = ? AND task_index = ?');

const stmtGetWater = db.prepare('SELECT day_number, glasses FROM water_logs WHERE user_id = ?');
const stmtUpsertWater = db.prepare(`
  INSERT INTO water_logs (user_id, day_number, glasses, updated_at)
  VALUES (?, ?, ?, ?)
  ON CONFLICT(user_id, day_number) DO UPDATE SET
    glasses = excluded.glasses,
    updated_at = excluded.updated_at
`);

const stmtGetWeights = db.prepare('SELECT log_date, weight FROM weight_logs WHERE user_id = ? ORDER BY log_date ASC');
const stmtUpsertWeight = db.prepare(`
  INSERT INTO weight_logs (user_id, log_date, weight, updated_at)
  VALUES (?, ?, ?, ?)
  ON CONFLICT(user_id, log_date) DO UPDATE SET
    weight = excluded.weight,
    updated_at = excluded.updated_at
`);
const stmtDeleteWeight = db.prepare('DELETE FROM weight_logs WHERE user_id = ? AND log_date = ?');

const stmtClearUserData = db.prepare('DELETE FROM daily_tasks WHERE user_id = ?');
const stmtClearWaterData = db.prepare('DELETE FROM water_logs WHERE user_id = ?');
const stmtClearWeightData = db.prepare('DELETE FROM weight_logs WHERE user_id = ?');

/**
 * Normalizes a secret key (trims whitespace)
 */
function normalizeKey(key) {
  return (key || '').trim();
}

/**
 * Register a new user with onboarding details
 */
function registerUser({ name, secretKey, startDate, initialWeight = null, targetWeight = null }) {
  const normKey = normalizeKey(secretKey);
  if (!normKey) {
    throw new Error('Secret key is required.');
  }
  if (!name || !name.trim()) {
    throw new Error('Name is required.');
  }
  if (!startDate) {
    throw new Error('Start date is required.');
  }

  const existing = stmtGetUserBySecret.get(normKey);
  if (existing) {
    throw new Error('A member with this Secret Key already exists. Please log in or choose a unique Secret Key.');
  }

  const now = new Date().toISOString();
  stmtInsertUser.run(
    normKey,
    name.trim(),
    startDate,
    initialWeight ? parseFloat(initialWeight) : null,
    targetWeight ? parseFloat(targetWeight) : null,
    now,
    now
  );

  const newUser = stmtGetUserBySecret.get(normKey);

  // If initial weight was provided, log it for start date
  if (initialWeight && !isNaN(parseFloat(initialWeight))) {
    stmtUpsertWeight.run(newUser.id, startDate, parseFloat(initialWeight), now);
  }

  return formatUserData(newUser);
}

/**
 * Authenticate user with Secret Key
 */
function loginUser(secretKey) {
  const normKey = normalizeKey(secretKey);
  if (!normKey) {
    throw new Error('Secret key is required.');
  }

  const user = stmtGetUserBySecret.get(normKey);
  if (!user) {
    throw new Error('No account found for this Secret Key. Please check your key or create a new profile.');
  }

  return formatUserData(user);
}

/**
 * Formats full user payload including tracking maps
 */
function formatUserData(user) {
  const tasks = stmtGetTasks.all(user.id);
  const doneMap = {};
  for (const t of tasks) {
    if (t.completed) {
      doneMap[`${t.day_number}:${t.task_index}`] = 1;
    }
  }

  const waterRows = stmtGetWater.all(user.id);
  const waterMap = {};
  for (const w of waterRows) {
    waterMap[w.day_number] = w.glasses;
  }

  const weightRows = stmtGetWeights.all(user.id);
  const wtsList = weightRows.map(r => ({ d: r.log_date, w: r.weight }));

  return {
    user: {
      id: user.id,
      name: user.name,
      startDate: user.start_date,
      initialWeight: user.initial_weight,
      targetWeight: user.target_weight,
      createdAt: user.created_at
    },
    data: {
      start: user.start_date,
      done: doneMap,
      water: waterMap,
      wts: wtsList
    }
  };
}

/**
 * Toggle task done/undone
 */
function toggleTask(userId, dayNumber, taskIndex, completed) {
  const now = new Date().toISOString();
  if (completed) {
    stmtUpsertTask.run(userId, parseInt(dayNumber), parseInt(taskIndex), 1, now);
  } else {
    stmtDeleteTask.run(userId, parseInt(dayNumber), parseInt(taskIndex));
  }
}

/**
 * Update water intake
 */
function updateWater(userId, dayNumber, glasses) {
  const now = new Date().toISOString();
  stmtUpsertWater.run(userId, parseInt(dayNumber), parseInt(glasses), now);
}

/**
 * Add or update weight log
 */
function logWeight(userId, logDate, weight) {
  const now = new Date().toISOString();
  stmtUpsertWeight.run(userId, logDate, parseFloat(weight), now);
}

/**
 * Sync entire payload (batch)
 */
function syncAll(userId, payload) {
  const now = new Date().toISOString();
  if (payload.done) {
    stmtClearUserData.run(userId);
    for (const key of Object.keys(payload.done)) {
      if (payload.done[key]) {
        const [d, i] = key.split(':');
        if (d !== undefined && i !== undefined) {
          stmtUpsertTask.run(userId, parseInt(d), parseInt(i), 1, now);
        }
      }
    }
  }

  if (payload.water) {
    stmtClearWaterData.run(userId);
    for (const day of Object.keys(payload.water)) {
      const g = parseInt(payload.water[day]);
      if (g > 0) {
        stmtUpsertWater.run(userId, parseInt(day), g, now);
      }
    }
  }

  if (payload.wts && Array.isArray(payload.wts)) {
    stmtClearWeightData.run(userId);
    for (const item of payload.wts) {
      if (item.d && item.w !== undefined) {
        stmtUpsertWeight.run(userId, item.d, parseFloat(item.w), now);
      }
    }
  }

  const user = stmtGetUserById.get(userId);
  return formatUserData(user);
}

module.exports = {
  db,
  normalizeKey,
  registerUser,
  loginUser,
  formatUserData,
  getUserBySecretKey: (k) => stmtGetUserBySecret.get(normalizeKey(k)),
  getUserById: (id) => stmtGetUserById.get(id),
  toggleTask,
  updateWater,
  logWeight,
  syncAll
};
