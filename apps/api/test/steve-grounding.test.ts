import {test} from 'node:test';
import assert from 'node:assert/strict';
import {loadStudyDirectory} from '../src/catalog/study-directory';
import {buildSteveInstructions} from '../src/steve/steve.prompt';

test('Steve receives the formula variables and worked example visible in the current module', () => {
  const entry=loadStudyDirectory().find('bb2026-m02')!;
  const prompt=buildSteveInstructions(entry);
  for (const block of entry.contestLocation!.module.blocks) {
    assert.ok(prompt.includes(block.title),block.title);
    if (block.type==='formula') {
      for (const variable of block.variables) {
        assert.ok(prompt.includes(variable.meaning),variable.meaning);
        assert.ok(prompt.includes(variable.unit),variable.unit);
      }
      for (const condition of block.conditions) assert.ok(prompt.includes(condition),condition);
    }
    if (block.type==='example') {
      for (const text of [block.problem,...block.steps,block.answer,block.check]) assert.ok(prompt.includes(text),text);
    }
  }
});

test('Steve receives the current writing task and self-review without automated official grading', () => {
  const entry=loadStudyDirectory().find('bb2026-r01')!;
  const prompt=buildSteveInstructions(entry),task=entry.contestLocation!.module.writingTasks[0]!;
  for (const text of [task.title,task.prompt,task.motivatingText,...task.planning,...task.selfReview]) assert.ok(prompt.includes(text),text);
  assert.ok(prompt.includes('sem nota oficial'));
  assert.ok(prompt.includes('Não atribua nota'));
  assert.ok(!prompt.includes(entry.topic.questions[0]!.prompt));
  assert.ok(!prompt.includes('correctIndex'));
});

test('Steve instructions stay bounded while retaining educational and privacy rules', () => {
  const entry=loadStudyDirectory().find('bb2026-b01')!;
  const oversized={...entry,topic:{...entry.topic,notes:'material-curado '.repeat(5000)}};
  const prompt=buildSteveInstructions(oversized);
  assert.ok(prompt.length<=16000,`Contexto de ${prompt.length} caracteres`);
  for (const text of ['Nunca peça senhas ou tokens','sem nota oficial','Responda como texto simples','Contexto reduzido']) assert.ok(prompt.includes(text),text);
});

test('every canonical topic preserves sources and module study goals within the prompt budget', () => {
  const directory=loadStudyDirectory();
  for (const id of directory.topicIds) {
    const entry=directory.find(id)!,prompt=buildSteveInstructions(entry);
    assert.ok(prompt.length<=16000,id);
    assert.ok(!prompt.includes('Contexto reduzido'),id);
    for (const source of entry.topic.sources) assert.ok(prompt.includes(source.url),id);
    if (entry.contestLocation) {
      const module=entry.contestLocation.module;
      for (const text of [...module.objectives,...module.prerequisites,...module.retrieval]) assert.ok(prompt.includes(text),`${id}: ${text}`);
    } else assert.ok(prompt.includes(entry.topic.notes),id);
  }
});
