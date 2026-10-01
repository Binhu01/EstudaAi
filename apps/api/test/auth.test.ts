import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ServiceUnavailableException } from '@nestjs/common';
import { FirebaseRestAuth } from '../src/auth/firebase-rest.auth';
import { createApp } from '../src/app';

const session = { idToken: 'ID.TOKEN.TEST', refreshToken: 'REFRESH.TEST', expiresInSeconds: 3600 };
test('Firebase gateway verifies each ID token and preserves password spaces', async () => {
  let verifications = 0; const calls: {url:string; body:string}[] = [];
  const gateway = new FirebaseRestAuth('test-key', {async verify(token) { assert.equal(token, session.idToken); verifications++; return {externalId:'verified'}; }},
    async (url, options) => {
      calls.push({url: String(url), body: String(options?.body)});
      assert.equal(options?.redirect, 'error');
      return Response.json(String(url).includes('securetoken') ? {id_token:session.idToken, refresh_token:session.refreshToken, expires_in:'3600'} : {idToken:session.idToken,refreshToken:session.refreshToken,expiresIn:'3600'});
    });
  assert.deepEqual(await gateway.register('a@example.com', ' pass word '), session);
  assert.deepEqual(await gateway.login('a@example.com', ' pass word '), session);
  assert.deepEqual(await gateway.refresh('refresh token'), session);
  assert.equal(verifications, 3);
  assert.equal(JSON.parse(calls[0]!.body).password, ' pass word ');
  assert.ok(calls[2]!.body.includes('refresh_token=refresh+token'));
});
test('absent configuration, foreign tokens and upstream failures remain safe', async () => {
  let calls = 0;
  const transport: typeof fetch = async () => { calls++; return Response.json({idToken:session.idToken,refreshToken:session.refreshToken,expiresIn:'3600'}); };
  const missing = new FirebaseRestAuth(undefined, {async verify() { throw Error('SECRET'); }}, transport);
  await assert.rejects(missing.login('a@example.com','password'), (e: any) => e.getStatus() === 503);
  assert.equal(calls, 0);
  const foreign = new FirebaseRestAuth('key', {async verify() { throw Error('SECRET foreign project'); }}, transport);
  await assert.rejects(foreign.login('a@example.com','password'), (e: any) => e.getStatus() === 401 && !e.message.includes('SECRET'));
  const unavailable = new FirebaseRestAuth('key', {async verify() { throw new ServiceUnavailableException(); }}, transport);
  await assert.rejects(unavailable.login('a@example.com','password'), (e: any) => e.getStatus() === 503);
  const reset = new FirebaseRestAuth('key', {async verify() { throw Error('must not verify reset'); }}, async () => Response.json({error:{message:'EMAIL_NOT_FOUND SECRET'}}, {status:400}));
  await reset.resetPassword('missing@example.com');
});
async function fixture() {
  const passwords: string[] = [];
  const app = await createApp({
    identity: {async verify() { return {externalId:'verified'}; }},
    users: {async resolve() { return {id:'internal'}; }}, ready:async()=>true, origins:[],
    auth: {
      async login(_email, password) { passwords.push(password); return session; },
      async register(_email, password) { passwords.push(password); return session; },
      async refresh() { return session; }, async resetPassword() {},
    },
  });
  await app.listen(0,'127.0.0.1');
  return {app, passwords, post: async (route: string, body: object) => fetch(await app.getUrl() + '/v1/auth/' + route, {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)})};
}
test('public authentication has a shared IP budget and a separate refresh budget', async () => {
  const f = await fixture();
  try {
    for (let i=0;i<10;i++) {
      const route = ['login','register','password-reset'][i%3]!;
      assert.equal((await f.post(route, route === 'password-reset' ? {email:'a@example.com'} : {email:'a@example.com',password:' pass word '})).status, 200);
    }
    assert.equal((await f.post('login',{email:'a@example.com',password:'password'})).status,429);
    for (let i=0;i<60;i++) assert.equal((await f.post('refresh',{refreshToken:'REFRESH'})).status,200);
    assert.equal((await f.post('refresh',{refreshToken:'REFRESH'})).status,429);
    assert.ok(f.passwords.every(p=>p===' pass word '));
  } finally { await f.app.close(); }
});
test('authentication rejects untrusted fields and invalid signup passwords', async () => {
  const f = await fixture();
  try {
    for (const body of [{email:'a@example.com',password:'        '},{email:'a@example.com',password:'short'},{email:'a@example.com',password:'password',userId:'attacker'}]) {
      const res = await f.post('register',body);
      assert.equal(res.status,400);
      assert.ok(!(await res.text()).includes('attacker'));
    }
  } finally { await f.app.close(); }
});
