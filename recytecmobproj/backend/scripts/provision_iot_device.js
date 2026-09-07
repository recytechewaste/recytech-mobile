const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { MongoClient, ServerApiVersion } = require('mongodb');

const backendDirectory = path.resolve(__dirname, '..');
const credentialsPath = path.join(backendDirectory, 'iot-device.credentials.local.json');
const defaultDeviceId = 'RECYTECH-XIAO-001';
const deviceId = String(process.argv[2] || defaultDeviceId).trim();
const deviceIdPattern = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/;

require('dotenv').config({ path: path.join(backendDirectory, '.env') });

function hashDeviceKey(deviceKey) {
  return crypto.createHash('sha256').update(deviceKey, 'utf8').digest('hex');
}

function readLocalCredentials() {
  if (!fs.existsSync(credentialsPath)) return null;

  let credentials;
  try {
    credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
  } catch (_) {
    throw new Error('The local IoT credentials file is not valid JSON.');
  }

  if (
    credentials?.deviceId !== deviceId ||
    typeof credentials?.deviceKey !== 'string' ||
    credentials.deviceKey.length < 43
  ) {
    throw new Error('The local IoT credentials file does not match the requested device.');
  }

  return credentials;
}

function writeLocalCredentials(credentials) {
  fs.writeFileSync(
    credentialsPath,
    `${JSON.stringify(credentials, null, 2)}\n`,
    { encoding: 'utf8', flag: 'wx', mode: 0o600 },
  );
}

function storedHashIsValid(value) {
  return /^[a-f0-9]{64}$/i.test(String(value || ''));
}

async function provision() {
  if (!deviceIdPattern.test(deviceId)) {
    throw new Error('Device ID must contain 1 to 128 letters, numbers, dots, underscores, colons, or hyphens.');
  }

  const uri = process.env.MONGO_URI;
  if (!uri) throw new Error('MONGO_URI is not configured.');

  const client = new MongoClient(uri, {
    serverApi: {
      version: ServerApiVersion.v1,
      strict: true,
      deprecationErrors: true,
    },
  });

  let createdCredentialsFile = false;
  try {
    await client.connect();
    const database = process.env.MONGO_DB_NAME
      ? client.db(process.env.MONGO_DB_NAME)
      : client.db();
    const devices = database.collection('iotdevices');

    await devices.createIndex(
      { deviceId: 1 },
      { unique: true, name: 'unique_device_id' },
    );

    const existing = await devices.findOne({ deviceId });
    let credentials = readLocalCredentials();
    let recordCreated = false;

    if (existing) {
      if (!storedHashIsValid(existing.deviceKeyHash)) {
        throw new Error('The existing device record does not contain a valid SHA-256 key hash.');
      }
      if (!credentials) {
        throw new Error('The device already exists, but its local credentials file is unavailable.');
      }
      if (hashDeviceKey(credentials.deviceKey) !== existing.deviceKeyHash.toLowerCase()) {
        throw new Error('The existing device record does not match the local credentials file.');
      }

      await devices.updateOne(
        { _id: existing._id },
        {
          $set: { enabled: true, updatedAt: new Date() },
          $unset: { deviceKey: '', apiKey: '', deviceSecret: '' },
        },
      );
    } else {
      if (!credentials) {
        credentials = {
          deviceId,
          deviceKey: crypto.randomBytes(32).toString('base64url'),
        };
        writeLocalCredentials(credentials);
        createdCredentialsFile = true;
      }

      const now = new Date();
      try {
        await devices.insertOne({
          deviceId,
          deviceKeyHash: hashDeviceKey(credentials.deviceKey),
          enabled: true,
          createdAt: now,
          updatedAt: now,
        });
        recordCreated = true;
      } catch (error) {
        if (createdCredentialsFile) {
          fs.rmSync(credentialsPath, { force: true });
          createdCredentialsFile = false;
        }
        if (error?.code === 11000) {
          throw new Error('The device was created concurrently; no duplicate was added.');
        }
        throw error;
      }
    }

    const verified = await devices.findOne(
      { deviceId },
      {
        projection: {
          deviceId: 1,
          deviceKeyHash: 1,
          enabled: 1,
          deviceKey: 1,
          apiKey: 1,
          deviceSecret: 1,
        },
      },
    );
    const databaseStoresOnlyHash = Boolean(
      verified &&
      storedHashIsValid(verified.deviceKeyHash) &&
      !verified.deviceKey &&
      !verified.apiKey &&
      !verified.deviceSecret,
    );

    if (!verified || verified.enabled !== true || !databaseStoresOnlyHash) {
      throw new Error('Provisioned device verification failed.');
    }

    console.log(JSON.stringify({
      ok: true,
      recordCreated,
      deviceId: verified.deviceId,
      enabled: verified.enabled,
      credentialsFilePresent: fs.existsSync(credentialsPath),
      credentialsFileCreated: createdCredentialsFile,
      databaseStoresOnlyHash,
    }));
  } finally {
    await client.close();
  }
}

provision().catch((error) => {
  console.error(JSON.stringify({
    ok: false,
    error: 'provisioning_failed',
    message: error instanceof Error ? error.message : 'Unknown provisioning error.',
  }));
  process.exitCode = 1;
});
