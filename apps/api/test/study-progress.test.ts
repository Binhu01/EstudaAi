import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {StudyDirectory} from '../src/catalog/study-directory';
import {StudyHistoryService} from '../src/study/study.service';
import {studyFixture,userA,userB} from './helpers/study-fixture';

test('progress uses distinct current questions, latest answers and scoped confirmed review work',async()=>{
 const f=await studyFixture();try{
  const g=await f.service.ensureContext(userA,'freeStudy');
  const qs=f.directory.find('porcentagem')!.topic.questions;
  async function answer(date:string,index:number,correct:boolean,source:'quiz'|'review'='quiz'){
   f.setTime(date);const q=qs[index]!;
   await f.service.confirmAnswer(userA,g.id,randomUUID(),{topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:correct?q.correctIndex:(q.correctIndex+1)%4,source});
  }
  await answer('2026-09-20T12:00:00Z',0,false);
  await answer('2026-09-21T12:00:00Z',0,true,'review');
  await answer('2026-09-21T12:00:00Z',1,true,'review');
  await answer('2026-09-22T12:00:00Z',0,true,'review');
  await answer('2026-09-25T12:00:00Z',2,true);
  await answer('2026-09-26T12:00:00Z',1,false);
  await answer('2026-09-27T12:00:00Z',3,true);
  await answer('2026-10-10T12:00:00Z',4,true,'review');
  const foreign=await f.service.ensureContext(userB,'freeStudy');
  const q=qs[4]!;
  await f.service.confirmAnswer(userB,foreign.id,randomUUID(),{topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:q.correctIndex,source:'review'});
  f.setTime('2026-09-28T12:00:00Z');
  const d=await f.service.readDashboard(userA,g.id);
  const progress=(d as any).progress;
  assert.equal(progress?.practicedQuestions,4);
  assert.equal(progress?.catalogQuestions,f.directory.free.topics.reduce((n,t)=>n+t.questions.length,0));
  assert.equal(progress?.reviewedErrors,1);
  assert.equal(progress?.correctReviewQuestions,2);
  assert.equal(progress?.activeDays,6);
  assert.equal(progress?.currentStreak,3);
  assert.equal(progress?.bestStreak,3);
  assert.deepEqual((d.subjects.find(s=>s.id==='porcentagem') as any)?.progress,{practicedQuestions:4,latestCorrectQuestions:3,catalogQuestions:qs.length});
  const bb=await f.service.ensureContext(userA,'bb2026');
  assert.equal(((await f.service.readDashboard(userA,bb.id)) as any).progress?.practicedQuestions,0);
 }finally{await f.db.close();}
});

test('consistency follows Sao Paulo civil days, allows yesterday and expires after a missed day',async()=>{
 const f=await studyFixture();try{
  const g=await f.service.ensureContext(userA,'freeStudy');
  const q=f.directory.find('porcentagem')!.topic.questions[0]!;
  const input={topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:q.correctIndex,source:'quiz' as const};
  for(const date of ['2026-10-01T03:00:00Z','2026-10-02T02:59:00Z','2026-10-02T03:00:00Z']){
   f.setTime(date);await f.service.confirmAnswer(userA,g.id,randomUUID(),input);
  }
  for(const [date,current] of [['2026-10-03T02:59:00Z',2],['2026-10-03T03:00:00Z',2],['2026-10-04T03:00:00Z',0]] as const){
   f.setTime(date);const p=((await f.service.readDashboard(userA,g.id)) as any).progress;
   assert.equal(p?.activeDays,2);assert.equal(p?.currentStreak,current);assert.equal(p?.bestStreak,2);
  }
 }finally{await f.db.close();}
});

test('empty and changed catalog progress reports no invented practiced or reviewed questions',async()=>{
 const f=await studyFixture();try{
  const g=await f.service.ensureContext(userA,'freeStudy');
  const empty=((await f.service.readDashboard(userA,g.id)) as any).progress;
  assert.ok(empty?.catalogQuestions>0);
  assert.deepEqual({...empty,catalogQuestions:0},{practicedQuestions:0,catalogQuestions:0,reviewedErrors:0,correctReviewQuestions:0,activeDays:0,currentStreak:0,bestStreak:0});
  const q=f.directory.find('porcentagem')!.topic.questions[0]!;
  const input={topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:(q.correctIndex+1)%4,source:'quiz' as const};
  await f.service.confirmAnswer(userA,g.id,randomUUID(),input);
  await f.service.confirmAnswer(userA,g.id,randomUUID(),{...input,optionIndex:q.correctIndex,source:'review'});
  const changed=new StudyHistoryService(f.database,new StudyDirectory({catalogVersion:2,topics:f.directory.free.topics,find:id=>f.directory.free.find(id)},f.directory.contests),f.clock);
  const d=await changed.readDashboard(userA,g.id);
  const p=(d as any).progress;
  assert.deepEqual({...p,catalogQuestions:0},{practicedQuestions:0,catalogQuestions:0,reviewedErrors:0,correctReviewQuestions:0,activeDays:0,currentStreak:0,bestStreak:0});
  assert.deepEqual(d.subjects,[]);
 }finally{await f.db.close();}
});

test('dashboard error counts use the same cutoff before future wrong answers become current',async()=>{
 const f=await studyFixture();try{
  const g=await f.service.ensureContext(userA,'freeStudy');
  const qs=f.directory.find('porcentagem')!.topic.questions;
  const input=(index:number,correct:boolean,source:'quiz'|'review'='quiz')=>{
   const q=qs[index]!;
   return {topicId:'porcentagem',contentVersion:1,questionId:q.id,optionIndex:correct?q.correctIndex:(q.correctIndex+1)%4,source};
  };
  f.setTime('2026-10-01T12:00:00Z');
  await f.service.confirmAnswer(userA,g.id,randomUUID(),input(0,false));
  await f.service.confirmAnswer(userA,g.id,randomUUID(),input(0,true,'review'));
  f.setTime('2026-10-10T12:00:00Z');
  await f.service.confirmAnswer(userA,g.id,randomUUID(),input(0,false));
  await f.service.confirmAnswer(userA,g.id,randomUUID(),input(1,false));
  f.setTime('2026-10-02T12:00:00Z');
  const before=await f.service.readDashboard(userA,g.id);
  assert.equal(before.pendingErrors,0);
  assert.equal(before.progress?.reviewedErrors,1);
  assert.equal(before.progress?.practicedQuestions,1);
  assert.equal(before.subjects[0]!.progress?.latestCorrectQuestions,1);
  f.setTime('2026-10-10T12:00:00Z');
  const current=await f.service.readDashboard(userA,g.id);
  assert.equal(current.pendingErrors,2);
  assert.equal(current.progress?.reviewedErrors,0);
  assert.equal(current.progress?.practicedQuestions,2);
  assert.equal(current.subjects[0]!.progress?.latestCorrectQuestions,0);
 }finally{await f.db.close();}
});
