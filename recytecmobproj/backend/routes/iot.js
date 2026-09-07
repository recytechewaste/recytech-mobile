const crypto = require('crypto');
const express = require('express');

const DEVICE_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/;
const READING_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/;
const UTC_TIMESTAMP_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/;
const MAX_DEVICE_KEY_LENGTH = 512;
const MAX_DISTANCE_MM = 1000000;
const DUMMY_KEY_HASH = Buffer.alloc(32);

function isPlainObject(value) {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function unexpectedFields(body, allowedFields) {
  const allowed = new Set(allowedFields);
  return Object.keys(body).filter((field) => !allowed.has(field));
}

function bearerDeviceKey(req) {
  const match = /^Bearer\s+(\S+)$/i.exec(String(req.headers.authorization || '').trim());
  if (!match || match[1].length > MAX_DEVICE_KEY_LENGTH) return '';
  return match[1];
}

function deviceKeyHash(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest();
}

function storedKeyHash(value) {
  const hash = String(value || '').trim();
  return /^[a-f0-9]{64}$/i.test(hash) ? Buffer.from(hash, 'hex') : DUMMY_KEY_HASH;
}

function isDeviceDisabled(device) {
  const status = String(device?.status || '').trim().toLowerCase();
  return device?.enabled !== true || device?.active === false || ['disabled', 'inactive', 'revoked'].includes(status);
}

function associatedBinIdentifier(device) {
  return device?.binId ?? device?.associatedBinId ?? device?.binCode ?? null;
}

function responseBinIdentifier(device) {
  const binId = associatedBinIdentifier(device);
  return binId == null ? null : String(binId);
}

function validateOptionalString(body, field, maxLength) {
  if (!(field in body)) return { ok: true, supplied: false };
  if (typeof body[field] !== 'string') {
    return { ok: false, message: `${field} must be a string.` };
  }
  const value = body[field].trim();
  if (!value || value.length > maxLength) {
    return { ok: false, message: `${field} must contain 1 to ${maxLength} characters.` };
  }
  return { ok: true, supplied: true, value };
}

function parseMeasurementTimestamp(value) {
  if (typeof value !== 'string' || value.length > 32 || !UTC_TIMESTAMP_PATTERN.test(value)) return null;
  const timestamp = new Date(value);
  return Number.isNaN(timestamp.getTime()) ? null : timestamp;
}

function sameTimestamp(left, right) {
  if (!left && !right) return true;
  if (!left || !right) return false;
  return new Date(left).getTime() === new Date(right).getTime();
}

function createIotRouter({ database }) {
  if (typeof database !== 'function') throw new TypeError('database must be a function.');

  const router = express.Router();
  const iotDevicesCollection = () => database().collection('iotdevices');
  const sensorReadingsCollection = () => database().collection('sensorreadings');

  async function authenticateDevice(req, res, next) {
    try {
      const deviceId = String(req.get('X-Device-ID') || '').trim();
      const key = bearerDeviceKey(req);
      if (!DEVICE_ID_PATTERN.test(deviceId) || !key) {
        return res.status(401).json({ code: 'device_unauthorized', message: 'Device authentication failed.' });
      }

      const device = await iotDevicesCollection().findOne({ deviceId });
      const presentedHash = deviceKeyHash(key);
      const expectedHash = storedKeyHash(device?.deviceKeyHash);
      const keyMatches = crypto.timingSafeEqual(presentedHash, expectedHash);

      if (!device || !keyMatches || isDeviceDisabled(device)) {
        return res.status(401).json({ code: 'device_unauthorized', message: 'Device authentication failed.' });
      }

      req.iotDevice = device;
      return next();
    } catch (error) {
      return next(error);
    }
  }

  router.post('/heartbeat', authenticateDevice, async (req, res, next) => {
    try {
      const body = req.body ?? {};
      if (!isPlainObject(body)) {
        return res.status(400).json({ code: 'invalid_payload', message: 'Request body must be a JSON object.' });
      }

      const unknown = unexpectedFields(body, ['firmwareVersion', 'controllerStatus']);
      if (unknown.length) {
        return res.status(400).json({
          code: 'unexpected_fields',
          message: `Unexpected field(s): ${unknown.join(', ')}.`,
        });
      }

      const firmwareVersion = validateOptionalString(body, 'firmwareVersion', 64);
      if (!firmwareVersion.ok) {
        return res.status(400).json({ code: 'invalid_firmware_version', message: firmwareVersion.message });
      }
      const controllerStatus = validateOptionalString(body, 'controllerStatus', 64);
      if (!controllerStatus.ok) {
        return res.status(400).json({ code: 'invalid_controller_status', message: controllerStatus.message });
      }

      const receivedAt = new Date();
      const updates = { lastSeenAt: receivedAt, updatedAt: receivedAt };
      if (firmwareVersion.supplied) updates.firmwareVersion = firmwareVersion.value;
      if (controllerStatus.supplied) updates.controllerStatus = controllerStatus.value;

      await iotDevicesCollection().updateOne(
        { _id: req.iotDevice._id },
        { $set: updates },
      );

      return res.json({
        ok: true,
        deviceId: req.iotDevice.deviceId,
        binId: responseBinIdentifier(req.iotDevice),
        receivedAt: receivedAt.toISOString(),
      });
    } catch (error) {
      return next(error);
    }
  });

  router.post('/sensor-readings', authenticateDevice, async (req, res, next) => {
    try {
      const body = req.body;
      if (!isPlainObject(body)) {
        return res.status(400).json({ code: 'invalid_payload', message: 'Request body must be a JSON object.' });
      }

      const unknown = unexpectedFields(body, ['readingId', 'distanceMm', 'measuredAt']);
      if (unknown.length) {
        return res.status(400).json({
          code: 'unexpected_fields',
          message: `Unexpected field(s): ${unknown.join(', ')}.`,
        });
      }

      const readingId = typeof body.readingId === 'string' ? body.readingId.trim() : '';
      if (!READING_ID_PATTERN.test(readingId)) {
        return res.status(400).json({
          code: 'invalid_reading_id',
          message: 'readingId must contain 1 to 128 letters, numbers, dots, underscores, colons, or hyphens.',
        });
      }

      if (
        typeof body.distanceMm !== 'number' ||
        !Number.isSafeInteger(body.distanceMm) ||
        body.distanceMm < 0 ||
        body.distanceMm > MAX_DISTANCE_MM
      ) {
        return res.status(400).json({
          code: 'invalid_distance',
          message: `distanceMm must be an integer from 0 to ${MAX_DISTANCE_MM}.`,
        });
      }

      let measuredAt = null;
      if ('measuredAt' in body) {
        measuredAt = parseMeasurementTimestamp(body.measuredAt);
        if (!measuredAt) {
          return res.status(400).json({
            code: 'invalid_measurement_timestamp',
            message: 'measuredAt must be a valid UTC ISO 8601 timestamp.',
          });
        }
      }

      const binId = associatedBinIdentifier(req.iotDevice);
      if (binId == null || String(binId).trim() === '') {
        return res.status(409).json({
          code: 'device_not_assigned',
          message: 'The authenticated device is not associated with a bin.',
        });
      }

      const receivedAt = new Date();
      const reading = {
        deviceId: req.iotDevice.deviceId,
        binId,
        readingId,
        distanceMm: body.distanceMm,
        measuredAt,
        receivedAt,
      };

      try {
        await sensorReadingsCollection().insertOne(reading);
      } catch (error) {
        if (error?.code !== 11000) throw error;

        const existing = await sensorReadingsCollection().findOne({
          deviceId: req.iotDevice.deviceId,
          readingId,
        });
        if (
          !existing ||
          existing.distanceMm !== body.distanceMm ||
          !sameTimestamp(existing.measuredAt, measuredAt)
        ) {
          return res.status(409).json({
            code: 'reading_id_conflict',
            message: 'readingId was already used for different sensor data.',
          });
        }

        await iotDevicesCollection().updateOne(
          { _id: req.iotDevice._id },
          { $set: { lastSeenAt: receivedAt, updatedAt: receivedAt } },
        );
        return res.json({
          ok: true,
          idempotentReplay: true,
          deviceId: req.iotDevice.deviceId,
          binId: responseBinIdentifier(req.iotDevice),
          readingId,
          receivedAt: new Date(existing.receivedAt).toISOString(),
        });
      }

      await iotDevicesCollection().updateOne(
        { _id: req.iotDevice._id },
        { $set: { lastSeenAt: receivedAt, updatedAt: receivedAt } },
      );

      return res.status(201).json({
        ok: true,
        idempotentReplay: false,
        deviceId: req.iotDevice.deviceId,
        binId: responseBinIdentifier(req.iotDevice),
        readingId,
        receivedAt: receivedAt.toISOString(),
      });
    } catch (error) {
      return next(error);
    }
  });

  return router;
}

async function ensureIotIndexes({ database }) {
  if (typeof database !== 'function') throw new TypeError('database must be a function.');
  await Promise.all([
    database().collection('iotdevices').createIndex(
      { deviceId: 1 },
      { unique: true, name: 'unique_device_id' },
    ),
    database().collection('sensorreadings').createIndex(
      { deviceId: 1, readingId: 1 },
      { unique: true, name: 'unique_device_reading_id' },
    ),
  ]);
}

module.exports = { createIotRouter, ensureIotIndexes };
