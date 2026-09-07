const crypto = require('crypto');
const path = require('path');
const { MongoClient, ObjectId, ServerApiVersion } = require('mongodb');

require('dotenv').config({ path: path.join(__dirname, '.env') });

const DEMO_BATCH = 'recytech-defense-demo';
const DEMO_TAG = Object.freeze({ isDemo: true, demoBatch: DEMO_BATCH });
const DRY_RUN = process.argv.includes('--dry-run');

const PREFERRED_ACCOUNTS = Object.freeze({
  partner: process.env.DEMO_PARTNER_EMAIL || 'nu@recytech.com',
  collector: process.env.DEMO_COLLECTOR_EMAIL || 'driver1@recytech.com',
  household: process.env.DEMO_HOUSEHOLD_EMAIL || 'jdoe@gmail.com',
});

const DEMO_IDS = Object.freeze({
  partnerProfile: deterministicObjectId('partner-profile'),
  dropOff: deterministicObjectId('household-drop-off'),
  activeRequest: deterministicObjectId('active-collection-request'),
  completedRequest: deterministicObjectId('completed-collection-request'),
});

function deterministicObjectId(key) {
  const hex = crypto.createHash('sha256').update(`${DEMO_BATCH}:${key}`).digest('hex').slice(0, 24);
  return new ObjectId(hex);
}

function normalize(value) {
  return String(value || '').trim().toLowerCase();
}

function isActiveAccount(account = {}) {
  return !['inactive', 'disabled', 'rejected'].includes(
    normalize(account.accountStatus || account.status),
  );
}

function isCollectorRole(role) {
  return normalize(role).replace(/[\s-]+/g, '_') === 'collector';
}

function isHouseholdRole(role) {
  return ['staff', 'household', 'resident', 'registered_user', 'regular_user', 'user'].includes(
    normalize(role).replace(/[\s-]+/g, '_'),
  );
}

function displayName(account = {}) {
  return String(
    account.fullName ||
      [account.firstName, account.lastName].filter(Boolean).join(' ') ||
      account.name ||
      '',
  ).trim();
}

function isOwnedDemo(document) {
  return document?.isDemo === true && document?.demoBatch === DEMO_BATCH;
}

function assertOwnedDemoOrAbsent(document, label) {
  if (document && !isOwnedDemo(document)) {
    throw new Error(
      `${label} uses a deterministic demo identifier that is already owned by an untagged record. No changes were made to that record.`,
    );
  }
}

function assertValidDemoBin(bin) {
  if (!bin) {
    throw new Error(
      'DEMO-BIN-001 was not found. The seeder will not invent replacement coordinates or create a duplicate bin.',
    );
  }
  if (bin.isDemo !== true) {
    throw new Error(
      'DEMO-BIN-001 exists but is not marked isDemo: true. Refusing to overwrite a potentially operational bin.',
    );
  }
  const coordinates = bin.location?.coordinates;
  if (
    bin.location?.type !== 'Point' ||
    !Array.isArray(coordinates) ||
    coordinates.length < 2 ||
    !coordinates.slice(0, 2).every(Number.isFinite)
  ) {
    throw new Error(
      'DEMO-BIN-001 does not contain valid GeoJSON Point coordinates. Refusing to guess a location.',
    );
  }
}

async function findAccountByEmail(collection, email) {
  const accounts = await collection
    .find({}, { projection: { password: 0, passwordHash: 0 } })
    .toArray();
  return accounts.find((account) => normalize(account.email) === normalize(email)) || null;
}

async function resolveAccounts(db) {
  const partner = await findAccountByEmail(
    db.collection('lguaccounts'),
    PREFERRED_ACCOUNTS.partner,
  );
  if (!partner || !isActiveAccount(partner)) {
    throw new Error(
      `No active existing Partner Organization account matched DEMO_PARTNER_EMAIL (${PREFERRED_ACCOUNTS.partner}).`,
    );
  }

  const collectorUser = await findAccountByEmail(
    db.collection('users'),
    PREFERRED_ACCOUNTS.collector,
  );
  if (!collectorUser || !isCollectorRole(collectorUser.role) || !isActiveAccount(collectorUser)) {
    throw new Error(
      `No active existing Collector user matched DEMO_COLLECTOR_EMAIL (${PREFERRED_ACCOUNTS.collector}).`,
    );
  }
  const collectorUserIds = [collectorUser._id, collectorUser._id.toString()];
  const collector = await db.collection('collectors').findOne({
    $or: [
      { user: { $in: collectorUserIds } },
      { email: normalize(collectorUser.email) },
    ],
  });
  if (!collector || !isActiveAccount(collector)) {
    throw new Error('The selected Collector user has no active Collector profile.');
  }

  const household = await findAccountByEmail(
    db.collection('users'),
    PREFERRED_ACCOUNTS.household,
  );
  if (!household || !isHouseholdRole(household.role) || !isActiveAccount(household)) {
    throw new Error(
      `No active existing Registered User matched DEMO_HOUSEHOLD_EMAIL (${PREFERRED_ACCOUNTS.household}).`,
    );
  }

  return { partner, collectorUser, collector, household };
}

