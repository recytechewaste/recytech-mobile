const crypto = require('crypto');
const express = require('express');
const { MongoClient, ServerApiVersion } = require('mongodb');

require('dotenv').config();

const uri = process.env.MONGO_URI;
const port = Number(process.env.PORT || 5000);
const tokenSecret =
  process.env.JWT_SECRET || process.env.AUTH_TOKEN_SECRET || crypto.randomBytes(32).toString('hex');

if (!uri) {
  console.error('MONGO_URI is required. Set it in backend/.env or your shell.');
  process.exit(1);
}

const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  },
});

const app = express();
app.use(express.json());

function database() {
  return process.env.MONGO_DB_NAME ? client.db(process.env.MONGO_DB_NAME) : client.db();
}

function usersCollection() {
  return database().collection('users');
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function normalizeRegistrationRole(role) {
  const normalized = String(role || 'Staff').trim().toLowerCase();
  if (['staff', 'household', 'resident', 'registered user', 'registered_user'].includes(normalized)) {
    return 'Staff';
  }
  return null;
}

function publicUser(user) {
  const firstName = String(user.firstName || '').trim();
  const lastName = String(user.lastName || '').trim();
  return {
    id: user._id.toString(),
    _id: user._id.toString(),
    firstName,
    lastName,
    fullName: String(user.fullName || `${firstName} ${lastName}`).trim(),
    email: user.email,
    role: user.role || 'Staff',
    ...(user.phone ? { phone: user.phone } : {}),
    ...(user.vehicleType ? { vehicleType: user.vehicleType } : {}),
    ...(user.plateNumber ? { plateNumber: user.plateNumber } : {}),
  };
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.pbkdf2Sync(password, salt, 120000, 32, 'sha256').toString('hex');
  return `pbkdf2_sha256$120000$${salt}$${hash}`;
}

function verifyPassword(password, storedHash) {
  const [scheme, roundsText, salt, expected] = String(storedHash || '').split('$');
  if (scheme !== 'pbkdf2_sha256' || !roundsText || !salt || !expected) return false;

  const actual = crypto
    .pbkdf2Sync(password, salt, Number(roundsText), 32, 'sha256')
    .toString('hex');

  const actualBytes = Buffer.from(actual, 'hex');
  const expectedBytes = Buffer.from(expected, 'hex');
  return actualBytes.length === expectedBytes.length && crypto.timingSafeEqual(actualBytes, expectedBytes);
}

function signToken(user) {
  const payload = Buffer.from(
    JSON.stringify({
      sub: user._id.toString(),
      email: user.email,
      role: user.role,
      iat: Math.floor(Date.now() / 1000),
    }),
  ).toString('base64url');
  const signature = crypto.createHmac('sha256', tokenSecret).update(payload).digest('base64url');
  return `${payload}.${signature}`;
}

function authResponse(user, statusCode, res) {
  const safeUser = publicUser(user);
  return res.status(statusCode).json({
    message: statusCode === 201 ? 'Registration successful.' : 'Login successful.',
    token: signToken(user),
    user: safeUser,
    data: {
      user: safeUser,
    },
  });
}

app.get('/api/health', async (_req, res, next) => {
  try {
    await database().command({ ping: 1 });
    res.json({ ok: true, message: 'RecyTech API is connected.' });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/register', async (req, res, next) => {
  try {
    const firstName = String(req.body.firstName || '').trim();
    const lastName = String(req.body.lastName || '').trim();
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');
    const role = normalizeRegistrationRole(req.body.role);

    if (!firstName || !lastName) {
      return res.status(400).json({ message: 'First name and last name are required.' });
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({ message: 'Enter a valid email address.' });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters.' });
    }

    if (!role) {
      return res.status(400).json({ message: 'Mobile registration is only available for Registered Users.' });
    }

    const users = usersCollection();
    await users.createIndex({ email: 1 }, { unique: true });

    const existing = await users.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: 'An account with this email already exists.' });
    }

    const now = new Date();
    const user = {
      firstName,
      lastName,
      fullName: `${firstName} ${lastName}`.trim(),
      email,
      role,
      passwordHash: hashPassword(password),
      createdAt: now,
      updatedAt: now,
    };

    const result = await users.insertOne(user);
    return authResponse({ ...user, _id: result.insertedId }, 201, res);
  } catch (error) {
    if (error && error.code === 11000) {
      return res.status(409).json({ message: 'An account with this email already exists.' });
    }
    next(error);
  }
});

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');
    const requestedRole = req.body.role ? String(req.body.role).trim().toLowerCase() : '';

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await usersCollection().findOne({ email });
    if (!user || !verifyPassword(password, user.passwordHash)) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    if (requestedRole && requestedRole !== String(user.role || '').toLowerCase()) {
      return res.status(403).json({ message: `This account is registered as ${user.role}.` });
    }

    return authResponse(user, 200, res);
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/logout', (_req, res) => {
  res.json({ message: 'Logged out successfully.' });
});

app.use((req, res) => {
  res.status(404).json({ message: `Route not found: ${req.method} ${req.originalUrl}` });
});

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(500).json({ message: 'Server error. Please try again later.' });
});

async function start() {
  await client.connect();
  await database().command({ ping: 1 });
  console.log('Connected to MongoDB Atlas.');

  const server = app.listen(port, '0.0.0.0', () => {
    console.log(`RecyTech API listening on http://localhost:${port}/api`);
  });

  async function shutdown() {
    server.close(async () => {
      await client.close();
      process.exit(0);
    });
  }

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

start().catch((error) => {
  console.error('Failed to start RecyTech API:', error);
  process.exit(1);
});
