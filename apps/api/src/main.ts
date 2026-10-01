import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { createApp } from './app';
import { readConfig } from './config';
import { PrismaDatabase } from './database/prisma';
import { FirebaseIdentityVerifier } from './auth/firebase.identity';

async function bootstrap() {
  const config = readConfig(process.env);
  const firebase = initializeApp({ credential: applicationDefault(), projectId: config.firebaseProject });
  const database = new PrismaDatabase(config.databaseUrl);
  const app = await createApp({
    identity: new FirebaseIdentityVerifier(getAuth(firebase)), users: database,
    ready: () => database.ready(), origins: config.origins,
    log: (event) => process.stdout.write(JSON.stringify(event) + '\n'),
  });
  async function shutdown() { await app.close(); await database.close(); }
  process.once('SIGTERM', () => { void shutdown(); });
  process.once('SIGINT', () => { void shutdown(); });
  await app.listen(config.port, '0.0.0.0');
  process.stdout.write(JSON.stringify({ event: 'listening', port: config.port }) + '\n');
}
bootstrap().catch(() => {
  process.stderr.write('Falha ao iniciar a API. Confira a configuração e as dependências.\n');
  process.exitCode = 1;
});
