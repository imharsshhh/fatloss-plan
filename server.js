const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./db.js');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '5mb' }));

// Auth Middleware
function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  const secretKey = req.headers['x-secret-key'] 
    || (authHeader && authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null)
    || req.query.key;

  if (!secretKey) {
    return res.status(401).json({ success: false, error: 'Authentication required. Missing Secret Key.' });
  }

  try {
    const user = db.getUserBySecretKey(secretKey);
    if (!user) {
      return res.status(401).json({ success: false, error: 'Invalid or expired Secret Key.' });
    }
    req.user = user;
    next();
  } catch (err) {
    return res.status(500).json({ success: false, error: 'Auth check failed: ' + err.message });
  }
}

// Public Auth Endpoints
app.post('/api/auth/register', (req, res) => {
  try {
    const { name, secretKey, startDate, initialWeight, targetWeight } = req.body;
    if (!name || !secretKey || !startDate) {
      return res.status(400).json({ success: false, error: 'Please provide name, secretKey, and startDate.' });
    }

    const result = db.registerUser({ name, secretKey, startDate, initialWeight, targetWeight });
    res.status(201).json({ success: true, ...result });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

app.post('/api/auth/login', (req, res) => {
  try {
    const { secretKey } = req.body;
    if (!secretKey) {
      return res.status(400).json({ success: false, error: 'Secret Key is required.' });
    }

    const result = db.loginUser(secretKey);
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(401).json({ success: false, error: err.message });
  }
});

// Protected User Data Endpoints
app.get('/api/user/me', authMiddleware, (req, res) => {
  try {
    const data = db.formatUserData(req.user);
    res.json({ success: true, ...data });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/user/toggle-task', authMiddleware, (req, res) => {
  try {
    const { dayNumber, taskIndex, completed } = req.body;
    if (dayNumber === undefined || taskIndex === undefined) {
      return res.status(400).json({ success: false, error: 'dayNumber and taskIndex required.' });
    }

    db.toggleTask(req.user.id, dayNumber, taskIndex, completed);
    res.json({ success: true, dayNumber, taskIndex, completed });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/user/water', authMiddleware, (req, res) => {
  try {
    const { dayNumber, glasses } = req.body;
    if (dayNumber === undefined || glasses === undefined) {
      return res.status(400).json({ success: false, error: 'dayNumber and glasses required.' });
    }

    db.updateWater(req.user.id, dayNumber, glasses);
    res.json({ success: true, dayNumber, glasses });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/user/weight', authMiddleware, (req, res) => {
  try {
    const { logDate, weight } = req.body;
    if (!logDate || weight === undefined) {
      return res.status(400).json({ success: false, error: 'logDate and weight required.' });
    }

    db.logWeight(req.user.id, logDate, weight);
    res.json({ success: true, logDate, weight });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/user/sync-all', authMiddleware, (req, res) => {
  try {
    const { done, water, wts } = req.body;
    const result = db.syncAll(req.user.id, { done, water, wts });
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/user/export', authMiddleware, (req, res) => {
  try {
    const data = db.formatUserData(req.user);
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename=fatloss_backup_${req.user.name.replace(/\s+/g, '_')}.json`);
    res.send(JSON.stringify(data, null, 2));
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', serverTime: new Date().toISOString() });
});

// Serve static frontend files
app.use(express.static(__dirname));

// Fallback to index.html for client-side routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 60-Day Fat Loss App is running locally!`);
  console.log(`🌐 Local URL: http://localhost:${PORT}`);
  console.log(`💾 SQLite DB: /data/fatloss.db`);
  console.log(`======================================================\n`);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    const fallbackPort = Number(PORT) + 1;
    console.log(`Port ${PORT} in use, trying port ${fallbackPort}...`);
    app.listen(fallbackPort, () => {
      console.log(`\n======================================================`);
      console.log(`🚀 60-Day Fat Loss App is running locally!`);
      console.log(`🌐 Local URL: http://localhost:${fallbackPort}`);
      console.log(`======================================================\n`);
    });
  } else {
    console.error('Server error:', err);
  }
});
