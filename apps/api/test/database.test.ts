import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
import { Prisma } from '@prisma/client';
import { GoalRepository } from '../src/goals/goal.repository';

const owner = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
const goal1 = '33333333-3333-4333-8333-333333333333';
const goal2 = '44444444-4444-4444-8444-444444444444';
async function fixture() {
  const db = new PGlite();
  await db.exec(await readFile('prisma/migrations/202609290001_foundation/migration.sql', 'utf8'));
  await db.query('INSERT INTO "User" (id, "externalId") VALUES ($1, $2), ($3, $4)', [owner, 'owner', other, 'other']);
  await db.query('INSERT INTO "StudyGoal" (id, "userId", name, category, "updatedAt") VALUES ($1, $2, $3, $4, now()), ($5, $2, $6, $4, now())', [goal1, owner, 'Concurso', 'CONCURSO', goal2, 'Faculdade']);
  const repository = new GoalRepository({ async query<T>(statement: Prisma.Sql) {
    return (await db.query<T>(statement.text, statement.values)).rows;
  } });
  return { db, repository };
}

test('goal SQL isolates ownership and returns only the exact requested goal', async () => {
  const f = await fixture();
  try {
    assert.equal((await f.repository.find(owner, goal1))?.name, 'Concurso');
    assert.equal((await f.repository.find(owner, goal2))?.name, 'Faculdade');
    assert.equal(await f.repository.find(other, goal1), null);
    assert.equal(await f.repository.find(owner, '55555555-5555-4555-8555-555555555555'), null);
  } finally { await f.db.close(); }
});
test('a write to another user cannot modify the goal and SQL values cannot escape their context', async () => {
  const f = await fixture();
  try {
    assert.equal(await f.repository.rename(other, goal1, 'Roubo'), null);
    assert.equal((await f.repository.find(owner, goal1))?.name, 'Concurso');
    const literal = "x'; DELETE FROM \"User\"; --";
    assert.equal((await f.repository.rename(owner, goal1, literal))?.name, literal);
    assert.equal((await f.repository.find(owner, goal2))?.name, 'Faculdade');
    assert.equal((await f.db.query('SELECT * FROM "User"')).rows.length, 2);
  } finally { await f.db.close(); }
});
test('database rejects dangling owners, duplicate identities and blank goal names', async () => {
  const f = await fixture();
  try {
    await assert.rejects(f.db.query('INSERT INTO "User" (id, "externalId") VALUES ($1, $2)', ['55555555-5555-4555-8555-555555555555', 'owner']));
    await assert.rejects(f.db.query('INSERT INTO "StudyGoal" (id, "userId", name, category, "updatedAt") VALUES ($1, $2, $3, $4, now())', ['55555555-5555-4555-8555-555555555555', '66666666-6666-4666-8666-666666666666', 'Inglês', 'CURSO']));
    await assert.rejects(f.repository.rename(owner, goal1, '   '));
  } finally { await f.db.close(); }
});
