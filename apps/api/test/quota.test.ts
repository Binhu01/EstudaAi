import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
import { Prisma } from '@prisma/client';
import { SqlTransactionProvider } from '../src/database/transaction';
import { QuotaRepository } from '../src/steve/quota.repository';
const owner = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
const now = new Date('2026-10-01T23:59:00Z');
async function fixture(limits = {userDaily:2,globalDaily:3}) {
  const db = new PGlite();
  for (const name of ['202609290001_foundation','202609300001_ai_quotas']) await db.exec(await readFile('prisma/migrations/'+name+'/migration.sql','utf8'));
  await db.query('INSERT INTO "User" (id,"externalId") VALUES ($1,$2),($3,$4)',[owner,'owner',other,'other']);
  const provider: SqlTransactionProvider = {async transaction<T>(work: (tx: {query<R>(s:Prisma.Sql):Promise<R[]>}) => Promise<T>) {
    return db.transaction(async tx => work({async query<R>(s:Prisma.Sql) { return (await tx.query<R>(s.text,s.values)).rows; }}));
  }};
  return {db,provider,quota:new QuotaRepository(provider,limits)};
}
test('quota increments both buckets atomically and releases once on its original day', async () => {
  const f = await fixture();
  try {
    const first = await f.quota.reserve(owner,now);
    assert.equal(first.remaining,1);
    assert.equal(first.resetAt,'2026-10-02T00:00:00.000Z');
    await f.quota.reserve(owner,now);
    await assert.rejects(f.quota.reserve(owner,now),(e:any)=>e.getStatus()===429);
    assert.equal(await f.quota.releaseUnsent(first.id,other),false);
    await f.quota.reserve(owner,new Date('2026-10-02T00:01:00Z'));
    assert.equal(await f.quota.releaseUnsent(first.id,owner),true);
    assert.equal(await f.quota.releaseUnsent(first.id,owner),false);
    const counts = (await f.db.query<{day:string;scope:string;count:number}>('SELECT "dayUTC"::text AS day,scope,count FROM "AiDailyUsage"')).rows;
    assert.equal(counts.find(r=>r.day==='2026-10-01'&&r.scope==='global')!.count,1);
    assert.equal(counts.find(r=>r.day==='2026-10-02'&&r.scope==='global')!.count,1);
  } finally { await f.db.close(); }
});
test('global limit and missing owners never consume a partial user/global allocation', async () => {
  const f = await fixture({userDaily:1,globalDaily:1});
  try {
    await assert.rejects(f.quota.reserve('33333333-3333-4333-8333-333333333333',now));
    assert.equal((await f.db.query('SELECT * FROM "AiDailyUsage"')).rows.length,0);
    await f.quota.reserve(owner,now);
    await assert.rejects(f.quota.reserve(other,now));
    assert.equal((await f.db.query("SELECT * FROM \"AiDailyUsage\" WHERE scope=$1",['user:'+other])).rows.length,0);
    await assert.rejects(f.db.query('UPDATE "AiDailyUsage" SET count=-1'));
  } finally { await f.db.close(); }
});
test('an error inserting the reservation rolls back both increments', async () => {
  const f = await fixture();
  try {
    const broken: SqlTransactionProvider = {transaction: work => f.provider.transaction(tx => work({async query<T>(s:Prisma.Sql) {
      if (s.text.includes('INSERT INTO "AiQuotaReservation"')) throw Error('deliberate test failure');
      return tx.query<T>(s);
    }}))};
    await assert.rejects(new QuotaRepository(broken,{userDaily:2,globalDaily:3}).reserve(owner,now));
    assert.equal((await f.db.query('SELECT * FROM "AiDailyUsage"')).rows.length,0);
  } finally { await f.db.close(); }
});
