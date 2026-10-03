import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {Prisma} from '@prisma/client';
import {StudyDirectory} from '../src/catalog/study-directory';
import {StudyHistoryService} from '../src/study/study.service';
import {readTestMigrations} from './helpers/test-migrations';
import {studyFixture,userA,userB} from './helpers/study-fixture';
const status=(value:number)=>(e:any)=>e.getStatus?.()===value;

test('study history preserves ownership, idempotence and error transitions',async t=>{
  const f=await studyFixture();
  try {
    const input={topicId:'porcentagem',contentVersion:1,questionId:f.directory.find('porcentagem')!.topic.questions[0]!.id,optionIndex:0,source:'quiz' as const};
    const correct=f.directory.find('porcentagem')!.topic.questions[0]!.correctIndex;
    const wrong={...input,optionIndex:(correct+1)%4};
    const a=await f.service.ensureContext(userA,'freeStudy');
    const bb=await f.service.ensureContext(userA,'bb2026');
    await t.test('ensure_twice_returns_same_goal and scopes remain separate',async()=>{
      assert.equal(a.dailyTarget,10); assert.equal(a.timezone,'America/Sao_Paulo');
      assert.equal((await f.service.ensureContext(userA,'freeStudy')).id,a.id);
      assert.notEqual(bb.id,a.id);
      assert.notEqual((await f.service.ensureContext(userB,'freeStudy')).id,a.id);
    });
    await t.test('owner_cannot_write_other_goal and scope is validated',async()=>{
      await assert.rejects(f.service.confirmAnswer(userB,a.id,randomUUID(),wrong),status(404));
      await assert.rejects(f.service.confirmAnswer(userA,bb.id,randomUUID(),wrong),status(400));
      for(const optionIndex of [-1,4,1.5])await assert.rejects(f.service.confirmAnswer(userA,a.id,randomUUID(),{...wrong,optionIndex}),status(400));
    });
    const id=randomUUID();
    await t.test('same_uuid_same_body_returns_original and incompatible intent conflicts',async()=>{
      const first=await f.service.confirmAnswer(userA,a.id,id,wrong);
      assert.equal(first.correct,false); assert.equal(first.receivedAt,'2026-10-01T12:00:00.000Z');
      f.setTime('2026-10-02T12:00:00Z');
      assert.deepEqual(await f.service.confirmAnswer(userA,a.id,id,wrong),first);
      await assert.rejects(f.service.confirmAnswer(userA,a.id,id,{...input,optionIndex:correct}),status(409));
      await assert.rejects(f.service.confirmAnswer(userA,bb.id,id,wrong),status(409));
      assert.equal((await f.db.query<{n:number}>('SELECT count(*)::int n FROM "StudyAnswer"')).rows[0]!.n,1);
    });
    await t.test('wrong_correct_wrong_reopens_error',async()=>{
      let rows=(await f.db.query<any>('SELECT * FROM "StudyQuestionError"')).rows;
      assert.equal(rows[0].status,'pending'); assert.equal(rows[0].wrongCount,1);
      await f.service.confirmAnswer(userA,a.id,randomUUID(),{...input,optionIndex:correct,source:'review'});
      assert.equal((await f.db.query<any>('SELECT * FROM "StudyQuestionError"')).rows[0].status,'reviewed');
      await f.service.confirmAnswer(userA,a.id,randomUUID(),wrong);
      rows=(await f.db.query<any>('SELECT * FROM "StudyQuestionError"')).rows;
      assert.equal(rows[0].status,'pending'); assert.equal(rows[0].wrongCount,2);
      assert.equal(rows[0].firstWrongAt.toISOString(),'2026-10-01T12:00:00.000Z');
    });
    await t.test('confirmed_retry_survives_catalog_update but new_old_version_is_rejected',async()=>{
      const updated=new StudyDirectory({catalogVersion:2,topics:f.directory.free.topics,find:id=>f.directory.free.find(id)},f.directory.contests);
      const s=new StudyHistoryService(f.database,updated,f.clock);
      const before=(await f.db.query('SELECT * FROM "StudyAnswer"')).rows.length;
      assert.equal((await s.confirmAnswer(userA,a.id,id,wrong)).receivedAt,'2026-10-01T12:00:00.000Z');
      await assert.rejects(s.confirmAnswer(userA,a.id,randomUUID(),wrong),status(409));
      assert.equal((await f.db.query('SELECT * FROM "StudyAnswer"')).rows.length,before);
    });
    await t.test('error_update_failure_rolls_back_answer',async()=>{
      const broken={query:f.database.query,transaction:<T>(work:any)=>f.database.transaction(tx=>work({query<R>(sql:Prisma.Sql){if(sql.text.includes('INSERT INTO "StudyQuestionError"'))throw Error('deliberate failure');return tx.query<R>(sql);}})) as Promise<T>};
      const s=new StudyHistoryService(broken,f.directory,f.clock);
      const before=(await f.db.query('SELECT * FROM "StudyAnswer"')).rows.length;
      await assert.rejects(s.confirmAnswer(userA,a.id,randomUUID(),wrong));
      assert.equal((await f.db.query('SELECT * FROM "StudyAnswer"')).rows.length,before);
    });
    await t.test('daily target accepts only 5 10 20 and preserves ownership',async()=>{
      assert.equal((await f.service.setDailyTarget(userA,a.id,5)).dailyTarget,5);
      await assert.rejects(f.service.setDailyTarget(userB,a.id,20),status(404));
      await assert.rejects(f.service.setDailyTarget(userA,a.id,7 as any),status(400));
    });
  }finally{await f.db.close();}
});

test('study migration preserves legacy goals without assigning an internal scope',async()=>{
  const db=new PGlite();
  try{
    const migrations=await readTestMigrations();
    for(const m of migrations.filter(m=>m.name<'202610020001'))await db.exec(m.sql);
    await db.query('INSERT INTO "User" (id,"externalId") VALUES ($1,$2)',[userA,'legacy']);
    await db.query('INSERT INTO "StudyGoal" (id,"userId",name,category,"updatedAt") VALUES ($1,$2,$3,$4,now())',[userB,userA,'Minha meta antiga','school']);
    assert.ok(migrations.some(m=>m.name==='202610020001_study_history'));
    for(const m of migrations.filter(m=>m.name>='202610020001'))await db.exec(m.sql);
    const row=(await db.query<any>('SELECT * FROM "StudyGoal"')).rows[0];
    assert.equal(row.id,userB);assert.equal(row.name,'Minha meta antiga');assert.equal(row.contextKey,null);assert.equal(row.dailyTarget,10);
  }finally{await db.close();}
});
