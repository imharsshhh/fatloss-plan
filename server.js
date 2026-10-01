const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const db = require('./db.js');

const PORT = process.env.PORT || 3000;

// Content types dictionary for static files
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

// Helper: Parse incoming JSON request body
function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      if (!body.trim()) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch (err) {
        reject(new Error('Invalid JSON body: ' + err.message));
      }
    });
    req.on('error', reject);
  });
}

// Helper: Send JSON response
function sendJson(res, statusCode, data, headers = {}) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, x-secret-key, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    ...headers
  });
  res.end(JSON.stringify(data));
}

// Helper: Resolve authenticated user from request
function getAuthUser(req, searchParams) {
  const authHeader = req.headers['authorization'];
  const secretKey = req.headers['x-secret-key']
    || (authHeader && authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null)
    || searchParams.get('key');

  if (!secretKey) return null;
  return db.getUserBySecretKey(secretKey);
}

// Helper: Serve static file
function serveStaticFile(res, filePath) {
  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      // Fallback to index.html for Single Page App routing
      const indexPath = path.join(__dirname, 'index.html');
      fs.readFile(indexPath, (indexErr, data) => {
        if (indexErr) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('404 Not Found');
          return;
        }
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(data);
      });
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(filePath).pipe(res);
  });
}

// Main HTTP Server
const server = http.createServer(async (req, res) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type, x-secret-key, Authorization',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
    });
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;
  const searchParams = parsedUrl.searchParams;

  // --- API ROUTES ---

  // Health Check
  if (req.method === 'GET' && pathname === '/api/health') {
    return sendJson(res, 200, { status: 'ok', serverTime: new Date().toISOString() });
  }

  // Register User (Onboarding)
  if (req.method === 'POST' && pathname === '/api/auth/register') {
    try {
      const body = await parseJsonBody(req);
      const { name, secretKey, startDate, initialWeight, targetWeight } = body;
      if (!name || !secretKey || !startDate) {
        return sendJson(res, 400, { success: false, error: 'Please provide name, secretKey, and startDate.' });
      }
      const result = db.registerUser({ name, secretKey, startDate, initialWeight, targetWeight });
      return sendJson(res, 201, { success: true, ...result });
    } catch (err) {
      return sendJson(res, 400, { success: false, error: err.message });
    }
  }

  // Login User
  if (req.method === 'POST' && pathname === '/api/auth/login') {
    try {
      const body = await parseJsonBody(req);
      const { secretKey } = body;
      if (!secretKey) {
        return sendJson(res, 400, { success: false, error: 'Secret Key is required.' });
      }
      const result = db.loginUser(secretKey);
      return sendJson(res, 200, { success: true, ...result });
    } catch (err) {
      return sendJson(res, 401, { success: false, error: err.message });
    }
  }

  // Authenticated APIs
  if (pathname.startsWith('/api/user/')) {
    const user = getAuthUser(req, searchParams);
    if (!user) {
      return sendJson(res, 401, { success: false, error: 'Authentication required. Invalid or missing Secret Key.' });
    }

    try {
      if (req.method === 'GET' && pathname === '/api/user/me') {
        const data = db.formatUserData(user);
        return sendJson(res, 200, { success: true, ...data });
      }

      if (req.method === 'POST' && pathname === '/api/user/toggle-task') {
        const body = await parseJsonBody(req);
        const { dayNumber, taskIndex, completed } = body;
        if (dayNumber === undefined || taskIndex === undefined) {
          return sendJson(res, 400, { success: false, error: 'dayNumber and taskIndex required.' });
        }
        db.toggleTask(user.id, dayNumber, taskIndex, completed);
        return sendJson(res, 200, { success: true, dayNumber, taskIndex, completed });
      }

      if (req.method === 'POST' && pathname === '/api/user/water') {
        const body = await parseJsonBody(req);
        const { dayNumber, glasses } = body;
        if (dayNumber === undefined || glasses === undefined) {
          return sendJson(res, 400, { success: false, error: 'dayNumber and glasses required.' });
        }
        db.updateWater(user.id, dayNumber, glasses);
        return sendJson(res, 200, { success: true, dayNumber, glasses });
      }

      if (req.method === 'POST' && pathname === '/api/user/weight') {
        const body = await parseJsonBody(req);
        const { logDate, weight } = body;
        if (!logDate || weight === undefined) {
          return sendJson(res, 400, { success: false, error: 'logDate and weight required.' });
        }
        db.logWeight(user.id, logDate, weight);
        return sendJson(res, 200, { success: true, logDate, weight });
      }

      if (req.method === 'POST' && pathname === '/api/user/sync-all') {
        const body = await parseJsonBody(req);
        const { done, water, wts } = body;
        const result = db.syncAll(user.id, { done, water, wts });
        return sendJson(res, 200, { success: true, ...result });
      }

      if (req.method === 'GET' && pathname === '/api/user/export') {
        const data = db.formatUserData(user);
        const fileName = `fatloss_backup_${user.name.replace(/\s+/g, '_')}.json`;
        res.writeHead(200, {
          'Content-Type': 'application/json',
          'Content-Disposition': `attachment; filename="${fileName}"`,
          'Access-Control-Allow-Origin': '*'
        });
        res.end(JSON.stringify(data, null, 2));
        return;
      }
    } catch (err) {
      return sendJson(res, 500, { success: false, error: err.message });
    }
  }

  // --- STATIC FILES ---
  let safePath = path.normalize(decodeURIComponent(pathname)).replace(/^(\.\.[\/\\])+/, '');
  if (safePath === '/' || safePath === '') {
    safePath = '/index.html';
  }
  const filePath = path.join(__dirname, safePath);
  serveStaticFile(res, filePath);
});

function startServer(portToUse) {
  server.listen(portToUse, () => {
    console.log(`\n======================================================`);
    console.log(`🚀 Zero-Dependency Node.js Server is Running!`);
    console.log(`🌐 Local URL: http://localhost:${portToUse}`);
    console.log(`💾 SQLite DB: /data/fatloss.db`);
    console.log(`⚡ Native HTTP + node:sqlite (Zero npm packages needed)`);
    console.log(`======================================================\n`);
  });
}

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    const nextPort = Number(PORT) + 1;
    console.log(`Port ${PORT} in use, trying ${nextPort}...`);
    startServer(nextPort);
  } else {
    console.error('Server error:', err);
  }
});

startServer(PORT);
