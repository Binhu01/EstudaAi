import { isIP } from 'node:net';

export interface Configuration {
  databaseUrl: string;
  firebaseProject: string;
  firebaseWebApiKey?: string;
  openaiApiKey?: string;
  steveModel?: string;
  steveDailyLimit: number;
  steveGlobalDailyLimit: number;
  origins: string[];
  trustedProxyCidrs: string[];
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
  const proxyValue = env.TRUSTED_PROXY_CIDRS?.trim() ?? '';
  const trustedProxyCidrs = proxyValue ? proxyValue.split(',').map(value => value.trim()) : [];
  if (trustedProxyCidrs.length > 32 || trustedProxyCidrs.some(value => {
    const parts = value.split('/');
    const family = isIP(parts[0] ?? '');
    if (!family || parts.length > 2) return true;
    if (parts.length === 1) return false;
    if (!/^[0-9]+$/.test(parts[1] ?? '')) return true;
    const prefix = Number(parts[1]);
    return prefix < 1 || prefix > (family === 4 ? 32 : 128);
  })) invalid('TRUSTED_PROXY_CIDRS');
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
  const openaiApiKey = env.OPENAI_API_KEY?.trim() || undefined;
  const steveModel = env.STEVE_MODEL?.trim() || undefined;
  if (!!openaiApiKey !== !!steveModel) invalid('OPENAI_API_KEY / STEVE_MODEL');
  if (steveModel && !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(steveModel)) invalid('STEVE_MODEL');
  const steveDailyLimit = Number(env.STEVE_DAILY_LIMIT ?? 10);
  const steveGlobalDailyLimit = Number(env.STEVE_GLOBAL_DAILY_LIMIT ?? 1000);
  if (!Number.isSafeInteger(steveDailyLimit) || steveDailyLimit < 1 || steveDailyLimit > 1000) invalid('STEVE_DAILY_LIMIT');
  if (!Number.isSafeInteger(steveGlobalDailyLimit) || steveGlobalDailyLimit < steveDailyLimit || steveGlobalDailyLimit > 100000) invalid('STEVE_GLOBAL_DAILY_LIMIT');
  return { databaseUrl, firebaseProject, firebaseWebApiKey, openaiApiKey, steveModel, steveDailyLimit, steveGlobalDailyLimit, origins, trustedProxyCidrs, port, production };
}
