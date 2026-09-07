const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const { MongoClient, ObjectId, ServerApiVersion } = require('mongodb');
const { createIotRouter, ensureIotIndexes } = require('./routes/iot');

require('dotenv').config();

let nodemailer = null;
try {
  nodemailer = require('nodemailer');
} catch (_) {
  nodemailer = null;
}

const uri = process.env.MONGO_URI;
const port = Number(process.env.PORT || 5000);
const tokenSecret =
  process.env.JWT_SECRET || process.env.AUTH_TOKEN_SECRET || crypto.randomBytes(32).toString('hex');
const isProduction = process.env.NODE_ENV === 'production';
const otpTtlMinutes = Number(process.env.OTP_TTL_MINUTES || 10);
const otpResendCooldownSeconds = Number(process.env.OTP_RESEND_COOLDOWN_SECONDS || 60);
const maxOtpAttempts = Number(process.env.OTP_MAX_ATTEMPTS || 5);
const allowDevOtpResponse =
  !isProduction && String(process.env.ALLOW_DEV_OTP_RESPONSE || '').toLowerCase() === 'true';

const ACCOUNT_STATUSES = Object.freeze({
  pending: 'pending',
  active: 'active',
  disabled: 'disabled',
  rejected: 'rejected',
});

const STATUS_ALIASES = new Map([
  ['pending', ACCOUNT_STATUSES.pending],
  ['active', ACCOUNT_STATUSES.active],
  ['enabled', ACCOUNT_STATUSES.active],
  ['approved', ACCOUNT_STATUSES.active],
  ['inactive', ACCOUNT_STATUSES.disabled],
  ['disabled', ACCOUNT_STATUSES.disabled],
  ['deactivated', ACCOUNT_STATUSES.disabled],
  ['rejected', ACCOUNT_STATUSES.rejected],
]);

if (!uri) {
  console.error('MONGO_URI is required. Set it in backend/.env or your shell.');
  process.exit(1);
}

if (isProduction && !process.env.JWT_SECRET && !process.env.AUTH_TOKEN_SECRET) {
  console.error('JWT_SECRET is required in production.');
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
app.use((req, res, next) => {
  console.log(`[API] ${req.method} ${req.originalUrl}`);
  res.on('finish', () => {
    console.log(`[API] ${res.statusCode} ${req.method} ${req.originalUrl}`);
  });
  next();
});

app.use(express.json());

function database() {
  return process.env.MONGO_DB_NAME ? client.db(process.env.MONGO_DB_NAME) : client.db();
}

function usersCollection() {
  return database().collection('users');
}

function collectorsCollection() {
  return database().collection('collectors');
}

function collectionRequestsCollection() {
  return database().collection('collectionrequests');
}

function legacyRequestsCollection() {
  return database().collection('requests');
}

function collectorReportsCollection() {
  return database().collection('collectorreports');
}

function binsCollection() {
  return database().collection('bins');
}

function partnerOrganizationsCollection() {
  return database().collection('partnerorganizations');
}

function legacyPartnerAccountsCollection() {
  return database().collection('lguaccounts');
}

function householdPointsAccountsCollection() {
  return database().collection('householdpointsaccounts');
}

function pointsTransactionsCollection() {
  return database().collection('pointstransactions');
}

function partnerRewardsCollection() {
  return database().collection('partnerrewards');
}

function rewardRedemptionsCollection() {
  return database().collection('rewardredemptions');
}

function householdDropOffsCollection() {
  return database().collection('householddropoffs');
}

function pointRulesCollection() {
  return database().collection('pointrules');
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function normalizeRoleKey(role) {
  return String(role || '')
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, '_')
    .replace(/_+/g, '_');
}

function normalizeAuthRole(role) {
  const normalized = normalizeRoleKey(role || 'Staff');
  if (['staff', 'household', 'resident', 'registered_user', 'regular_user', 'user'].includes(normalized)) {
    return 'household';
  }
  if (['lgu', 'partner_organization', 'partner_org', 'partner', 'organization'].includes(normalized)) {
    return 'partner_org';
  }
  if (normalized === 'collector') {
    return 'collector';
  }
  return null;
}

function normalizeRegistrationRole(role) {
  return normalizeAuthRole(role || 'household');
}

function normalizeAccountStatus(status) {
  return STATUS_ALIASES.get(normalizeRoleKey(status)) || null;
}

function accountStatusFor(user = {}) {
  return normalizeAccountStatus(user.accountStatus) || normalizeAccountStatus(user.status) || ACCOUNT_STATUSES.active;
}

function legacyStatusFor(status) {
  switch (normalizeAccountStatus(status)) {
    case ACCOUNT_STATUSES.pending:
      return 'Pending';
    case ACCOUNT_STATUSES.disabled:
      return 'Inactive';
    case ACCOUNT_STATUSES.rejected:
      return 'Rejected';
    case ACCOUNT_STATUSES.active:
    default:
      return 'Active';
  }
}

function canIssueAuth(user = {}) {
  const status = accountStatusFor(user);
  if (status === ACCOUNT_STATUSES.pending) {
    return {
      ok: false,
      status: 403,
      code: 'account_pending',
      message: 'Account is pending. Please contact support.',
    };
  }
  if (status === ACCOUNT_STATUSES.disabled) {
    return {
      ok: false,
      status: 403,
      code: 'account_disabled',
      message: 'Account is disabled. Please contact an administrator.',
    };
  }
  if (status === ACCOUNT_STATUSES.rejected) {
    return {
      ok: false,
      status: 403,
      code: 'account_rejected',
      message: 'Account registration was rejected. Please contact an administrator.',
    };
  }
  return { ok: true };
}

function isEmailVerified(user) {
  if (user.emailVerified === false) return false;
  if (user.emailVerification && !user.emailVerified) return false;
  return true;
}

function objectIdFrom(value) {
  return ObjectId.isValid(String(value || '')) ? new ObjectId(value) : null;
}

function publicUser(user) {
  const firstName = String(user.firstName || '').trim();
  const lastName = String(user.lastName || '').trim();
  const accountStatus = accountStatusFor(user);
  const role = normalizeAuthRole(user.role) || user.role || 'household';
  return {
    id: user._id.toString(),
    _id: user._id.toString(),
    firstName,
    lastName,
    fullName: String(user.fullName || `${firstName} ${lastName}`).trim(),
    email: user.email,
    role,
    legacyRole: user.role,
    emailVerified: isEmailVerified(user),
    accountStatus,
    status: legacyStatusFor(accountStatus),
    ...(user.organizationName ? { organizationName: user.organizationName } : {}),
    ...(user.contactPerson ? { contactPerson: user.contactPerson } : {}),
    ...(user.contactNumber ? { contactNumber: user.contactNumber } : {}),
    ...(user.phone ? { phone: user.phone } : {}),
    ...(user.vehicleType ? { vehicleType: user.vehicleType } : {}),
    ...(user.plateNumber ? { plateNumber: user.plateNumber } : {}),
  };
}

function publicPartnerAccount(account) {
  const organizationName = String(account.organizationName || account.name || '').trim();
  const contactPerson = String(account.contactPerson || account.fullName || organizationName).trim();
  const [firstName = '', ...lastNameParts] = contactPerson.split(/\s+/).filter(Boolean);
  const contactNumber = String(account.contactNumber || account.phone || '').trim();
  const accountStatus = accountStatusFor(account);

  return {
    id: account._id.toString(),
    _id: account._id.toString(),
    firstName,
    lastName: lastNameParts.join(' '),
    fullName: contactPerson,
    email: account.email,
    role: 'partner_org',
    legacyRole: account.role || 'Partner Organization',
    emailVerified: account.emailVerified !== false,
    accountStatus,
    status: legacyStatusFor(accountStatus),
    organizationName,
    contactPerson,
    ...(contactNumber ? { contactNumber, phone: contactNumber } : {}),
    ...(account.jurisdiction ? { jurisdiction: account.jurisdiction } : {}),
  };
}

async function mirrorPartnerOrganizationProfile(user, { organizationName, contactPerson, contactNumber, now }) {
  await partnerOrganizationsCollection().updateOne(
    { user: user._id },
    {
      $set: {
        user: user._id,
        organizationName,
        contactPerson,
        contactNumber,
        address: '',
        status: legacyStatusFor(accountStatusFor(user)),
        updatedAt: now,
      },
      $setOnInsert: { createdAt: now },
    },
    { upsert: true },
  );

  await legacyPartnerAccountsCollection().updateOne(
    { email: user.email },
    {
      $set: {
        name: organizationName,
        email: user.email,
        contactPerson,
        phone: contactNumber,
        status: legacyStatusFor(accountStatusFor(user)),
        updatedAt: now,
      },
      $setOnInsert: {
        assignedBins: [],
        createdAt: now,
      },
    },
    { upsert: true },
  );
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.pbkdf2Sync(password, salt, 120000, 32, 'sha256').toString('hex');
  return `pbkdf2_sha256$120000$${salt}$${hash}`;
}

function isPbkdf2PasswordHash(storedHash) {
  const [scheme, roundsText, salt, expected] = String(storedHash || '').split('$');
  return scheme === 'pbkdf2_sha256' && Boolean(roundsText && salt && expected);
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

function isLegacyBcryptHash(storedHash) {
  return /^\$2[ab]\$\d{2}\$[./A-Za-z0-9]{53}$/.test(String(storedHash || ''));
}

async function verifyLoginPassword(password, user) {
  if (isPbkdf2PasswordHash(user?.passwordHash)) {
    return {
      ok: verifyPassword(password, user.passwordHash),
      legacyBcrypt: false,
    };
  }

  if (!isLegacyBcryptHash(user?.password)) {
    return { ok: false, legacyBcrypt: false };
  }

  const ok = await bcrypt.compare(password, user.password);
  return { ok, legacyBcrypt: ok };
}

function base64UrlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function signToken(user, { purpose = 'auth', expiresInSeconds = 7 * 24 * 60 * 60, source = 'users' } = {}) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlJson({ alg: 'HS256', typ: 'JWT' });
  const payload = base64UrlJson({
    sub: user._id.toString(),
    email: user.email,
    role: user.role,
    source,
    purpose,
    iat: now,
    exp: now + expiresInSeconds,
  });
  const signature = crypto
    .createHmac('sha256', tokenSecret)
    .update(`${header}.${payload}`)
    .digest('base64url');
  return `${header}.${payload}.${signature}`;
}

function verifyToken(token, expectedPurpose = 'auth') {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;

  const [header, payload, signature] = parts;
  const expected = crypto
    .createHmac('sha256', tokenSecret)
    .update(`${header}.${payload}`)
    .digest('base64url');
  const sigBytes = Buffer.from(signature);
  const expectedBytes = Buffer.from(expected);
  if (sigBytes.length !== expectedBytes.length || !crypto.timingSafeEqual(sigBytes, expectedBytes)) return null;

  try {
    const claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    if (claims.exp && Number(claims.exp) < Math.floor(Date.now() / 1000)) return null;
    if (claims.purpose !== expectedPurpose) return null;
    return claims;
  } catch (_) {
    return null;
  }
}

function authResponse(user, statusCode, res, { source = 'users', userMapper = publicUser } = {}) {
  const safeUser = userMapper(user);
  const token = signToken({ ...user, role: safeUser.role }, { source });
  return res.status(statusCode).json({
    message: 'Login successful.',
    token,
    accessToken: token,
    user: safeUser,
    data: {
      token,
      user: safeUser,
    },
  });
}

function bearerToken(req) {
  const [scheme, token] = String(req.headers.authorization || '').split(/\s+/);
  return scheme?.toLowerCase() === 'bearer' ? token : '';
}

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function hashOtp(email, pin, purpose) {
  return crypto
    .createHmac('sha256', tokenSecret)
    .update(`${purpose}:${normalizeEmail(email)}:${pin}`)
    .digest('hex');
}

function createPinState(email, purpose, now = new Date()) {
  const pin = generateOtp();
  const expiresAt = new Date(now.getTime() + otpTtlMinutes * 60 * 1000);
  const resendAvailableAt = new Date(now.getTime() + otpResendCooldownSeconds * 1000);
  return {
    pin,
    state: {
      pinHash: hashOtp(email, pin, purpose),
      expiresAt,
      resendAvailableAt,
      attempts: 0,
      createdAt: now,
      sentAt: now,
    },
  };
}

function assertValidPinState(user, fieldName, pin, purpose) {
  const state = user[fieldName];
  if (!state || !state.pinHash) {
    return { ok: false, status: 400, message: 'No active verification PIN. Please request a new PIN.' };
  }
  if (state.expiresAt && new Date(state.expiresAt).getTime() < Date.now()) {
    return { ok: false, status: 410, message: 'Verification PIN has expired. Please request a new PIN.' };
  }
  if (Number(state.attempts || 0) >= maxOtpAttempts) {
    return { ok: false, status: 429, message: 'Too many incorrect PIN attempts. Please request a new PIN.' };
  }

  const expected = Buffer.from(state.pinHash, 'hex');
  const actual = Buffer.from(hashOtp(user.email, pin, purpose), 'hex');
  if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) {
    return { ok: false, status: 400, message: 'Invalid verification PIN.' };
  }
  return { ok: true };
}

