import { readdir, readFile } from 'node:fs/promises';
export async function readTestMigrations(): Promise<{name:string;sql:string}[]> {
  const path='prisma/migrations';
  const entries=await readdir(path,{withFileTypes:true});
  return Promise.all(entries.filter(e=>e.isDirectory()).map(e=>e.name).sort().map(async name=>({name,sql:await readFile(`${path}/${name}/migration.sql`,'utf8')})));
}
