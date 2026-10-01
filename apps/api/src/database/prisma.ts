import { PrismaClient, Prisma } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { UserRepository } from '../contracts';
import { SqlExecutor } from '../goals/goal.repository';

export class PrismaDatabase implements UserRepository, SqlExecutor {
  readonly client: PrismaClient;
  constructor(databaseUrl: string) {
    this.client = new PrismaClient({ adapter: new PrismaPg({ connectionString: databaseUrl, max: 10, connectionTimeoutMillis: 5000 }) });
  }
  async resolve(externalId: string) {
    return this.client.user.upsert({ where: { externalId }, create: { externalId }, update: {}, select: { id: true } });
  }
  query<T>(statement: Prisma.Sql): Promise<T[]> { return this.client.$queryRaw<T[]>(statement); }
  async ready() {
    try { await this.client.$queryRaw`SELECT 1`; return true; } catch { return false; }
  }
  async close() { await this.client.$disconnect(); }
}
