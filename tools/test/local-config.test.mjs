import test from 'node:test';
import assert from 'node:assert/strict';
import {checkLocalConfig} from '../check-local-config.mjs';
import {verifyLiveStudy} from '../verify-live-study.mjs';
const env={DATABASE_URL:'postgresql://test:secret-sentinel@127.0.0.1:55433/estuda_ai',FIREBASE_PROJECT_ID:'estuda-test',FIREBASE_WEB_API_KEY:'AIza-test-sentinel-123456789012345678901',GOOGLE_APPLICATION_CREDENTIALS:'C:/private/admin.json',OPENAI_API_KEY:'sk-test-secret-sentinel-123456789012345',STEVE_MODEL:'gpt-4.1-mini',CORS_ORIGINS:'http://127.0.0.1:4173,http://127.0.0.1:4174'};
const probe={database:async()=>({connected:true,schema:true}),firebase:async()=>({type:'service_account',project_id:'estuda-test',private_key:'-----BEGIN PRIVATE KEY-----\nsecret-sentinel\n-----END PRIVATE KEY-----\n',client_email:'admin@estuda-test.iam.gserviceaccount.com'})};
test('missing services do not claim readiness',async()=>{const r=await checkLocalConfig({},probe);assert.equal(r.firebase.status,'missing');assert.equal(r.steve.status,'missing');assert.equal(r.database.status,'missing');assert.equal(r.readyForLiveTest,false);});
test('presence is configured rather than provider verification',async()=>{const r=await checkLocalConfig(env,probe);assert.equal(r.database.status,'verified');assert.equal(r.cors.status,'verified');assert.equal(r.firebase.status,'configured');assert.equal(r.steve.status,'configured');assert.equal(r.readyForLiveTest,true);assert.ok(!JSON.stringify(r).includes('sentinel'));});
test('select one with absent schema cannot certify database',async()=>{const r=await checkLocalConfig(env,{...probe,database:async()=>({connected:true,schema:false})});assert.equal(r.database.status,'invalid');assert.equal(r.readyForLiveTest,false);});
test('foreign Firebase project and malformed model or keys refused',async()=>{
 assert.equal((await checkLocalConfig(env,{...probe,firebase:async()=>({...await probe.firebase(),project_id:'other-project'})})).firebase.status,'invalid');
 for(const change of [{STEVE_MODEL:'bad model'},{OPENAI_API_KEY:'bad key'},{FIREBASE_WEB_API_KEY:'bad key'}])assert.equal((await checkLocalConfig({...env,...change},probe))[change.FIREBASE_WEB_API_KEY?'firebase':'steve'].status,'invalid');
});
test('preview 4174 missing from CORS is reported',async()=>{const r=await checkLocalConfig({...env,CORS_ORIGINS:'http://127.0.0.1:4173'},probe);assert.equal(r.cors.status,'invalid');assert.equal(r.readyForLiveTest,false);assert.ok(r.cors.issues.some(s=>s.includes('4174')));});
test('probe failures never echo secrets or exception strings',async()=>{const fail=async()=>{throw new Error('secret-sentinel '+env.DATABASE_URL+env.OPENAI_API_KEY);};const r=await checkLocalConfig(env,{database:fail,firebase:fail});assert.equal(r.readyForLiveTest,false);assert.ok(!JSON.stringify(r).includes('sentinel'));});
test('live validation pending never creates accounts or calls external services',async()=>{let calls=0;const report=await verifyLiveStudy({env:{},probe,request:async()=>{calls++;throw new Error('must not run');}});assert.equal(report.status,'pending');assert.equal(calls,0);assert.equal(report.checks.length,0);});
