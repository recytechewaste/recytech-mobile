const path = require('path');
const { MongoClient, ServerApiVersion } = require('mongodb');

require('dotenv').config({ path: path.join(__dirname, '.env') });

const DEMO_FILTER = Object.freeze({
  isDemo: true,
  demoBatch: 'recytech-defense-demo',
});
const DRY_RUN = process.argv.includes('--dry-run');

// Authentication/profile source collections are deliberately excluded.
const COLLECTIONS = Object.freeze([
  'collectorreports',
  'collectionrequests',
  'pointstransactions',
  'householddropoffs',
  'partnerorganizations',
  'bins',
]);

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
    const existingNames = new Set(
      (await db.listCollections({}, { nameOnly: true }).toArray()).map((item) => item.name),
    );

    let total = 0;
    for (const name of COLLECTIONS) {
      if (!existingNames.has(name)) {
        console.log(`[DEMO] ${name}: 0 ${DRY_RUN ? 'would be removed' : 'removed'}`);
        continue;
      }

      const collection = db.collection(name);
      const count = await collection.countDocuments(DEMO_FILTER);
      if (!DRY_RUN && count > 0) {
        const result = await collection.deleteMany(DEMO_FILTER);
        total += result.deletedCount;
        console.log(`[DEMO] ${name}: ${result.deletedCount} removed`);
      } else {
        total += count;
        console.log(`[DEMO] ${name}: ${count} ${DRY_RUN ? 'would be removed' : 'removed'}`);
      }
    }

    console.log(
      `[DEMO] Cleanup ${DRY_RUN ? 'dry run' : 'complete'}: ${total} tagged document${total === 1 ? '' : 's'} ${DRY_RUN ? 'matched' : 'removed'}.`,
    );
    console.log('[DEMO] users, collectors, lguaccounts, and householdpointsaccounts were not modified.');
  } finally {
    await client.close();
  }
}

run().catch((error) => {
  console.error(`[DEMO] Cleanup failed safely: ${error.message}`);
  process.exitCode = 1;
});
