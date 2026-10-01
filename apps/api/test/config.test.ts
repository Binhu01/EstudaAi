import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readConfig } from '../src/config';

const valid = { DATABASE_URL: 'postgresql://user:private@localhost:5432/study', FIREBASE_PROJECT_ID: 'estuda-ai-test', CORS_ORIGINS: 'http://localhost:4173', PORT: '3001' };
test('Firebase REST key is optional but never exposed as a configuration error', () => {
  assert.equal(readConfig(valid).firebaseWebApiKey, undefined);
  assert.equal(readConfig({...valid, FIREBASE_WEB_API_KEY:'server-only'}).firebaseWebApiKey, 'server-only');
});
test('configuration fails closed for missing values and never leaks their contents', () => {
  assert.throws(() => readConfig({}));
  assert.throws(() => readConfig({ ...valid, PORT: '0' }));
  assert.throws(() => readConfig({ ...valid, DATABASE_URL: 'SECRET' }), (error: unknown) => error instanceof Error && !error.message.includes('SECRET'));
  assert.throws(() => readConfig({ ...valid, CORS_ORIGINS: '*' }));
});
test('production rejects emulator authentication and non-HTTPS origins', () => {
  assert.throws(() => readConfig({ ...valid, NODE_ENV: 'production', CORS_ORIGINS: 'https://study.example', FIREBASE_AUTH_EMULATOR_HOST: 'localhost:9099' }));
  assert.throws(() => readConfig({ ...valid, NODE_ENV: 'production' }));
  assert.equal(readConfig({ ...valid, NODE_ENV: 'production', CORS_ORIGINS: 'https://study.example' }).production, true);
});
