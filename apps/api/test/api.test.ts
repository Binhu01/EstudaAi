import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createApp, createOpenApi } from '../src/app';
import { AppDependencies } from '../src/contracts';

async function fixture(overrides: Partial<AppDependencies> = {}) {
  const logs: Readonly<Record<string, unknown>>[] = [];
  const app = await createApp({
    identity: { async verify(token) {
      if (token !== 'valid-token') throw new Error('private credential detail');
      return { externalId: 'external-user' };
    } },
    users: { async resolve(id) { assert.equal(id, 'external-user'); return { id: 'internal-user' }; } },
    ready: async () => true,
    origins: ['http://localhost:4173'],
    log: (event) => logs.push(event),
    ...overrides,
  });
  await app.listen(0, '127.0.0.1');
  const url = await app.getUrl();
  return { app, logs, get: (path: string, token?: string, extra?: Record<string, string>) => fetch(url + path, {
    headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}), ...extra },
  }) };
}

test('health is public and readiness returns 503 when the database is unavailable', async () => {
  const f = await fixture({ ready: async () => false });
  try {
    assert.equal((await f.get('/health/live')).status, 200);
    const res = await f.get('/health/ready');
    assert.equal(res.status, 503);
    assert.equal((await res.json() as { code: string }).code, 'UNAVAILABLE');
  } finally { await f.app.close(); }
});

test('private endpoints reject missing, invalid, expired and foreign-project credentials without disclosure', async () => {
  const f = await fixture();
  try {
    for (const token of [undefined, 'invalid', 'expired', 'other-project']) {
      const res = await f.get('/v1/me', token);
      assert.equal(res.status, 401);
      const body = await res.text();
      assert.ok(!body.includes('private credential'));
      assert.ok(!body.includes('stack'));
    }
  } finally { await f.app.close(); }
});

test('verified identity resolves server-owned user and never accepts Premium from client headers', async () => {
  const f = await fixture();
  try {
    const res = await f.get('/v1/me', 'valid-token', { 'x-user-id': 'attacker', 'x-plan': 'PREMIUM' });
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { id: 'internal-user', plan: 'FREE' });
    const entitlements = await f.get('/v1/me/entitlements', 'valid-token');
    assert.deepEqual(await entitlements.json(), { plan: 'FREE', capabilities: { advancedAi: false, generatedQuestions: false, advancedAnalytics: false } });
  } finally { await f.app.close(); }
});

test('unexpected failures are sanitized and logs omit credentials and URLs', async () => {
  const f = await fixture({ users: { async resolve() { throw new Error('database password SECRET'); } } });
  try {
    const res = await f.get('/v1/me?private=SECRET', 'valid-token', { 'x-request-id': 'untrusted' });
    assert.equal(res.status, 500);
    assert.ok(res.headers.get('x-request-id'));
    assert.notEqual(res.headers.get('x-request-id'), 'untrusted');
    assert.ok(!(await res.text()).includes('SECRET'));
    assert.ok(!JSON.stringify(f.logs).includes('SECRET'));
    assert.ok(!JSON.stringify(f.logs).includes('valid-token'));
  } finally { await f.app.close(); }
});

test('rate limits are enforced and untrusted Origin receives no CORS authorization', async () => {
  const f = await fixture({ rateLimit: 2 });
  try {
    await f.get('/v1/me', 'valid-token');
    await f.get('/v1/me', 'valid-token');
    assert.equal((await f.get('/v1/me', 'valid-token')).status, 429);
    const res = await f.get('/health/live', undefined, { Origin: 'https://untrusted.invalid' });
    assert.equal(res.headers.get('access-control-allow-origin'), null);
  } finally { await f.app.close(); }
});

test('the verified user shares a quota across private endpoints', async () => {
  const f = await fixture({ rateLimit: 2 });
  try {
    assert.equal((await f.get('/v1/me', 'valid-token')).status, 200);
    assert.equal((await f.get('/v1/me/entitlements', 'valid-token')).status, 200);
    assert.equal((await f.get('/v1/me', 'valid-token')).status, 429);
    assert.equal((await f.get('/health/live')).status, 200);
  } finally { await f.app.close(); }
});

test('OpenAPI documents public readiness and safe private error contracts', async () => {
  const f = await fixture();
  try {
    const document = createOpenApi(f.app);
    assert.ok(document.paths['/health/ready']?.get?.responses['503']);
    assert.equal(document.paths['/health/live']?.get?.security, undefined);
    for (const path of ['/v1/me', '/v1/me/entitlements']) {
      const operation = document.paths[path]?.get;
      assert.deepEqual(operation?.security, [{ bearer: [] }]);
      for (const status of ['401', '429', '500', '503']) {
        const response = operation?.responses[status];
        assert.ok(response && 'content' in response && response.content?.['application/json']);
      }
    }
    assert.ok(document.components?.schemas?.SafeErrorResponse);
  } finally { await f.app.close(); }
});
