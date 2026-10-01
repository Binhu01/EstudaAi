import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Pool } from 'pg';
import { Prisma } from '@prisma/client';
import { PrismaDatabase } from '../../src/database/prisma';
import { QuotaRepository } from '../../src/steve/quota.repository';
import { SqlTransactionProvider } from '../../src/database/transaction';

test('real PostgreSQL preserves quota under independent concurrent connections', async () => {
  const url = process.env.TEST_DATABASE_URL;
  if (!url || new URL(url).pathname !== '/estuda_ai_integration_test') throw Error('A dedicated TEST_DATABASE_URL is required.');
  const setup = new Pool({connectionString:url,max:1});
  const a = new PrismaDatabase(url), b = new PrismaDatabase(url);
  try {
    const existing = await setup.query("SELECT tablename FROM pg_tables WHERE schemaname='public'");
    if (existing.rows.length) throw Error('Integration database must be new and empty; refusing to change existing data.');
    for (const name of ['202609290001_foundation','202609300001_ai_quotas']) await setup.query(await readFile('prisma/migrations/'+name+'/migration.sql','utf8'));
    const user = await a.resolve('integration-owner'), other = await b.resolve('integration-other');
    const first = new QuotaRepository(a,{userDaily:10,globalDaily:1000});
    const second = new QuotaRepository(b,{userDaily:10,globalDaily:1000});
    const day = new Date('2026-10-01T12:00:00Z');
    const attempts = await Promise.allSettled(Array.from({length:20},(_,i)=>(i%2?first:second).reserve(user.id,day)));
    assert.equal(attempts.filter(r=>r.status==='fulfilled').length,10);
    assert.equal(attempts.filter(r=>r.status==='rejected'&&(r.reason as any).getStatus()===429).length,10);
    const counts = await a.query<{scope:string;count:number}>(Prisma.sql`SELECT scope,count FROM "AiDailyUsage" WHERE "dayUTC"='2026-10-01'`);
    assert.equal(counts.find(r=>r.scope==='global')!.count,10);
    assert.equal(counts.find(r=>r.scope==='user:'+user.id)!.count,10);

    const nextDay = new Date('2026-10-02T12:00:00Z');
    const globalA = new QuotaRepository(a,{userDaily:1,globalDaily:1}), globalB = new QuotaRepository(b,{userDaily:1,globalDaily:1});
    const last = await Promise.allSettled([globalA.reserve(user.id,nextDay),globalB.reserve(other.id,nextDay)]);
    assert.equal(last.filter(r=>r.status==='fulfilled').length,1);
    const winning = last.find(r=>r.status==='fulfilled')!;
    assert.equal(winning.status,'fulfilled');
    if (winning.status !== 'fulfilled') throw Error('No winner');
    const refunds = await Promise.all([globalA.releaseUnsent(winning.value.id,winning.value.userId),globalB.releaseUnsent(winning.value.id,winning.value.userId)]);
    assert.deepEqual(refunds.sort(),[false,true]);
    assert.equal((await a.query<{count:number}>(Prisma.sql`SELECT count FROM "AiDailyUsage" WHERE "dayUTC"='2026-10-02' AND scope='global'`))[0]!.count,0);

    const broken: SqlTransactionProvider = {transaction: work => a.transaction(tx => work({async query<T>(sql:Prisma.Sql) {
      if (sql.text.includes('INSERT INTO "AiQuotaReservation"')) throw Error('deliberate integration failure');
      return tx.query<T>(sql);
    }}))};
    await assert.rejects(new QuotaRepository(broken,{userDaily:10,globalDaily:1000}).reserve(user.id,new Date('2026-10-03T12:00:00Z')));
    assert.equal((await a.query(Prisma.sql`SELECT count FROM "AiDailyUsage" WHERE "dayUTC"='2026-10-03'`)).length,0);
    const continued = await first.reserve(user.id,new Date('2026-10-04T00:01:00Z'));
    assert.equal(await second.releaseUnsent(continued.id,user.id),true);
    assert.equal(await first.releaseUnsent(continued.id,user.id),false);
  } finally { await a.close(); await b.close(); await setup.end(); }
});