function mailTransportConfig() {
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) return null;
  return {
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: String(process.env.SMTP_SECURE || '').toLowerCase() === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  };
}

async function sendPinEmail({ to, pin, purpose }) {
  const config = mailTransportConfig();
  if (!config || !nodemailer) return false;

  const transporter = nodemailer.createTransport(config);
  const subject =
    purpose === 'email_verification' ? 'Your RecyTech verification PIN' : 'Your RecyTech password reset PIN';
  const intro =
    purpose === 'email_verification'
      ? 'Use this PIN to verify your RecyTech email address.'
      : 'Use this PIN to reset your RecyTech password.';

  await transporter.sendMail({
    from: process.env.EMAIL_FROM || process.env.SMTP_USER,
    to,
    subject,
    text: `${intro}\n\nPIN: ${pin}\n\nThis PIN expires in ${otpTtlMinutes} minutes.`,
  });
  return true;
}

function emailPinResponse(res, statusCode, { message, email, sent, pin }) {
  const payload = {
    message,
    emailVerificationRequired: true,
    email,
    emailSent: sent,
  };
  if (allowDevOtpResponse && pin) payload.devOtp = pin;
  return res.status(statusCode).json(payload);
}

function readDouble(...values) {
  for (const value of values) {
    if (value === null || value === undefined || value === '') continue;
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function readNested(object, path) {
  return path.split('.').reduce((current, key) => {
    if (!current || typeof current !== 'object') return undefined;
    return current[key];
  }, object);
}

const ACTIVE_COLLECTOR_JOB_STATUSES = Object.freeze([
  'queued',
  'assigned',
  'collector_assigned',
  'Approved',
  'Assigned',
  'For Pickup',
  'In-Transit',
  'on_the_way',
  'Arrived',
  'arrived',
  'In Progress',
  'in_progress',
  'Collected',
  'ready_for_completion',
]);

const COMPLETED_COLLECTION_STATUSES = Object.freeze([
  'completed',
  'Completed',
]);

function objectIdOrValue(value) {
  const text = String(value || '').trim();
  if (!text) return null;
  return objectIdFrom(text) || text;
}

function objectIdString(value) {
  if (!value) return '';
  if (value instanceof ObjectId) return value.toString();
  if (value._id) return objectIdString(value._id);
  return String(value);
}

function collectorDisplayName(collector = {}) {
  return [collector.firstName, collector.lastName]
    .map((part) => String(part || '').trim())
    .filter(Boolean)
    .join(' ')
    .trim();
}

function fullNameForAccount(account = {}) {
  const fromFullName = String(account.fullName || '').trim();
  if (fromFullName) return fromFullName;
  return collectorDisplayName(account);
}

function dateValue(value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function newestDate(...values) {
  return values.map(dateValue).filter(Boolean).sort((a, b) => b - a)[0] || new Date(0);
}

function normalizeStatusForSort(status) {
  const normalized = String(status || '')
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, '_')
    .replace(/_+/g, '_');
  if (normalized === 'assigned' || normalized === 'approved' || normalized === 'queued') return 0;
  if (normalized === 'on_the_way' || normalized === 'in_transit') return 1;
  if (normalized === 'arrived') return 2;
  if (normalized === 'in_progress' || normalized === 'started' || normalized === 'collection_started') return 3;
  if (normalized === 'collected' || normalized === 'ready_for_completion') return 4;
  return 5;
}

function collectorIdCandidates(user = {}, collector = {}) {
  const values = [
    collector._id,
    collector.id,
    user._id,
    user.id,
  ]
    .map(objectIdString)
    .filter(Boolean);
  return [...new Set(values)];
}

function assignmentClauses(user = {}, collector = {}) {
  const idCandidates = collectorIdCandidates(user, collector);
  const ids = idCandidates.flatMap((id) => {
    const objectId = objectIdFrom(id);
    return objectId ? [objectId, id] : [id];
  });
  const name = fullNameForAccount(collector) || fullNameForAccount(user);
  const email = normalizeEmail(user.email);
  const clauses = [];

  if (ids.length > 0) {
    clauses.push({ assignedCollectorId: { $in: ids } });
    clauses.push({ assignedCollector: { $in: ids } });
    clauses.push({ collectorId: { $in: ids } });
  }

  if (name) {
    clauses.push({ assignedCollectorName: name });
    clauses.push({ collectorName: name });
  }

  if (email) {
    clauses.push({ collectorEmail: email });
    clauses.push({ assignedCollectorEmail: email });
  }

  return clauses.length ? clauses : [{ _id: null }];
}

async function findReferencedDocument(collection, value) {
  const id = objectIdOrValue(value);
  if (!id) return null;
  if (id instanceof ObjectId) {
    return collection.findOne({ _id: id });
  }
  return collection.findOne({ $or: [{ _id: id }, { id }, { binCode: id }, { publicQrCode: id }] });
}

async function authenticatedUser(req, res) {
  const claims = verifyToken(bearerToken(req));
  if (!claims?.sub) {
    res.status(401).json({ message: 'Not authorized.' });
    return null;
  }

  const accountId = objectIdFrom(claims.sub);
  if (!accountId) {
    res.status(401).json({ message: 'Not authorized.' });
    return null;
  }

  const isLegacyPartnerToken = claims.source === 'lguaccounts';
  const user = isLegacyPartnerToken
    ? await legacyPartnerAccountsCollection().findOne({ _id: accountId })
    : await usersCollection().findOne({ _id: accountId });
  if (!user) {
    res.status(401).json({ message: 'Not authorized.' });
    return null;
  }

  const issueCheck = canIssueAuth(user);
  if (!issueCheck.ok) {
    res.status(issueCheck.status).json({
      code: issueCheck.code,
      message: issueCheck.message,
      accountStatus: accountStatusFor(user),
    });
    return null;
  }

  return user;
}

async function authenticatedCollector(req, res) {
  const user = await authenticatedUser(req, res);
  if (!user) return null;

  if (normalizeAuthRole(user.role) !== 'collector') {
    res.status(403).json({ message: 'Not authorized as a collector.' });
    return null;
  }

  const userId = objectIdString(user._id);
  const profile = await collectorsCollection().findOne({
    $or: [
      { user: user._id },
      { user: userId },
      { email: normalizeEmail(user.email) },
    ],
  });

  return {
    user,
    collector: profile || {
      _id: user._id,
      firstName: user.firstName,
      lastName: user.lastName,
      fullName: user.fullName,
      phone: user.phone || user.contactNumber || '',
      status: legacyStatusFor(accountStatusFor(user)),
    },
  };
}

async function authenticatedPartner(req, res) {
  const claims = verifyToken(bearerToken(req));
  const user = await authenticatedUser(req, res);
  if (!user) return null;

  const isLegacyPartnerSession =
    claims?.source === 'lguaccounts' &&
    normalizeAuthRole(claims.role) === 'partner_org';
  if (normalizeAuthRole(user.role) !== 'partner_org' && !isLegacyPartnerSession) {
    res.status(403).json({ message: 'Not authorized as a partner organization.' });
    return null;
  }

  const userId = objectIdString(user._id);
  const organizationName = String(user.organizationName || user.name || '').trim();
  const canonicalUser = isLegacyPartnerSession
    ? await usersCollection().findOne({ email: normalizeEmail(user.email) })
    : user;
  const profileClauses = [
    { user: user._id },
    { user: userId },
  ];
  if (canonicalUser && objectIdString(canonicalUser._id) !== userId) {
    profileClauses.push(
      { user: canonicalUser._id },
      { user: objectIdString(canonicalUser._id) },
    );
  }
  if (organizationName) profileClauses.push({ organizationName });

  const partner = await partnerOrganizationsCollection().findOne({
    $or: profileClauses,
  });

  return { user, canonicalUser, partner };
}

async function authenticatedHousehold(req, res) {
  const user = await authenticatedUser(req, res);
  if (!user) return null;
  if (normalizeAuthRole(user.role) !== 'household') {
    res.status(403).json({ message: 'Not authorized as a registered user.' });
    return null;
  }
  return user;
}

function householdAccountScope(user) {
  return {
    householdUserId: user._id,
    householdAccountModel: 'User',
  };
}

function pointsTransactionPayload(transaction = {}) {
  const amount = Number.isFinite(Number(transaction.amount)) ? Number(transaction.amount) : 0;
  const sign = transaction.type === 'debit' ? -1 : 1;
  return {
    id: objectIdString(transaction._id),
    type: transaction.type || '',
    amount,
    signedAmount: sign * amount,
    sourceType: transaction.sourceType || '',
    sourceId: objectIdString(transaction.sourceId),
    description: transaction.description || '',
    partnerOrganizationId: objectIdString(transaction.partnerOrganizationId) || null,
    binId: objectIdString(transaction.binId) || null,
    createdAt: transaction.createdAt || null,
  };
}

function householdRewardPayload(reward = {}, { partner = null, bins = [], balance = 0 } = {}) {
  const applicableBinIds = Array.isArray(reward.applicableBinIds)
    ? reward.applicableBinIds.map(objectIdString).filter(Boolean)
    : [];
  return {
    id: objectIdString(reward._id),
    partnerOrganizationId: objectIdString(reward.partnerOrganizationId),
    partnerOrganizationName: partner?.organizationName || reward.partnerOrganizationName || '',
    title: reward.title || 'Partner Reward',
    description: reward.description || '',
    pointsCost: Number.isFinite(Number(reward.pointsCost)) ? Number(reward.pointsCost) : 0,
    active: reward.active !== false,
    applicableBinIds,
    applicableBins: bins.map((bin) => ({
      id: objectIdString(bin._id),
      binCode: bin.binCode || '',
      name: bin.name || '',
    })),
    appliesToAllPartnerBins: applicableBinIds.length === 0,
    canRedeem: Number(balance) >= Number(reward.pointsCost || 0),
    createdAt: reward.createdAt || null,
    updatedAt: reward.updatedAt || null,
  };
}

function householdRedemptionPayload(redemption = {}, { partner = null } = {}) {
  return {
    id: objectIdString(redemption._id),
    partnerOrganizationId: objectIdString(redemption.partnerOrganizationId),
    partnerOrganizationName: partner?.organizationName || redemption.partnerOrganizationName || '',
    rewardId: objectIdString(redemption.rewardId),
    rewardTitle: redemption.rewardTitleSnapshot || redemption.rewardTitle || 'Partner Reward',
    rewardTitleSnapshot: redemption.rewardTitleSnapshot || redemption.rewardTitle || 'Partner Reward',
    pointsCost: Number(redemption.pointsCostSnapshot || redemption.pointsCost || 0),
    pointsCostSnapshot: Number(redemption.pointsCostSnapshot || redemption.pointsCost || 0),
    status: redemption.status || 'requested',
    redeemedAt: redemption.redeemedAt || redemption.createdAt || null,
    fulfilledAt: redemption.fulfilledAt || null,
    cancelledAt: redemption.cancelledAt || null,
    createdAt: redemption.createdAt || null,
    updatedAt: redemption.updatedAt || null,
  };
}

function normalizeCategoryKey(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, '_')
    .replace(/_+/g, '_');
}

function displayCategory(value) {
  const normalized = normalizeCategoryKey(value);
  if (normalized === 'pcb') return 'PCB';
  return normalized
    .split('_')
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

async function findHouseholdBin(value) {
  const code = String(value || '').trim().toUpperCase();
  if (!code) return null;
  const id = objectIdFrom(code);
  const clauses = [
    { binCode: code },
    { publicQrCode: code },
    { publicCode: code },
  ];
  if (id) clauses.push({ _id: id });
  return binsCollection().findOne({ $or: clauses });
}

async function householdBinPayload(bin) {
  const partner = await findReferencedDocument(
    partnerOrganizationsCollection(),
    bin.partnerOrganizationId,
  );
  const payload = publicBinFromDocument({
    ...bin,
    partnerOrganizationName: partner?.organizationName || bin.partnerOrganizationName,
  });
  const categories = Array.isArray(bin.acceptedCategories) ? bin.acceptedCategories : [];
  return {
    ...payload,
    acceptedCategories: categories,
    acceptedCategoryDisplayNames: categories.map((category) => ({
      value: category,
      label: displayCategory(category),
    })),
  };
}

async function householdDropOffPayload(dropOff) {
  const [bin, partner] = await Promise.all([
    findReferencedDocument(binsCollection(), dropOff.binId),
    findReferencedDocument(partnerOrganizationsCollection(), dropOff.partnerOrganizationId),
  ]);
  return {
    id: objectIdString(dropOff._id),
    userId: objectIdString(dropOff.householdUserId),
    binId: bin?.binCode || objectIdString(dropOff.binId),
    binName: bin?.name || 'RecyTech Bin',
    binCode: bin?.binCode || '',
    publicQrCode: bin?.publicQrCode || '',
    partnerOrganizationName: partner?.organizationName || '',
    location: bin?.address || '',
    locationDescription: bin?.address || '',
    submissionMethod: dropOff.submissionMethod || 'manual',
    items: (Array.isArray(dropOff.items) ? dropOff.items : []).map((item) => ({
      category: item.category,
      categoryLabel: displayCategory(item.category),
      quantity: Number(item.quantity || 0),
    })),
    submittedAt: dropOff.submittedAt || dropOff.createdAt || null,
    createdAt: dropOff.submittedAt || dropOff.createdAt || null,
    status: dropOff.status || 'submitted',
    pointsStatus: dropOff.pointsStatus || 'not_processed',
    pointsAwarded: Number(dropOff.pointsAwarded || 0),
    rewardEligible: dropOff.pointsStatus === 'credited',
    rewardStatus: dropOff.pointsStatus || 'not_processed',
  };
}

async function awardHouseholdDropOffPoints(dropOff) {
  const scope = {
    householdUserId: dropOff.householdUserId,
    householdAccountModel: dropOff.householdAccountModel,
  };
  const existing = await pointsTransactionsCollection().findOne({
    sourceType: 'household_drop_off',
    sourceId: dropOff._id,
    type: 'credit',
  });
  if (existing) {
    await householdDropOffsCollection().updateOne(
      { _id: dropOff._id },
      { $set: { pointsStatus: 'credited', pointsAwarded: existing.amount, updatedAt: new Date() } },
    );
    return Number(existing.amount || 0);
  }

  const categories = [...new Set(dropOff.items.map((item) => item.category))];
  const rules = await pointRulesCollection()
    .find({ category: { $in: categories }, active: true })
    .toArray();
  const byCategory = new Map(rules.map((rule) => [rule.category, rule]));
  if (categories.some((category) => !byCategory.has(category))) {
    await householdDropOffsCollection().updateOne(
      { _id: dropOff._id },
      { $set: { pointsStatus: 'failed', pointsAwarded: 0, updatedAt: new Date() } },
    );
    return 0;
  }

  const points = dropOff.items.reduce(
    (total, item) => total + Number(item.quantity) * Number(byCategory.get(item.category).pointsPerItem),
    0,
  );
  if (!Number.isInteger(points) || points <= 0) return 0;

  await householdPointsAccountsCollection().findOneAndUpdate(
    scope,
    { $setOnInsert: { ...scope, balance: 0, createdAt: new Date(), updatedAt: new Date() } },
    { upsert: true, returnDocument: 'after' },
  );
  try {
    await pointsTransactionsCollection().insertOne({
      ...scope,
      type: 'credit',
      amount: points,
      sourceType: 'household_drop_off',
      sourceId: dropOff._id,
      description: `Drop-off points: ${dropOff.items.map((item) => `${displayCategory(item.category)} x ${item.quantity}`).join(', ')}`,
      partnerOrganizationId: dropOff.partnerOrganizationId,
      binId: dropOff.binId,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await householdPointsAccountsCollection().updateOne(
      scope,
      { $inc: { balance: points }, $set: { updatedAt: new Date() } },
    );
  } catch (error) {
    if (error?.code !== 11000) throw error;
  }
  await householdDropOffsCollection().updateOne(
    { _id: dropOff._id },
    { $set: { pointsStatus: 'credited', pointsAwarded: points, updatedAt: new Date() } },
  );
  return points;
}

function partnerReferenceValues(auth) {
  const values = [auth.partner?._id, auth.canonicalUser?._id, auth.user?._id]
    .map(objectIdString)
    .filter(Boolean)
    .flatMap((value) => {
      const objectId = objectIdFrom(value);
      return objectId ? [objectId, value] : [value];
    });
  return [...new Set(values.map(objectIdString))].flatMap((value) => {
    const objectId = objectIdFrom(value);
    return objectId ? [objectId, value] : [value];
  });
}

function partnerOwnershipClauses(auth) {
  const values = partnerReferenceValues(auth);
  return [
    { partnerOrganizationId: { $in: values } },
    { assignedLguId: { $in: values } },
    { lguId: { $in: values } },
  ];
}

function fullnessStatusFor(fillPercentage, fallback) {
  const supplied = String(fallback || '').trim();
  if (supplied) return supplied;
  if (fillPercentage === null) return 'requires_inspection';
  if (fillPercentage >= 90) return 'full';
  if (fillPercentage >= 70) return 'nearly_full';
  if (fillPercentage <= 0) return 'empty';
  return 'partially_filled';
}

function partnerBinPayload(bin = {}, activeRequest = null, partner = null) {
  const fillPercentage = readDouble(bin.latestFillPercentage, bin.fillPercentage, bin.fillLevel);
  const lastUpdatedAt = bin.lastSensorUpdatedAt || bin.lastUpdatedAt || null;
  const binCode = String(bin.binCode || bin.binId || bin.code || bin._id || '').trim();
  const name = String(bin.name || bin.binName || bin.displayName || binCode).trim();
  const location = bin.location && typeof bin.location === 'object'
    ? String(bin.location.address || bin.location.name || '').trim()
    : String(bin.address || bin.location || '').trim();
  const categories = Array.isArray(bin.acceptedCategories) ? bin.acceptedCategories : [];

  return {
    id: objectIdString(bin._id),
    binId: binCode,
    binCode,
    binName: name,
    name,
    assignedLguId: objectIdString(bin.partnerOrganizationId || bin.assignedLguId || bin.lguId),
    partnerOrganizationId: objectIdString(bin.partnerOrganizationId),
    partnerOrganizationName:
      partner?.organizationName || bin.partnerOrganizationName || bin.organizationName || '',
    publicQrCode: bin.publicQrCode || '',
    acceptedCategories: categories,
    acceptedCategoryDisplayNames: categories.map((category) =>
      String(category)
        .replace(/[_-]+/g, ' ')
        .replace(/\b\w/g, (letter) => letter.toUpperCase())),
    location,
    address: location,
    latitude: readDouble(bin.latitude, bin.lat),
    longitude: readDouble(bin.longitude, bin.lng, bin.lon),
    distanceCm: readDouble(bin.distanceCm, bin.distance_mm == null ? null : Number(bin.distance_mm) / 10),
    fillPercentage,
    fullnessStatus: fullnessStatusFor(fillPercentage, bin.fullnessStatus),
    sensorStatus: bin.latestSensorStatus || bin.sensorStatus || 'unknown',
    controllerStatus: bin.latestControllerStatus || bin.controllerStatus || 'unknown',
    lastUpdatedAt,
    lastSensorUpdatedAt: lastUpdatedAt,
    lastCollectionAt: bin.lastCollectionAt || bin.lastCollectionDate || null,
    activeCollectionRequest: activeRequest,
    hasActiveCollectionRequest: Boolean(activeRequest),
    isActive: bin.active !== false && bin.isActive !== false,
  };
}

async function partnerBins(auth) {
  const assignedBins = Array.isArray(auth.user.assignedBins)
    ? auth.user.assignedBins.map(objectIdOrValue).filter(Boolean)
    : [];
  const ownership = partnerOwnershipClauses(auth);
  if (assignedBins.length) ownership.push({ _id: { $in: assignedBins } });

  return binsCollection()
    .find({ $or: ownership })
    .sort({ binCode: 1, name: 1 })
    .toArray();
}

const ACTIVE_PARTNER_REQUEST_STATUSES = Object.freeze([
  'pending',
  'queued',
  'assigned',
  'collector_assigned',
  'on_the_way',
  'arrived',
  'in_progress',
  'collected',
  'ready_for_completion',
  'Pending',
  'Approved',
  'Assigned',
  'For Pickup',
  'In-Transit',
  'In Progress',
  'Collected',
]);

async function collectionRequestsForPartner(auth) {
  return collectionRequestsCollection()
    .find({ $or: partnerOwnershipClauses(auth) })
    .sort({ requestedAt: -1, createdAt: -1 })
    .limit(200)
    .toArray();
}

function collectionRequestPayload(request = {}, { partner = null, bin = null, collector = null } = {}) {
  const snapshot = request.binSnapshot || {};
  const assignedCollector = collector || {};
  const binCode = snapshot.binCode || bin?.binCode || request.binCode || '';
  const binName = snapshot.name || bin?.name || request.binName || binCode;
  const address = snapshot.address || bin?.address || request.location || request.address || '';
  const fillPercentage =
    snapshot.latestFillPercentage ?? bin?.latestFillPercentage ?? request.fillPercentage ?? null;

  return {
    _id: request._id,
    id: objectIdString(request._id),
    partnerOrganizationId: objectIdString(request.partnerOrganizationId),
    partnerOrganizationName:
      partner?.organizationName || request.partnerOrganizationName || request.organizationName || '',
    binDatabaseId: objectIdString(request.binId),
    binId: binCode || objectIdString(request.binId),
    binCode,
    binName,
    name: binName,
    address,
    location: address,
    latitude: snapshot.latitude ?? bin?.latitude ?? request.latitude ?? null,
    longitude: snapshot.longitude ?? bin?.longitude ?? request.longitude ?? null,
    fillPercentage,
    fullnessStatus: request.fullnessStatus || '',
    status: request.status || 'queued',
    requestedAt: request.requestedAt || request.createdAt || null,
    queueEnteredAt: request.queueEnteredAt || null,
    assignedCollectorId: objectIdString(request.assignedCollectorId || request.assignedCollector),
    assignedCollectorName:
      collectorDisplayName(assignedCollector) || request.assignedCollectorName || request.collectorName || '',
    claimedAt: request.claimedAt || null,
    startedAt: request.startedAt || null,
    completedAt: request.completedAt || null,
    remarks: request.remarks || request.notes || '',
    reason: request.reason || 'Manual partner organization request',
    createdAt: request.createdAt || null,
    updatedAt: request.updatedAt || null,
  };
}

function legacyRequestPayload(request = {}, { collector = null } = {}) {
  const location = request.location && typeof request.location === 'object'
    ? request.location.address
    : request.location;

  return {
    _id: request._id,
    id: objectIdString(request._id),
    residentName: request.residentName || '',
    location: location || '',
    wasteType: request.wasteType || '',
    itemCategory: request.itemCategory || '',
    detectedClass: request.detectedClass || '',
    quantity: request.quantity || 1,
    ratePerKg: request.ratePerKg || 0,
    ratePerItem: request.ratePerItem || 0,
    residentEmail: request.residentEmail || '',
    phone: request.phone || '',
    wasteImage: request.wasteImage || '',
    status: request.status || 'Pending',
    assignedCollector: collectorDisplayName(collector || {}) || request.assignedCollectorName || '',
    assignedCollectorId: objectIdString(request.assignedCollector),
    scheduledAt: request.scheduledAt || '',
    createdAt: request.createdAt || '',
    updatedAt: request.updatedAt || '',
    requestedAt: request.createdAt || request.requestedAt || '',
    startedAt: request.startedAt || '',
  };
}

async function enrichCollectionRequest(request) {
  const [partner, bin, collector] = await Promise.all([
    findReferencedDocument(partnerOrganizationsCollection(), request.partnerOrganizationId),
    findReferencedDocument(binsCollection(), request.binId),
    findReferencedDocument(collectorsCollection(), request.assignedCollectorId || request.assignedCollector),
  ]);
  return collectionRequestPayload(request, { partner, bin, collector });
}

async function enrichLegacyRequest(request) {
  const collector = await findReferencedDocument(collectorsCollection(), request.assignedCollector);
  return legacyRequestPayload(request, { collector });
}

function reportPayload(report = {}, { request = null, partner = null, bin = null, collector = null } = {}) {
  const binSnapshot = report.binSnapshot || {};
  const partnerSnapshot = report.partnerSnapshot || {};
  const requestSnapshot = report.requestSnapshot || {};

  return {
    _id: report._id,
    id: objectIdString(report._id),
    collectionRequestId: objectIdString(report.collectionRequestId || report.requestId),
    requestId: objectIdString(report.collectionRequestId || report.requestId),
    requestReference: report.requestReference || objectIdString(report.collectionRequestId || report.requestId || report._id),
    collectorId: objectIdString(report.collectorId),
    collectorName: collectorDisplayName(collector || {}) || report.collectorName || '',
    partnerOrganizationId: objectIdString(report.partnerOrganizationId),
    partnerOrganizationName:
      partner?.organizationName || partnerSnapshot.organizationName || report.partnerOrganizationName || '',
    binDatabaseId: objectIdString(report.binId),
    binId: binSnapshot.binCode || bin?.binCode || report.binId || '',
    binCode: binSnapshot.binCode || bin?.binCode || '',
    binName: binSnapshot.name || bin?.name || report.binName || '',
    location: binSnapshot.address || bin?.address || report.location || '',
    beforeEvidence: report.beforeEvidence || {},
    afterEvidence: report.afterEvidence || {},
    items: report.items || [],
    itemSummary: report.itemSummary || [],
    totalQuantity: report.totalQuantity || 0,
    optionalTotalWeight: report.optionalTotalWeight || { totalWeightKg: null, unit: 'kg' },
    remarks: report.remarks || {},
    submittedAt: report.submittedAt || report.createdAt || null,
    completedAt: requestSnapshot.completedAt || request?.completedAt || report.completedAt || report.submittedAt || null,
    collectionRequest: request ? collectionRequestPayload(request, { partner, bin, collector }) : null,
    createdAt: report.createdAt || null,
    updatedAt: report.updatedAt || null,
  };
}

async function enrichReport(report) {
  const [request, partner, bin, collector] = await Promise.all([
    findReferencedDocument(collectionRequestsCollection(), report.collectionRequestId || report.requestId),
    findReferencedDocument(partnerOrganizationsCollection(), report.partnerOrganizationId),
    findReferencedDocument(binsCollection(), report.binId),
    findReferencedDocument(collectorsCollection(), report.collectorId),
  ]);
  return reportPayload(report, { request, partner, bin, collector });
}

function completedRequestHistoryPayload(request, source, collector) {
  const payload = source === 'legacy'
    ? legacyRequestPayload(request, { collector })
    : collectionRequestPayload(request, { collector });
  return {
    _id: request._id,
    id: objectIdString(request._id),
    collectionRequestId: objectIdString(request._id),
    requestId: objectIdString(request._id),
    requestReference: payload.requestCode || `CR-${objectIdString(request._id).slice(-6)}`,
    collectorId: objectIdString(collector?._id || request.assignedCollectorId || request.assignedCollector),
    collectorName: collectorDisplayName(collector || {}) || payload.assignedCollectorName || payload.assignedCollector || '',
    partnerOrganizationId: payload.partnerOrganizationId || '',
    partnerOrganizationName: payload.partnerOrganizationName || '',
    binId: payload.binId || payload.binCode || '',
    binCode: payload.binCode || '',
    binName: payload.binName || payload.name || payload.itemCategory || payload.wasteType || '',
    location: payload.location || '',
    items: [],
    itemSummary: [],
    totalQuantity: payload.quantity || 0,
    optionalTotalWeight: { totalWeightKg: null, unit: 'kg' },
    remarks: {
      finalBinStatus: source === 'legacy' ? 'Completed' : 'Completed',
      finalRemarks: payload.remarks || '',
    },
    submittedAt: request.completedAt || request.updatedAt || request.createdAt || null,
    completedAt: request.completedAt || request.updatedAt || null,
    createdAt: request.createdAt || null,
    updatedAt: request.updatedAt || null,
  };
}

function publicBinFromDocument(doc) {
  const location = doc.location && typeof doc.location === 'object' ? doc.location : {};
  const coordinates = Array.isArray(doc.coordinates)
    ? doc.coordinates
    : Array.isArray(location.coordinates)
      ? location.coordinates
      : [];
  const latitude = readDouble(doc.latitude, doc.lat, location.latitude, location.lat, coordinates[1]);
  const longitude = readDouble(doc.longitude, doc.lng, doc.lon, location.longitude, location.lng, location.lon, coordinates[0]);
  const publicQrCode = String(
    doc.publicQrCode || doc.publicQRCode || doc.publicCode || doc.binCode || doc.qrCode || doc.code || '',
  ).trim();
  const name = String(doc.name || doc.binName || doc.displayName || doc.label || publicQrCode || 'RecyTech Bin').trim();
  const address = String(doc.address || location.address || doc.locationAddress || doc.locationName || '').trim();
  const building = String(doc.building || doc.buildingName || location.building || '').trim();
  const locationDescription = String(
    doc.locationDescription || doc.description || location.description || (typeof doc.location === 'string' ? doc.location : ''),
  ).trim();
  const partnerName = String(
    doc.partnerOrganizationName ||
      doc.partnerName ||
      doc.organizationName ||
      readNested(doc, 'partnerOrganization.name') ||
      readNested(doc, 'organization.name') ||
      '',
  ).trim();
  const status = String(doc.publicStatus || doc.availability || doc.status || '').trim();
  const activeValue = doc.isActive ?? doc.active ?? doc.enabled;
  const active =
    activeValue === undefined
      ? !['inactive', 'disabled', 'decommissioned', 'archived', 'private'].includes(status.toLowerCase())
      : Boolean(activeValue);

  if (!publicQrCode && !doc.publicVisible && !doc.dropOffEnabled && !doc.designatedForDropOff) return null;
  if (!active) return null;

  return {
    id: String(doc._id || doc.id || doc.binId || publicQrCode),
    publicQrCode,
    publicCode: publicQrCode,
    name,
    address: address || locationDescription || building,
    latitude,
    longitude,
    publicStatus: status || 'Active',
    availability: status || 'Active',
    ...(building ? { building } : {}),
    ...(locationDescription ? { locationDescription } : {}),
    ...(doc.accessInfo ? { accessInfo: String(doc.accessInfo) } : {}),
    ...(partnerName ? { partnerOrganizationName: partnerName } : {}),
    isActive: true,
  };
}

async function findPublicBins() {
  const collectionNames = (process.env.PUBLIC_BINS_COLLECTIONS || 'publicBins,bins,smartBins,recytechBins')
    .split(',')
    .map((name) => name.trim())
    .filter(Boolean);
  const projection = {
    password: 0,
    passwordHash: 0,
    deviceSecret: 0,
    apiKey: 0,
    sensorCredentials: 0,
    controllerCredentials: 0,
    adminNotes: 0,
    privateNotes: 0,
  };

  for (const collectionName of collectionNames) {
    const docs = await database()
      .collection(collectionName)
      .find(
        {
          $or: [
            { publicVisible: true },
            { dropOffEnabled: true },
            { designatedForDropOff: true },
            { publicQrCode: { $exists: true, $ne: '' } },
            { publicCode: { $exists: true, $ne: '' } },
          ],
        },
        { projection },
      )
      .limit(100)
      .toArray();

    const bins = docs.map(publicBinFromDocument).filter(Boolean);
    if (bins.length > 0) return bins;
  }

  return [];
}

app.use('/api/iot', createIotRouter({ database }));

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
    const fullName = String(req.body.fullName || `${firstName} ${lastName}`).trim();
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');
    const role = normalizeRegistrationRole(req.body.role);
    const organizationName = String(req.body.organizationName || '').trim();
    const contactPerson = String(req.body.contactPerson || fullName).trim();
    const contactNumber = String(req.body.contactNumber || req.body.phone || '').trim();
    const vehicleType = String(req.body.vehicleType || 'Not Assigned').trim();
    const plateNumber = String(req.body.plateNumber || req.body.vehiclePlate || 'Not Assigned').trim();

    if (!firstName || !lastName) return res.status(400).json({ message: 'First name and last name are required.' });
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({ message: 'Enter a valid email address.' });
    }
    if (password.length < 8) return res.status(400).json({ message: 'Password must be at least 8 characters.' });
    if (!role) {
      return res.status(400).json({
        message: 'Unsupported account type.',
      });
    }
    if (role === 'partner_org' && !organizationName) {
      return res.status(400).json({ message: 'Organization name is required.' });
    }
    if (role === 'collector' && !contactNumber) {
      return res.status(400).json({ message: 'Contact number is required.' });
    }

    const users = usersCollection();
    await users.createIndex({ email: 1 }, { unique: true });
    const existing = await users.findOne({ email });
    const existingPartnerAccount = await legacyPartnerAccountsCollection().findOne({ email }, { projection: { _id: 1 } });
    if (existing || existingPartnerAccount) {
      return res.status(409).json({ message: 'An account with this email already exists.' });
    }

    const now = new Date();
    const accountStatus = ACCOUNT_STATUSES.active;
    const user = {
      firstName,
      lastName,
      fullName,
      email,
      role,
      passwordHash: hashPassword(password),
      status: legacyStatusFor(accountStatus),
      accountStatus,
      emailVerified: true,
      emailVerifiedAt: now,
      ...(role === 'partner_org'
        ? {
            organizationName,
            contactPerson,
            contactNumber,
          }
        : {}),
      ...(role === 'collector'
        ? {
            phone: contactNumber,
            contactNumber,
            vehicleType,
            plateNumber,
          }
        : {}),
      createdAt: now,
      updatedAt: now,
    };

    const result = await users.insertOne(user);
    const createdUser = { ...user, _id: result.insertedId };
    if (role === 'partner_org') {
      await mirrorPartnerOrganizationProfile(createdUser, {
        organizationName,
        contactPerson,
        contactNumber,
        now,
      });
    }

    return res.status(201).json({
      message: 'Registration successful. You may now log in.',
      email,
      role,
      accountStatus,
      status: legacyStatusFor(accountStatus),
      emailVerificationRequired: false,
      emailSent: false,
      user: publicUser(createdUser),
    });
  } catch (error) {
    if (error && error.code === 11000) {
      return res.status(409).json({ message: 'An account with this email already exists.' });
    }
    next(error);
  }
});

