import { Prisma } from '@prisma/client';
export type Goal = Readonly<{ id: string; userId: string; name: string }>;
export interface SqlExecutor { query<T>(statement: Prisma.Sql): Promise<T[]>; }
export class GoalRepository {
  constructor(private readonly database: SqlExecutor) {}
  async find(userId: string, goalId: string): Promise<Goal | null> {
    const rows = await this.database.query<Goal>(Prisma.sql`
      SELECT "id", "userId", "name" FROM "StudyGoal"
      WHERE "userId" = ${userId}::uuid AND "id" = ${goalId}::uuid LIMIT 1`);
    return rows[0] ?? null;
  }
  async rename(userId: string, goalId: string, name: string): Promise<Goal | null> {
    const normalized = name.trim();
    if (!normalized || normalized.length > 120) throw new Error('Nome de meta inválido.');
    const rows = await this.database.query<Goal>(Prisma.sql`
      UPDATE "StudyGoal" SET "name" = ${normalized}, "updatedAt" = CURRENT_TIMESTAMP
      WHERE "userId" = ${userId}::uuid AND "id" = ${goalId}::uuid
      RETURNING "id", "userId", "name"`);
    return rows[0] ?? null;
  }
}