async function findDemoBin(db) {
  const bins = await db.collection('bins').find({
    $or: [
      { binCode: 'DEMO-BIN-001' },
      { publicQrCode: 'RECYTECH-DEMO-BIN-001' },
    ],
  }).toArray();
  if (bins.length > 1) {
    throw new Error(
      'Multiple records match the demo bin code/QR. Refusing to choose one or create another.',
    );
  }
  return bins[0] || null;
}

async function resolvePartnerProfile(db, partnerAccount, now) {
  const collection = db.collection('partnerorganizations');
  const accountIds = [partnerAccount._id, partnerAccount._id.toString()];
  const candidates = await collection.find({
    $or: [
      { user: { $in: accountIds } },
      { organizationName: partnerAccount.name },
    ],
  }).toArray();

  if (candidates.length > 1) {
    throw new Error(
      'Multiple Partner Organization profiles match the selected login. Refusing to create an ambiguous link.',
    );
  }

  const existing = candidates[0] || null;
  if (existing && !isOwnedDemo(existing)) {
    return { profile: existing, operation: 'reuse' };
  }

  const deterministicCollision = await collection.findOne({ _id: DEMO_IDS.partnerProfile });
  assertOwnedDemoOrAbsent(deterministicCollision, 'Partner Organization profile');

  const profile = {
    _id: existing?._id || DEMO_IDS.partnerProfile,
    user: partnerAccount._id,
    organizationName: partnerAccount.name,
    contactPerson: partnerAccount.contactPerson || '',
    contactNumber: partnerAccount.phone || '',
    address: partnerAccount.jurisdiction || 'Sampaloc, Manila',
    status: 'Active',
    ...DEMO_TAG,
    updatedAt: now,
  };

  if (!DRY_RUN) {
    await collection.updateOne(
      { _id: profile._id },
      {
        $set: Object.fromEntries(Object.entries(profile).filter(([key]) => key !== '_id')),
        $setOnInsert: { createdAt: now },
      },
      { upsert: true },
    );
  }

  return { profile, operation: existing ? 'update' : 'create' };
}

async function guardedDemoUpsert(collection, id, fields, now, label) {
  const existing = await collection.findOne({ _id: id });
  assertOwnedDemoOrAbsent(existing, label);
  if (!DRY_RUN) {
    await collection.updateOne(
      { _id: id },
      {
        $set: { ...fields, ...DEMO_TAG, updatedAt: now },
        $setOnInsert: { createdAt: now },
      },
      { upsert: true },
    );
  }
  return existing ? 'update' : 'create';
}

