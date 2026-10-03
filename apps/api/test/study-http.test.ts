import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {createApp,createOpenApi} from '../src/app';
import {studyFixture,userA,userB} from './helpers/study-fixture';
test('private study HTTP rejects extra claims and validates owner and catalog',async()=>{
 const f=await studyFixture();
 const app=await createApp(Object.assign({identity:{async verify(token:string){return {externalId:token};}},users:{async resolve(id:string){return {id:id==='a'?userA:userB};}},ready:async()=>true,origins:[],rateLimit:500},{study:f.service}));
 await app.listen(0,'127.0.0.1');const base=await app.getUrl();
 const call=(path:string,method='GET',body?:unknown,token='a')=>fetch(base+path,{method,headers:{...(token?{authorization:'Bearer '+token}:{}),...(body!==undefined?{'content-type':'application/json'}:{})},...(body!==undefined?{body:JSON.stringify(body)}:{})});
 try{
  assert.equal((await call('/v1/study-contexts/freeStudy/ensure','POST',{})).status,200);
  const goal=await(await call('/v1/study-contexts/freeStudy/ensure','POST',{})).json() as any;
  assert.equal((await call('/v1/study-contexts/freeStudy/ensure','POST',{userId:userB})).status,400);
  assert.equal((await call('/v1/study-contexts/missing/ensure','POST',{})).status,400);
  const path='/v1/goals/'+goal.id;
  assert.equal((await call(path+'/dashboard','GET',undefined,'')).status,401);
  assert.equal((await call(path+'/dashboard','GET',undefined,'b')).status,404);
  assert.equal((await call('/v1/goals/not-uuid/dashboard')).status,400);
  assert.equal((await call(path+'/daily-target','PATCH',{dailyTarget:5})).status,200);
  assert.equal((await call(path+'/daily-target','PATCH',{dailyTarget:7})).status,400);
  const q=f.directory.find('porcentagem')!.topic.questions[0]!;
  const input={topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:0,source:'quiz'};
  const answer=path+'/answers/'+randomUUID();
  for(const extra of [{correct:true},{userId:userB},{receivedAt:'2026-10-02'}, {points:700}])assert.equal((await call(answer,'PUT',{...input,...extra})).status,400);
  assert.equal((await call(answer,'PUT',input)).status,200);
  const conflict=await call(answer,'PUT',{...input,optionIndex:1});assert.equal(conflict.status,409);assert.equal((await conflict.json() as any).code,'CONFLICT');
  const updated=await call(path+'/answers/'+randomUUID(),'PUT',{...input,contentVersion:2});assert.equal(updated.status,409);assert.equal((await updated.json() as any).code,'CONTENT_CHANGED');
  assert.equal((await call(path+'/dashboard')).status,200);
  assert.equal((await call(path+'/errors')).status,200);
  for(const query of ['?limit=51','?limit=-1','?limit=1.5','?status=mastered','?userId='+userA,'?cursor=bad'])assert.equal((await call(path+'/errors'+query)).status,400);
  const api=createOpenApi(app,f.directory.topicIds);
  assert.ok(api.paths['/v1/goals/{goalId}/dashboard']);
 }finally{await app.close();await f.db.close();}
});
test('missing history returns safe service unavailable',async()=>{
 const app=await createApp({identity:{async verify(){return {externalId:'a'};}},users:{async resolve(){return {id:userA};}},ready:async()=>true,origins:[]});
 await app.listen(0,'127.0.0.1');try{
  const r=await fetch((await app.getUrl())+'/v1/study-contexts/freeStudy/ensure',{method:'POST',headers:{authorization:'Bearer a','content-type':'application/json'},body:'{}'});
  assert.equal(r.status,503);assert.equal((await r.json() as any).code,'UNAVAILABLE');
 }finally{await app.close();}
});
