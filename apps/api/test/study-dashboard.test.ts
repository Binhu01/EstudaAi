import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {StudyDirectory} from '../src/catalog/study-directory';
import {StudyCatalog} from '../src/catalog/study-catalog';
import {StudyHistoryService} from '../src/study/study.service';
import {studyFixture,userA,userB} from './helpers/study-fixture';
test('dashboard counts confirmed distinct questions, civil dates and current catalog only',async t=>{
 const f=await studyFixture();try{
  const goal=await f.service.ensureContext(userA,'freeStudy');
  await t.test('empty_dashboard_has_seven_zero_days',async()=>{
   const d=await f.service.readDashboard(userA,goal.id);
   assert.equal(d.activity.length,7);assert.equal(d.activity[0]!.date,'2026-09-25');assert.equal(d.resume,null);
   assert.ok(d.activity.every(v=>v.attempts===0&&v.differentQuestions===0&&v.correct===0));
  });
  const q=f.directory.find('porcentagem')!.topic.questions[0]!;
  const input={topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:(q.correctIndex+1)%4,source:'quiz' as const};
  await t.test('two_answers_same_question_count_one_daily_question',async()=>{
   await f.service.confirmAnswer(userA,goal.id,randomUUID(),input);
   await f.service.confirmAnswer(userA,goal.id,randomUUID(),{...input,optionIndex:q.correctIndex});
   const d=await f.service.readDashboard(userA,goal.id);
   assert.deepEqual(d.today,{date:'2026-10-01',differentQuestions:1,attempts:2,correct:1});
   assert.deepEqual(d.resume,{topicId:'porcentagem',contentVersion:1});assert.equal(d.pendingErrors,0);
   assert.equal(d.subjects.find(s=>s.id==='porcentagem')!.attempts,2);
  });
  await t.test('utc_midnight_keeps_sao_paulo_day and local midnight starts new day',async()=>{
   f.setTime('2026-10-02T00:01:00Z');await f.service.confirmAnswer(userA,goal.id,randomUUID(),input);
   assert.equal((await f.service.readDashboard(userA,goal.id)).today.date,'2026-10-01');
   f.setTime('2026-10-02T02:59:00Z');await f.service.confirmAnswer(userA,goal.id,randomUUID(),input);
   f.setTime('2026-10-02T03:00:00Z');await f.service.confirmAnswer(userA,goal.id,randomUUID(),input);
   const d=await f.service.readDashboard(userA,goal.id);
   assert.deepEqual(d.today,{date:'2026-10-02',differentQuestions:1,attempts:1,correct:0});
   assert.equal(d.activity[5]!.attempts,4);assert.equal(d.pendingErrors,1);
  });
  await t.test('same_qid_different_topics_are_distinct and tied times resume insertion order',async()=>{
   const free=StudyCatalog.fromJson({schemaVersion:1,catalogVersion:1,topics:f.directory.free.topics.map(topic=>topic.id==='interpretacao-texto'?{...topic,questions:topic.questions.map((old,i)=>i===0?{...old,id:q.id}:old)}:topic)});
   const s=new StudyHistoryService(f.database,new StudyDirectory(free,f.directory.contests),f.clock);
   await s.confirmAnswer(userA,goal.id,randomUUID(),{...input,topicId:'interpretacao-texto'});
   const d=await s.readDashboard(userA,goal.id);
   assert.equal(d.today.differentQuestions,2);assert.equal(d.today.attempts,2);assert.equal(d.resume!.topicId,'interpretacao-texto');
  });
  await t.test('old_version_not_in_dashboard and foreign goal cannot be read',async()=>{
   const s=new StudyHistoryService(f.database,new StudyDirectory({catalogVersion:2,topics:f.directory.free.topics,find:id=>f.directory.free.find(id)},f.directory.contests),f.clock);
   const d=await s.readDashboard(userA,goal.id);assert.equal(d.today.attempts,0);assert.equal(d.pendingErrors,0);assert.equal(d.resume,null);assert.deepEqual(d.subjects,[]);
   await assert.rejects(s.readDashboard(userB,goal.id),(e:any)=>e.getStatus()===404);
  });
 }finally{await f.db.close();}
});
test('error pages filter and retain old versions without duplicating tied rows',async()=>{
 const f=await studyFixture();try{
  const g=await f.service.ensureContext(userA,'freeStudy');
  for(const q of f.directory.find('porcentagem')!.topic.questions.slice(0,3))await f.service.confirmAnswer(userA,g.id,randomUUID(),{topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:(q.correctIndex+1)%4,source:'quiz'});
  const query={status:'pending' as const,subjectId:'porcentagem',limit:1};
  const ids:string[]=[];let cursor:string|undefined;
  do{const page=await f.service.listErrors(userA,g.id,{...query,cursor});ids.push(...page.items.map(v=>v.questionId));cursor=page.nextCursor??undefined;}while(cursor);
  assert.equal(ids.length,3);assert.equal(new Set(ids).size,3);
  const page=await f.service.listErrors(userA,g.id,query);
  await assert.rejects(f.service.listErrors(userA,g.id,{...query,status:'reviewed',cursor:page.nextCursor!}),(e:any)=>e.getStatus()===400);
  await assert.rejects(f.service.listErrors(userA,g.id,{...query,limit:51}),(e:any)=>e.getStatus()===400);
  const other=await f.service.ensureContext(userA,'bb2026');
  await assert.rejects(f.service.listErrors(userA,other.id,{...query,cursor:page.nextCursor!}),(e:any)=>e.getStatus()===400);
  assert.equal((await f.service.listErrors(userA,g.id,{...query,subjectId:'ecologia'})).items.length,0);
  const s=new StudyHistoryService(f.database,new StudyDirectory({catalogVersion:2,topics:f.directory.free.topics,find:id=>f.directory.free.find(id)},f.directory.contests),f.clock);
  assert.ok((await s.listErrors(userA,g.id,{...query,limit:20})).items.every(v=>v.contentStatus==='outdated'));
 }finally{await f.db.close();}
});
