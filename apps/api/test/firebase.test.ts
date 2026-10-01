import { test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { UnauthorizedException } from '@nestjs/common';
import { FirebaseIdentityVerifier } from '../src/auth/firebase.identity';

test('the real Firebase Admin SDK rejects malformed and foreign-project JWT content', async () => {
  const app = initializeApp({ projectId: 'foundation-test' }, 'foundation-verifier-test');
  try {
    const verifier = new FirebaseIdentityVerifier(getAuth(app));
    const encode = (value: unknown) => Buffer.from(JSON.stringify(value)).toString('base64url');
    const foreign = [encode({ alg: 'RS256', kid: 'invalid-test-key' }), encode({
      aud: 'another-project', iss: 'https://securetoken.google.com/another-project',
      sub: 'test-user', iat: Math.floor(Date.now() / 1000), exp: Math.floor(Date.now() / 1000) + 600,
    }), 'invalid-signature'].join('.');
    // Rejection happens before certificate retrieval or credentialed user lookup.
    // These are invalid test strings, never issued tokens or a successful login.
    await assert.rejects(verifier.verify('not-a-jwt'), UnauthorizedException);
    await assert.rejects(verifier.verify(foreign), UnauthorizedException);
  } finally { await deleteApp(app); }
});
