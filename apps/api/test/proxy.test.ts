import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app';
import { readConfig } from '../src/config';

const env = { DATABASE_URL: 'postgresql://user:test@localhost/study', FIREBASE_PROJECT_ID: 'estuda-ai-test', CORS_ORIGINS: 'https://study.example' };

for (const scenario of [
  { name: 'default ignores forged forwarded addresses', proxy: undefined, expected: 429 },
  { name: 'untrusted peer cannot evade the IP budget', proxy: '192.0.2.4/32', expected: 429 },
  { name: 'explicit trusted peer keeps separate client IP budgets', proxy: '127.0.0.1/32,::1/128', expected: 200 },
]) {
  test(scenario.name, async () => {
    const config = readConfig({ ...env, TRUSTED_PROXY_CIDRS: scenario.proxy });
    const app = await createApp({
      ...config,
      identity: { async verify(token) { return { externalId: token }; } },
      users: { async resolve(id) { return { id }; } },
      ready: async () => true,
      rateLimit: 2,
    });
    await app.listen(0, '127.0.0.1');
    const url = await app.getUrl();
    try {
      for (const [index, ip] of ['198.51.100.10', '198.51.100.10', '198.51.100.20'].entries()) {
        const response = await fetch(url + '/v1/me', {
          headers: { authorization: 'Bearer student-' + index, 'x-forwarded-for': ip },
        });
        assert.equal(response.status, index === 2 ? scenario.expected : 200);
      }
    } finally { await app.close(); }
  });
}

test('trust proxy rejects wildcards, hop counts and invalid CIDRs without disclosing input', () => {
  for (const value of ['true', '*', '1', 'loopback', '127.0.0.1/33', '::1/129', '0.0.0.0/0', '::/0', 'SECRET', '127.0.0.1,,::1']) {
    assert.throws(() => readConfig({ ...env, TRUSTED_PROXY_CIDRS: value }),
      (error: unknown) => error instanceof Error && error.message === 'Configuração inválida: TRUSTED_PROXY_CIDRS.');
  }
});
