import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { createApp } from './app';
import { readConfig } from './config';
import { PrismaDatabase } from './database/prisma';
import { FirebaseIdentityVerifier } from './auth/firebase.identity';
import { FirebaseRestAuth } from './auth/firebase-rest.auth';
import { loadStudyDirectory } from './catalog/study-directory';
import { QuotaRepository } from './steve/quota.repository';
import { SteveService } from './steve/steve.service';
import { OpenAiSteveProvider } from './steve/openai.provider';
import { StudyHistoryService } from './study/study.service';

async function bootstrap() {
  const config = readConfig(process.env);
  const firebase = initializeApp({ credential: applicationDefault(), projectId: config.firebaseProject });
  const database = new PrismaDatabase(config.databaseUrl);
  const identity = new FirebaseIdentityVerifier(getAuth(firebase));
  const quota = new QuotaRepository(database,{userDaily:config.steveDailyLimit,globalDaily:config.steveGlobalDailyLimit});
  const provider = config.openaiApiKey && config.steveModel ? new OpenAiSteveProvider(config.openaiApiKey,config.steveModel) : undefined;
  const directory=loadStudyDirectory();
  const app = await createApp({
    identity, users: database,
    auth: new FirebaseRestAuth(config.firebaseWebApiKey, identity),
    steve: new SteveService(directory,quota,provider),
    study: new StudyHistoryService(database,directory),
    steveDailyLimit: config.steveDailyLimit,
    ready: () => database.ready(), origins: config.origins,
    trustedProxyCidrs: config.trustedProxyCidrs,
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
