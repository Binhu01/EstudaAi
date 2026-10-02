import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { loadStudyDirectory } from '../src/catalog/study-directory';

test('isolates_free_and_contest_catalogs', () => {
  const directory = loadStudyDirectory();
  assert.equal(directory.topicIds.length, 129);
  assert.equal(new Set(directory.topicIds).size, 129);
  assert.equal(directory.free.topics.length, 3);
  const free = directory.find('porcentagem')!;
  const contest = directory.find('bb2026-b01')!;
  assert.equal(free.area, 'freeStudy');
  assert.equal(contest.area, 'contest');
  assert.equal(free.contentVersion, 1);
  assert.equal(contest.contentVersion, 1);
  assert.equal(free.topic.questions.length, 10);
  assert.equal(contest.topic.questions.length, 6);
  assert.equal(contest.topic.lessons[0], contest.contestLocation!.discipline.lessons[0]);
  assert.equal(contest.topic.notes, contest.contestLocation!.module.notes);
  assert.equal(contest.disciplineId, 'bancarios');
  assert.equal(contest.referenceDate, '2026-10-01');
  assert.equal(directory.find('bb2026-missing'), undefined);
  assert.equal(directory.find('missing'), undefined);
});
test('packaged_bytes_equal_for_both_catalogs', async () => {
  for (const [source, copy] of [
    ['../client/assets/study/catalog.json', 'dist/src/catalog/catalog.json'],
    ['../client/assets/contests/bb2026/catalog.json', 'dist/src/catalog/contests/bb2026/catalog.json'],
  ]) assert.ok((await readFile(source!)).equals(await readFile(copy!)));
});
