import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { loadStudyCatalog, StudyCatalog } from '../src/catalog/study-catalog';

test('packaged catalog preserves canonical bytes and routes known topics', async () => {
  const canonical = await readFile('../client/assets/study/catalog.json');
  assert.ok(canonical.equals(await readFile('dist/src/catalog/catalog.json')));
  const catalog = loadStudyCatalog();
  assert.equal(catalog.find('ecologia')?.lessons[0]?.videoId, 'gEV3nOs0EjY');
  assert.equal(catalog.find('missing'), undefined);
  assert.equal(catalog.topics.reduce((n,t) => n + t.questions.length, 0), 30);
});
test('server rejects malformed curriculum rather than accepting unsafe material', async () => {
  const raw = await readFile('../client/assets/study/catalog.json', 'utf8');
  for (const mutate of [
    (d: any) => { d.topics[0].sources[0].url = 'http://unsafe.example'; },
    (d: any) => { d.topics[0].questions[0].correctIndex = 5; },
    (d: any) => { d.topics[1].id = d.topics[0].id; },
    (d: any) => { d.topics[0].questions[0].options[1] = d.topics[0].questions[0].options[0]; },
  ]) {
    const data = JSON.parse(raw);
    mutate(data);
    assert.throws(() => StudyCatalog.fromJson(data));
  }
});
