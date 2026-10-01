import { randomUUID } from 'node:crypto';
import { Prisma } from '@prisma/client';
import { SqlTransactionProvider } from '../database/transaction';
import { DailyQuotaExceeded } from '../errors';
export interface QuotaReservation { id:string; userId:string; dayUTC:string; remaining:number; resetAt:string }
export interface SteveQuota {
  reserve(userId:string, now:Date):Promise<QuotaReservation>;
  releaseUnsent(id:string, userId:string):Promise<boolean>;
}
export class QuotaRepository implements SteveQuota {
  constructor(private readonly provider:SqlTransactionProvider, private readonly limits:{userDaily:number;globalDaily:number}) {
    if (!Number.isSafeInteger(limits.userDaily) || limits.userDaily < 1 || !Number.isSafeInteger(limits.globalDaily) || limits.globalDaily < limits.userDaily) throw new Error('Invalid quota limits');
  }
  async reserve(userId:string, now:Date):Promise<QuotaReservation> {
    const dayUTC = now.toISOString().slice(0,10);
    const resetAt = new Date(Date.parse(dayUTC+'T00:00:00Z')+86_400_000).toISOString();
    const userScope = 'user:'+userId;
    return this.provider.transaction(async tx => {
      await tx.query(Prisma.sql`INSERT INTO "AiDailyUsage" ("dayUTC",scope) VALUES (${dayUTC}::date,'global') ON CONFLICT DO NOTHING RETURNING count`);
      const global = (await tx.query<{count:number}>(Prisma.sql`SELECT count FROM "AiDailyUsage" WHERE "dayUTC"=${dayUTC}::date AND scope='global' FOR UPDATE`))[0]!;
      if (global.count >= this.limits.globalDaily) throw new DailyQuotaExceeded(resetAt);
      await tx.query(Prisma.sql`INSERT INTO "AiDailyUsage" ("dayUTC",scope) VALUES (${dayUTC}::date,${userScope}) ON CONFLICT DO NOTHING RETURNING count`);
      const user = (await tx.query<{count:number}>(Prisma.sql`SELECT count FROM "AiDailyUsage" WHERE "dayUTC"=${dayUTC}::date AND scope=${userScope} FOR UPDATE`))[0]!;
      if (user.count >= this.limits.userDaily) throw new DailyQuotaExceeded(resetAt);
      await tx.query(Prisma.sql`UPDATE "AiDailyUsage" SET count=count+1 WHERE "dayUTC"=${dayUTC}::date AND scope IN ('global',${userScope}) RETURNING count`);
      const id = randomUUID();
      await tx.query(Prisma.sql`INSERT INTO "AiQuotaReservation" (id,"userId","dayUTC") VALUES (${id}::uuid,${userId}::uuid,${dayUTC}::date) RETURNING id`);
      return {id,userId,dayUTC,remaining:this.limits.userDaily-user.count-1,resetAt};
    });
  }
  async releaseUnsent(id:string,userId:string):Promise<boolean> {
    return this.provider.transaction(async tx => {
      const row = (await tx.query<{day:string}>(Prisma.sql`SELECT "dayUTC"::text AS day FROM "AiQuotaReservation" WHERE id=${id}::uuid AND "userId"=${userId}::uuid`))[0];
      if (!row) return false;
      const userScope = 'user:'+userId;
      await tx.query(Prisma.sql`SELECT count FROM "AiDailyUsage" WHERE "dayUTC"=${row.day}::date AND scope='global' FOR UPDATE`);
      await tx.query(Prisma.sql`SELECT count FROM "AiDailyUsage" WHERE "dayUTC"=${row.day}::date AND scope=${userScope} FOR UPDATE`);
      const changed = await tx.query(Prisma.sql`UPDATE "AiQuotaReservation" SET "releasedAt"=CURRENT_TIMESTAMP WHERE id=${id}::uuid AND "userId"=${userId}::uuid AND "releasedAt" IS NULL RETURNING id`);
      if (!changed.length) return false;
      await tx.query(Prisma.sql`UPDATE "AiDailyUsage" SET count=count-1 WHERE "dayUTC"=${row.day}::date AND scope IN ('global',${userScope}) RETURNING count`);
      return true;
    });
  }
}
