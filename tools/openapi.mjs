import { createRequire } from 'node:module';
import { writeFile } from 'node:fs/promises';
const require = createRequire(import.meta.url);
const { createApp, createOpenApi } = require('../apps/api/dist/src/app.js');
// Only generates metadata: never listens or simulates a signed-in user.
const unavailable = async () => { throw new Error('Documentation only'); };
const app = await createApp({ identity: { verify: unavailable }, users: { resolve: unavailable }, ready: async () => false, origins: [] });
try {
  await app.init();
  await writeFile('contracts/openapi.json', JSON.stringify(createOpenApi(app), null, 2) + '\n');
} finally { await app.close(); }