app.post('/api/auth/verify-email', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    const pin = String(req.body.pin || req.body.otp || '').trim();
    if (!email || !/^\d{6}$/.test(pin)) return res.status(400).json({ message: 'Email and 6-digit PIN are required.' });

    const users = usersCollection();
    const user = await users.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Account not found.' });
    if (isEmailVerified(user)) return res.json({ message: 'Email is already verified.', user: publicUser(user) });

    const validation = assertValidPinState(user, 'emailVerification', pin, 'email_verification');
    if (!validation.ok) {
      await users.updateOne({ _id: user._id }, { $inc: { 'emailVerification.attempts': 1 } });
      return res.status(validation.status).json({ message: validation.message });
    }

    const now = new Date();
    await users.updateOne(
      { _id: user._id },
      {
        $set: { emailVerified: true, emailVerifiedAt: now, updatedAt: now },
        $unset: { emailVerification: '' },
      },
    );
    const updated = await users.findOne({ _id: user._id });
    return res.json({ message: 'Email verified successfully. You can now log in.', user: publicUser(updated) });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/resend-verification', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    if (!email) return res.status(400).json({ message: 'Email is required.' });

    const users = usersCollection();
    const user = await users.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Account not found.' });
    if (isEmailVerified(user)) return res.json({ message: 'Email is already verified.', emailVerificationRequired: false, email });

    const current = user.emailVerification;
    if (current?.resendAvailableAt && new Date(current.resendAvailableAt).getTime() > Date.now()) {
      return res.status(429).json({ message: 'Please wait before requesting another verification PIN.' });
    }

    const { pin, state } = createPinState(email, 'email_verification');
    await users.updateOne({ _id: user._id }, { $set: { emailVerification: state, updatedAt: new Date() } });
    const sent = await sendPinEmail({ to: email, pin, purpose: 'email_verification' });
    return emailPinResponse(res, 200, {
      message: sent ? 'A new verification PIN has been sent.' : 'Email service is not configured, so the verification PIN could not be sent.',
      email,
      sent,
      pin,
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');
    if (!email || !password) return res.status(400).json({ message: 'Email and password are required.' });

    const users = usersCollection();
    const user = await users.findOne({ email });
    if (user) {
      const passwordVerification = await verifyLoginPassword(password, user);
      if (!passwordVerification.ok) {
        return res.status(401).json({ message: 'Invalid email or password.' });
      }

      const issueCheck = canIssueAuth(user);
      if (!issueCheck.ok) {
        return res.status(issueCheck.status).json({
          code: issueCheck.code,
          message: issueCheck.message,
          accountStatus: accountStatusFor(user),
        });
      }

      if (passwordVerification.legacyBcrypt) {
        await users.updateOne(
          { _id: user._id },
          {
            $set: { passwordHash: hashPassword(password), updatedAt: new Date() },
            $unset: { password: '' },
          },
        );
      }

      return authResponse(user, 200, res);
    }

    const partnerAccount = await legacyPartnerAccountsCollection().findOne({ email });
    const partnerPasswordVerification = partnerAccount
      ? await verifyLoginPassword(password, partnerAccount)
      : { ok: false };
    if (!partnerAccount || !partnerPasswordVerification.ok) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    const issueCheck = canIssueAuth(partnerAccount);
    if (!issueCheck.ok) {
      return res.status(issueCheck.status).json({
        code: issueCheck.code,
        message: issueCheck.message,
        accountStatus: accountStatusFor(partnerAccount),
      });
    }

    return authResponse(partnerAccount, 200, res, {
      source: 'lguaccounts',
      userMapper: publicPartnerAccount,
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/auth/me', async (req, res, next) => {
  try {
    const claims = verifyToken(bearerToken(req));
    if (!claims?.sub) return res.status(401).json({ message: 'Not authorized.' });

    const accountId = objectIdFrom(claims.sub);
    if (!accountId) return res.status(401).json({ message: 'Not authorized.' });
    const isLegacyPartnerToken = claims.source === 'lguaccounts';
    const user = isLegacyPartnerToken
      ? await legacyPartnerAccountsCollection().findOne({ _id: accountId })
      : await usersCollection().findOne({ _id: accountId });
    if (!user) return res.status(401).json({ message: 'Not authorized.' });

    const issueCheck = canIssueAuth(user);
    if (!issueCheck.ok) {
      return res.status(issueCheck.status).json({
        code: issueCheck.code,
        message: issueCheck.message,
        accountStatus: accountStatusFor(user),
      });
    }

    return res.json({ user: isLegacyPartnerToken ? publicPartnerAccount(user) : publicUser(user) });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/logout', (_req, res) => {
  res.json({ message: 'Logged out successfully.' });
});

app.post('/api/auth/forgot-password', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    if (!email) return res.status(400).json({ message: 'Email is required.' });

    const users = usersCollection();
    const user = await users.findOne({ email });
    const genericMessage = 'If the email exists, a PIN has been sent.';
    if (!user) return res.json({ message: genericMessage });

    const current = user.passwordReset;
    if (current?.resendAvailableAt && new Date(current.resendAvailableAt).getTime() > Date.now()) {
      return res.status(429).json({ message: 'Please wait before requesting another reset PIN.' });
    }

    const { pin, state } = createPinState(email, 'password_reset');
    await users.updateOne({ _id: user._id }, { $set: { passwordReset: state, updatedAt: new Date() } });
    await sendPinEmail({ to: email, pin, purpose: 'password_reset' });
    const payload = { message: genericMessage };
    if (allowDevOtpResponse) payload.devOtp = pin;
    return res.json(payload);
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/verify-pin', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    const pin = String(req.body.pin || '').trim();
    if (!email || !/^\d{6}$/.test(pin)) return res.status(400).json({ message: 'Email and 6-digit PIN are required.' });

    const users = usersCollection();
    const user = await users.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid verification PIN.' });

    const validation = assertValidPinState(user, 'passwordReset', pin, 'password_reset');
    if (!validation.ok) {
      await users.updateOne({ _id: user._id }, { $inc: { 'passwordReset.attempts': 1 } });
      return res.status(validation.status).json({ message: validation.message });
    }

    return res.json({
      message: 'PIN verified. You can now reset your password.',
      resetToken: signToken(user, { purpose: 'password_reset', expiresInSeconds: 15 * 60 }),
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/reset-password', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    const newPassword = String(req.body.newPassword || '');
    const confirmPassword = String(req.body.confirmPassword || '');
    const resetToken = String(req.body.resetToken || '');
    if (!email || !resetToken) return res.status(400).json({ message: 'Email and reset token are required.' });
    if (newPassword.length < 8) return res.status(400).json({ message: 'Password must be at least 8 characters.' });
    if (newPassword !== confirmPassword) return res.status(400).json({ message: 'Passwords do not match.' });

    const claims = verifyToken(resetToken, 'password_reset');
    if (!claims || normalizeEmail(claims.email) !== email) {
      return res.status(401).json({ message: 'Reset token is invalid or expired.' });
    }

    const result = await usersCollection().updateOne(
      { email },
      {
        $set: { passwordHash: hashPassword(newPassword), updatedAt: new Date() },
        $unset: { passwordReset: '' },
      },
    );
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Account not found.' });
    return res.json({ message: 'Password has been reset successfully.' });
  } catch (error) {
    next(error);
  }
});

app.get('/api/collector/current-job', async (req, res, next) => {
  try {
    const auth = await authenticatedCollector(req, res);
    if (!auth) return;

    const assignedToCollector = assignmentClauses(auth.user, auth.collector);
    const activeStatus = { status: { $in: ACTIVE_COLLECTOR_JOB_STATUSES } };
    const query = { $and: [{ $or: assignedToCollector }, activeStatus] };

    const [collectionRequests, legacyRequests] = await Promise.all([
      collectionRequestsCollection()
        .find(query)
        .sort({ startedAt: -1, claimedAt: -1, queueEnteredAt: 1, requestedAt: 1, createdAt: 1 })
        .limit(10)
        .toArray(),
      legacyRequestsCollection()
        .find(query)
        .sort({ scheduledAt: 1, updatedAt: -1, createdAt: 1 })
        .limit(10)
        .toArray(),
    ]);

    const jobs = [
      ...(await Promise.all(collectionRequests.map(enrichCollectionRequest))).map((job) => ({
        job,
        date: newestDate(job.startedAt, job.updatedAt, job.requestedAt, job.createdAt),
      })),
      ...(await Promise.all(legacyRequests.map(enrichLegacyRequest))).map((job) => ({
        job,
        date: newestDate(job.startedAt, job.updatedAt, job.scheduledAt, job.createdAt),
      })),
    ].sort((a, b) => {
      const statusOrder = normalizeStatusForSort(a.job.status) - normalizeStatusForSort(b.job.status);
      if (statusOrder !== 0) return statusOrder;
      return b.date - a.date;
    });

    const currentJob = jobs[0]?.job || null;
    return res.json({
      currentJob,
      job: currentJob,
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/collector/history', async (req, res, next) => {
  try {
    const auth = await authenticatedCollector(req, res);
    if (!auth) return;

    const assignedToCollector = assignmentClauses(auth.user, auth.collector);
    const completedStatus = { status: { $in: COMPLETED_COLLECTION_STATUSES } };
    const completedQuery = { $and: [{ $or: assignedToCollector }, completedStatus] };

    const [reports, completedCollectionRequests, completedLegacyRequests] = await Promise.all([
      collectorReportsCollection()
        .find({ $or: assignedToCollector })
        .sort({ submittedAt: -1, createdAt: -1 })
        .limit(100)
        .toArray(),
      collectionRequestsCollection()
        .find(completedQuery)
        .sort({ completedAt: -1, updatedAt: -1, createdAt: -1 })
        .limit(100)
        .toArray(),
      legacyRequestsCollection()
        .find(completedQuery)
        .sort({ completedAt: -1, updatedAt: -1, createdAt: -1 })
        .limit(100)
        .toArray(),
    ]);

    const history = await Promise.all(reports.map(enrichReport));
    const reportedRequestIds = new Set(
      history.map((report) => report.collectionRequestId || report.requestId).filter(Boolean),
    );

    const fallbackCollectionHistory = completedCollectionRequests
      .filter((request) => !reportedRequestIds.has(objectIdString(request._id)))
      .map((request) => completedRequestHistoryPayload(request, 'collection', auth.collector));
    const fallbackLegacyHistory = completedLegacyRequests
      .filter((request) => !reportedRequestIds.has(objectIdString(request._id)))
      .map((request) => completedRequestHistoryPayload(request, 'legacy', auth.collector));

    const combinedHistory = [
      ...history,
      ...fallbackCollectionHistory,
      ...fallbackLegacyHistory,
    ].sort((a, b) => newestDate(b.completedAt, b.submittedAt, b.updatedAt) - newestDate(a.completedAt, a.submittedAt, a.updatedAt));

    return res.json({
      history: combinedHistory,
      reports: combinedHistory,
      data: combinedHistory,
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/household/drop-offs/validate-bin-qr', async (req, res, next) => {
  try {
    const user = await authenticatedHousehold(req, res);
    if (!user) return;

    const raw = String(req.body.qrCode || req.body.publicQrCode || req.body.publicBinCode || '').trim();
    let code = raw;
    try {
      const url = new URL(raw);
      const parts = url.pathname.split('/').filter(Boolean);
      if (url.protocol !== 'recytech:' || url.hostname.toLowerCase() !== 'bin' || parts.length !== 1) {
        return res.status(400).json({ code: 'malformed_qr', message: 'Invalid RecyTech bin QR.' });
      }
      [code] = parts;
    } catch (_) {
      code = raw;
    }
    code = String(code || '').trim().toUpperCase();
    if (!/^[A-Z0-9_-]{3,64}$/.test(code)) {
      return res.status(400).json({ code: 'malformed_qr', message: 'Invalid RecyTech bin QR.' });
    }

    const bin = await findHouseholdBin(code);
    if (!bin) return res.status(404).json({ code: 'unknown_bin', message: 'Bin unavailable. This bin was not found.' });
    if (bin.active === false || bin.isActive === false || bin.publicVisible === false) {
      return res.status(400).json({ code: 'inactive_bin', message: 'Bin unavailable. This designated bin is temporarily unavailable.' });
    }
    const partner = await findReferencedDocument(partnerOrganizationsCollection(), bin.partnerOrganizationId);
    if (!partner) {
      return res.status(400).json({ code: 'invalid_partner', message: 'Bin unavailable. No valid Partner Organization is assigned.' });
    }
    return res.json({ bin: await householdBinPayload(bin) });
  } catch (error) {
    next(error);
  }
});

app.post('/api/household/drop-offs', async (req, res, next) => {
  try {
    const user = await authenticatedHousehold(req, res);
    if (!user) return;

    const bin = await findHouseholdBin(req.body.binId || req.body.binCode || req.body.publicQrCode);
    if (!bin) return res.status(404).json({ code: 'unknown_bin', message: 'Bin unavailable. This bin was not found.' });
    if (bin.active === false || bin.isActive === false || bin.publicVisible === false) {
      return res.status(400).json({ code: 'inactive_bin', message: 'Bin unavailable. This designated bin is temporarily unavailable.' });
    }
    const partner = await findReferencedDocument(partnerOrganizationsCollection(), bin.partnerOrganizationId);
    if (!partner) {
      return res.status(400).json({ code: 'invalid_partner', message: 'Bin unavailable. No valid Partner Organization is assigned.' });
    }

    const submittedItems = Array.isArray(req.body.items) ? req.body.items : [];
    if (submittedItems.length === 0) {
      return res.status(400).json({ code: 'missing_items', message: 'Please add at least one e-waste item.' });
    }
    const accepted = new Set((Array.isArray(bin.acceptedCategories) ? bin.acceptedCategories : []).map(normalizeCategoryKey));
    const items = [];
    for (const item of submittedItems) {
      const category = normalizeCategoryKey(item?.category);
      const quantity = Number(item?.quantity);
      if (!category) return res.status(400).json({ code: 'missing_category', message: 'Please select an e-waste category.' });
      if (!Number.isInteger(quantity) || quantity <= 0 || quantity > 100) {
        return res.status(400).json({ code: 'invalid_quantity', message: 'Quantity must be a whole number from 1 to 100.' });
      }
      if (!accepted.has(category)) {
        return res.status(400).json({ code: 'category_not_accepted', message: 'This e-waste category is not accepted by this bin.' });
      }
      items.push({ category, quantity });
    }

    const scope = householdAccountScope(user);
    const idempotencyKey = String(req.body.idempotencyKey || '').trim() || null;
    if (idempotencyKey) {
      const existing = await householdDropOffsCollection().findOne({ ...scope, idempotencyKey });
      if (existing) {
        return res.json({ dropOff: await householdDropOffPayload(existing), idempotentReplay: true });
      }
    }

    const now = new Date();
    const document = {
      ...scope,
      binId: bin._id,
      partnerOrganizationId: partner._id,
      submissionMethod: String(req.body.submissionMethod || '').trim().toLowerCase() === 'qr' ? 'qr' : 'manual',
      items,
      idempotencyKey,
      submittedAt: now,
      status: 'submitted',
      pointsStatus: 'not_processed',
      pointsAwarded: 0,
      createdAt: now,
      updatedAt: now,
    };
    const result = await householdDropOffsCollection().insertOne(document);
    const created = { ...document, _id: result.insertedId };
    const pointsAwarded = await awardHouseholdDropOffPoints(created);
    created.pointsStatus = pointsAwarded > 0 ? 'credited' : 'failed';
    created.pointsAwarded = pointsAwarded;
    return res.status(201).json({ dropOff: await householdDropOffPayload(created) });
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(409).json({ code: 'duplicate_drop_off', message: 'Drop-off already submitted.' });
    }
    next(error);
  }
});

app.get('/api/household/drop-offs', async (req, res, next) => {
  try {
    const user = await authenticatedHousehold(req, res);
    if (!user) return;
    const records = await householdDropOffsCollection()
      .find(householdAccountScope(user))
      .sort({ submittedAt: -1, createdAt: -1 })
      .limit(200)
      .toArray();
    const payload = await Promise.all(records.map(householdDropOffPayload));
    return res.json({ dropOffs: payload });
  } catch (error) {
    next(error);
  }
});

app.get('/api/household/points', async (req, res, next) => {
  try {
    const user = await authenticatedHousehold(req, res);
    if (!user) return;

    const scope = householdAccountScope(user);
    const account = await householdPointsAccountsCollection().findOneAndUpdate(
      scope,
      { $setOnInsert: { ...scope, balance: 0, createdAt: new Date(), updatedAt: new Date() } },
      { upsert: true, returnDocument: 'after' },
    );
    const transactions = await pointsTransactionsCollection()
      .find(scope)
      .sort({ createdAt: -1 })
      .limit(50)
      .toArray();
    const balance = Number.isFinite(Number(account?.balance)) ? Number(account.balance) : 0;

    return res.json({
      points: balance,
      balance,
      history: transactions.map(pointsTransactionPayload),
      transactions: transactions.map(pointsTransactionPayload),
      account: {
        householdUserId: objectIdString(scope.householdUserId),
        householdAccountModel: scope.householdAccountModel,
        balance,
        updatedAt: account?.updatedAt || null,
      },
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/household/rewards', async (req, res, next) => {
  try {
    const user = await authenticatedHousehold(req, res);
    if (!user) return;

    const scope = householdAccountScope(user);
    const [account, rewards] = await Promise.all([
      householdPointsAccountsCollection().findOne(scope),
      partnerRewardsCollection()
        .find({ active: true })
        .sort({ pointsCost: 1, title: 1 })
        .toArray(),
    ]);
    const balance = Number.isFinite(Number(account?.balance)) ? Number(account.balance) : 0;
    const payload = await Promise.all(rewards.map(async (reward) => {
      const [partner, bins] = await Promise.all([
        findReferencedDocument(partnerOrganizationsCollection(), reward.partnerOrganizationId),
        Array.isArray(reward.applicableBinIds) && reward.applicableBinIds.length
          ? binsCollection().find({ _id: { $in: reward.applicableBinIds } }).toArray()
          : Promise.resolve([]),
      ]);
      return householdRewardPayload(reward, { partner, bins, balance });
    }));

    return res.json({ balance, rewards: payload });
  } catch (error) {
    next(error);
  }
});

app.get('/api/household/reward-redemptions', async (req, res, next) => {
  try {
    const user = await authenticatedHousehold(req, res);
    if (!user) return;

    const redemptions = await rewardRedemptionsCollection()
      .find(householdAccountScope(user))
      .sort({ redeemedAt: -1, createdAt: -1 })
      .toArray();
    const payload = await Promise.all(redemptions.map(async (redemption) => {
      const partner = await findReferencedDocument(
        partnerOrganizationsCollection(),
        redemption.partnerOrganizationId,
      );
      return householdRedemptionPayload(redemption, { partner });
    }));

    return res.json({ history: payload, redemptions: payload });
  } catch (error) {
    next(error);
  }
});

app.get('/api/partner/bins', async (req, res, next) => {
  try {
    const auth = await authenticatedPartner(req, res);
    if (!auth) return;

    const bins = await partnerBins(auth);
    if (bins.length === 0) {
      return res.json({ bins: [], data: [] });
    }

    const binReferences = bins.flatMap((bin) => [bin._id, objectIdString(bin._id), bin.binCode].filter(Boolean));
    const activeRequests = await collectionRequestsCollection()
      .find({
        binId: { $in: binReferences },
        status: { $in: ACTIVE_PARTNER_REQUEST_STATUSES },
      })
      .toArray();
    const activeByBin = new Map();
    for (const request of activeRequests) {
      activeByBin.set(objectIdString(request.binId), request);
      if (request.binSnapshot?.binCode) activeByBin.set(String(request.binSnapshot.binCode), request);
    }

    const payload = await Promise.all(bins.map(async (bin) => {
      const active = activeByBin.get(objectIdString(bin._id)) || activeByBin.get(String(bin.binCode || ''));
      return partnerBinPayload(
        bin,
        active ? await enrichCollectionRequest(active) : null,
        auth.partner,
      );
    }));
    return res.json({ bins: payload, data: payload });
  } catch (error) {
    next(error);
  }
});

app.get('/api/partner/bins/:idOrCode', async (req, res, next) => {
  try {
    const auth = await authenticatedPartner(req, res);
    if (!auth) return;

    const idOrCode = String(req.params.idOrCode || '').trim();
    const identifiers = [idOrCode];
    const objectId = objectIdFrom(idOrCode);
    if (objectId) identifiers.push(objectId);
    const bin = await binsCollection().findOne({
      $and: [
        { $or: partnerOwnershipClauses(auth) },
        {
          $or: [
            { _id: { $in: identifiers } },
            { binCode: idOrCode },
            { binId: idOrCode },
            { code: idOrCode },
          ],
        },
      ],
    });
    if (!bin) return res.status(404).json({ message: 'Partner smart bin not found.' });

    const active = await collectionRequestsCollection().findOne({
      binId: { $in: [bin._id, objectIdString(bin._id), bin.binCode].filter(Boolean) },
      status: { $in: ACTIVE_PARTNER_REQUEST_STATUSES },
    });
    const payload = partnerBinPayload(
      bin,
      active ? await enrichCollectionRequest(active) : null,
      auth.partner,
    );
    return res.json({ bin: payload, data: payload });
  } catch (error) {
    next(error);
  }
});

app.get('/api/partner/collection-requests', async (req, res, next) => {
  try {
    const auth = await authenticatedPartner(req, res);
    if (!auth) return;

    const requests = await collectionRequestsForPartner(auth);
    if (requests.length === 0) {
      return res.json({ requests: [], data: [] });
    }

    const reports = await collectorReportsCollection()
      .find({ collectionRequestId: { $in: requests.flatMap((request) => [request._id, objectIdString(request._id)]) } })
      .toArray();
    const reportsByRequest = new Map(
      reports.map((report) => [objectIdString(report.collectionRequestId || report.requestId), report]),
    );
    const payload = await Promise.all(requests.map(async (request) => {
      const item = await enrichCollectionRequest(request);
      const report = reportsByRequest.get(objectIdString(request._id));
      return {
        ...item,
        completionReport: report ? await enrichReport(report) : null,
      };
    }));
    return res.json({ requests: payload, data: payload });
  } catch (error) {
    next(error);
  }
});

app.post('/api/partner/collection-requests', async (req, res, next) => {
  try {
    const auth = await authenticatedPartner(req, res);
    if (!auth) return;

    const binId = String(req.body.binId || '').trim();
    if (!binId) return res.status(400).json({ message: 'binId is required.' });

    const identifiers = [binId];
    const objectId = objectIdFrom(binId);
    if (objectId) identifiers.push(objectId);
    const bin = await binsCollection().findOne({
      $and: [
        { $or: partnerOwnershipClauses(auth) },
        {
          $or: [
            { _id: { $in: identifiers } },
            { binCode: binId },
            { binId },
            { code: binId },
          ],
        },
      ],
    });
    if (!bin) return res.status(404).json({ message: 'Partner smart bin not found.' });
    if (bin.active === false || bin.isActive === false) {
      return res.status(400).json({ message: 'Inactive bins cannot request collection.' });
    }

    const binReferences = [bin._id, objectIdString(bin._id), bin.binCode].filter(Boolean);
    const existing = await collectionRequestsCollection().findOne({
      binId: { $in: binReferences },
      status: { $in: ACTIVE_PARTNER_REQUEST_STATUSES },
    });
    if (existing) {
      return res.status(409).json({
        message: 'A collection request for this bin is already active.',
        request: await enrichCollectionRequest(existing),
      });
    }

    const now = new Date();
    const binPayload = partnerBinPayload(bin, null, auth.partner);
    const document = {
      partnerOrganizationId: auth.partner?._id || auth.user._id,
      partnerOrganizationName: auth.partner?.organizationName || auth.user.organizationName || auth.user.name || '',
      binId: bin._id,
      requestedAt: now,
      queueEnteredAt: now,
      status: 'queued',
      remarks: String(req.body.remarks || '').trim(),
      reason: 'Manual partner organization request',
      fullnessStatus: binPayload.fullnessStatus,
      binSnapshot: {
        binCode: binPayload.binCode,
        name: binPayload.name,
        address: binPayload.address,
        latitude: binPayload.latitude,
        longitude: binPayload.longitude,
        latestFillPercentage: binPayload.fillPercentage,
      },
      createdAt: now,
      updatedAt: now,
    };
    const result = await collectionRequestsCollection().insertOne(document);
    const created = { ...document, _id: result.insertedId };
    return res.status(201).json({ request: await enrichCollectionRequest(created) });
  } catch (error) {
    next(error);
  }
});

app.get('/api/bins/public', async (_req, res, next) => {
  try {
    const bins = await findPublicBins();
    res.json({ bins, data: bins });
  } catch (error) {
    next(error);
  }
});

app.get('/api/public/bins', async (_req, res, next) => {
  try {
    const bins = await findPublicBins();
    res.json({ bins, data: bins });
  } catch (error) {
    next(error);
  }
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
  await ensureIotIndexes({ database });
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
