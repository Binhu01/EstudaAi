import { PGlite } from '@electric-sql/pglite';
import { Prisma } from '@prisma/client';
import { loadStudyDirectory } from '../../src/catalog/study-directory';
import { SqlExecutor } from '../../src/goals/goal.repository';
import { SqlTransactionProvider } from '../../src/database/transaction';
import { StudyHistoryService } from '../../src/study/study.service';
import { readTestMigrations } from './test-migrations';
export const userA='11111111-1111-4111-8111-111111111111', userB='22222222-2222-4222-8222-222222222222';
export async function studyFixture() {
  const db=new PGlite();
  for(const m of await readTestMigrations()) await db.exec(m.sql);
  await db.query('INSERT INTO "User" (id,"externalId") VALUES ($1,$2),($3,$4)',[userA,'a',userB,'b']);
  const database:SqlExecutor & SqlTransactionProvider={
    async query<T>(sql:Prisma.Sql){return (await db.query<T>(sql.text,sql.values)).rows;},
    transaction<T>(work:(tx:SqlExecutor)=>Promise<T>){return db.transaction(tx=>work({async query<R>(sql:Prisma.Sql){return (await tx.query<R>(sql.text,sql.values)).rows;}}));},
  };
  let now=new Date('2026-10-01T12:00:00Z');
  const directory=loadStudyDirectory();
  const service=new StudyHistoryService(database,directory,()=>now);
  return {db,database,directory,service,setTime(value:string){now=new Date(value);},clock:()=>now};
}