async function run() {
  const uri = process.env.MONGO_URI;
  if (!uri) throw new Error('MONGO_URI is required in backend/.env or the shell environment.');

  const client = new MongoClient(uri, {
    serverApi: {
      version: ServerApiVersion.v1,
      strict: true,
      deprecationErrors: true,
    },
  });

  try {
    await client.connect();
    const db = process.env.MONGO_DB_NAME ? client.db(process.env.MONGO_DB_NAME) : client.db();
    await db.command({ ping: 1 });

    const now = new Date();
    const recentSensorAt = new Date(now.getTime() - 4 * 60 * 1000);
    const activeRequestedAt = new Date(now.getTime() - 2 * 60 * 60 * 1000);
    const completedRequestedAt = new Date(now.getTime() - 8 * 24 * 60 * 60 * 1000);
    const completedStartedAt = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000 - 45 * 60 * 1000);
    const completedAt = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const dropOffAt = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    const accounts = await resolveAccounts(db);
    const bin = await findDemoBin(db);
    assertValidDemoBin(bin);

    const partnerResult = await resolvePartnerProfile(db, accounts.partner, now);
    const partner = partnerResult.profile;
    const collectorName = displayName(accounts.collector) || displayName(accounts.collectorUser);

    const binUpdate = {
      binCode: 'DEMO-BIN-001',
      publicQrCode: 'RECYTECH-DEMO-BIN-001',
      name: 'RecyTech Demo Bin - NU Manila',
      binName: 'RecyTech Demo Bin - NU Manila',
      address: 'National University Manila, Sampaloc, Manila',
      latitude: Number(bin.location.coordinates[1]),
      longitude: Number(bin.location.coordinates[0]),
      partnerOrganizationId: partner._id,
      partnerOrganizationName: partner.organizationName,
      active: true,
      isActive: true,
      publicVisible: true,
      acceptedCategories: ['smartphone', 'laptop', 'keyboard', 'mouse', 'battery'],
      latestFillPercentage: 82,
      fullnessStatus: 'nearly_full',
      latestSensorStatus: 'active',
      latestControllerStatus: 'active',
      lastSensorUpdatedAt: recentSensorAt,
      demoRecord: true,
      ...DEMO_TAG,
      updatedAt: now,
    };

    if (!DRY_RUN) {
      const binResult = await db.collection('bins').updateOne(
        { _id: bin._id, isDemo: true },
        { $set: binUpdate },
      );
      if (binResult.matchedCount !== 1) {
        throw new Error('The demo bin changed during seeding; no guarded update was applied.');
      }
    }

    const binSnapshot = {
      binCode: 'DEMO-BIN-001',
      name: 'RecyTech Demo Bin - NU Manila',
      address: 'National University Manila, Sampaloc, Manila',
      latitude: binUpdate.latitude,
      longitude: binUpdate.longitude,
      latestFillPercentage: 82,
      latestSensorStatus: 'active',
      latestControllerStatus: 'active',
      lastSensorUpdatedAt: recentSensorAt,
    };

    const dropOffOperation = await guardedDemoUpsert(
      db.collection('householddropoffs'),
      DEMO_IDS.dropOff,
      {
        householdUserId: accounts.household._id,
        householdAccountModel: 'User',
        binId: bin._id,
        partnerOrganizationId: partner._id,
        submissionMethod: 'qr',
        items: [{ category: 'smartphone', quantity: 2 }],
        idempotencyKey: `${DEMO_BATCH}:drop-off-001`,
        submittedAt: dropOffAt,
        status: 'submitted',
        pointsStatus: 'not_processed',
        pointsAwarded: 0,
      },
      now,
      'Registered User drop-off',
    );

    const activeRequestOperation = await guardedDemoUpsert(
      db.collection('collectionrequests'),
      DEMO_IDS.activeRequest,
      {
        partnerOrganizationId: partner._id,
        partnerOrganizationName: partner.organizationName,
        binId: bin._id,
        requestedAt: activeRequestedAt,
        queueEnteredAt: activeRequestedAt,
        status: 'queued',
        assignedCollectorId: accounts.collector._id,
        assignedCollectorName: collectorName,
        claimedAt: null,
        startedAt: null,
        completedAt: null,
        remarks: 'DEMO ACTIVE REQUEST — NU Manila defense scenario.',
        reason: 'Manual partner organization request',
        fullnessStatus: 'nearly_full',
        binSnapshot,
      },
      now,
      'Active collection request',
    );

    const completedRequestOperation = await guardedDemoUpsert(
      db.collection('collectionrequests'),
      DEMO_IDS.completedRequest,
      {
        partnerOrganizationId: partner._id,
        partnerOrganizationName: partner.organizationName,
        binId: bin._id,
        requestedAt: completedRequestedAt,
        queueEnteredAt: completedRequestedAt,
        status: 'completed',
        assignedCollectorId: accounts.collector._id,
        assignedCollectorName: collectorName,
        claimedAt: completedStartedAt,
        startedAt: completedStartedAt,
        completedAt,
        remarks: 'DEMO-HISTORY-001 — Completed NU Manila smart-bin collection.',
        reason: 'Manual partner organization request',
        fullnessStatus: 'nearly_full',
        binSnapshot: {
          ...binSnapshot,
          latestFillPercentage: 76,
          lastSensorUpdatedAt: completedRequestedAt,
        },
      },
      now,
      'Completed collection request',
    );

    const prefix = DRY_RUN ? '[DRY-RUN]' : '[DEMO]';
    console.log(`${prefix} Existing login accounts resolved (no auth records changed)`);
    console.log(`${prefix} Demo bin ready${DRY_RUN ? ' (would update)' : ''}`);
    console.log(`${prefix} Partner link ready${DRY_RUN ? ` (would ${partnerResult.operation})` : ''}`);
    console.log(`${prefix} User drop-off ready${DRY_RUN ? ` (would ${dropOffOperation})` : ''}`);
    console.log(`${prefix} Active collection request ready${DRY_RUN ? ` (would ${activeRequestOperation})` : ''}`);
    console.log(`${prefix} Collector history ready${DRY_RUN ? ` (would ${completedRequestOperation})` : ''}`);
    console.log(`${prefix} Rewards left empty; no configured partner offers or canonical point rules found`);
    console.log(`${prefix} Notifications left unchanged; the mobile app currently uses in-memory notifications`);
  } finally {
    await client.close();
  }
}

run().catch((error) => {
  console.error(`[DEMO] Seed failed safely: ${error.message}`);
  process.exitCode = 1;
});
