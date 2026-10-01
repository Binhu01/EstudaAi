export interface Configuration {
  databaseUrl: string;
  firebaseProject: string;
  firebaseWebApiKey?: string;
  origins: string[];
  port: number;
  production: boolean;
}
export function readConfig(env: NodeJS.ProcessEnv): Configuration {
  const production = env.NODE_ENV === 'production';
  const databaseUrl = env.DATABASE_URL ?? '';
  const firebaseProject = env.FIREBASE_PROJECT_ID ?? '';
  const origins = (env.CORS_ORIGINS ?? '').split(',').map((origin) => origin.trim());
  const port = Number(env.PORT ?? 3001);
  const invalid = (field: string): never => { throw new Error(`Configuração inválida: ${field}.`); };
  let database: URL;
  try { database = new URL(databaseUrl); } catch { return invalid('DATABASE_URL'); }
  if (!['postgres:', 'postgresql:'].includes(database.protocol) || !database.hostname) invalid('DATABASE_URL');
  if (!/^[a-z][a-z0-9-]{4,29}$/.test(firebaseProject)) invalid('FIREBASE_PROJECT_ID');
  if (!Number.isInteger(port) || port < 1 || port > 65535) invalid('PORT');
  if (!origins.length || origins.some((origin) => {
    try {
      const url = new URL(origin);
      return url.origin !== origin || !['https:', 'http:'].includes(url.protocol) || (production && url.protocol !== 'https:');
    } catch { return true; }
  })) invalid('CORS_ORIGINS');
  if (production && env.FIREBASE_AUTH_EMULATOR_HOST) invalid('FIREBASE_AUTH_EMULATOR_HOST');
  const firebaseWebApiKey = env.FIREBASE_WEB_API_KEY?.trim() || undefined;
  return { databaseUrl, firebaseProject, firebaseWebApiKey, origins, port, production };
}
