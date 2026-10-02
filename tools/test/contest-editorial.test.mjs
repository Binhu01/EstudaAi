import {readFileSync} from 'node:fs';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {verifyContestContent,verifyContestMetadata} from '../verify-contest-content.mjs';
export function loadEditorialRoot(){return JSON.parse(readFileSync(new URL('../../apps/client/assets/contests/bb2026/catalog.json',import.meta.url),'utf8'));}
test('metadata_and_videos_ready',()=>{const report=verifyContestMetadata(loadEditorialRoot());assert.equal(report.lessons,18);assert.deepEqual(report.errors,[]);});
test('bancarios_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'bancarios'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,22);assert.equal(report.questions,132);assert.equal(report.writingTasks,0);});
test('atualidades_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'atualidades'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,12);assert.equal(report.questions,72);assert.equal(report.writingTasks,0);});
test('portugues_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'portugues'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,13);assert.equal(report.questions,78);assert.equal(report.writingTasks,0);});
test('matematica_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'matematica'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,18);assert.equal(report.questions,108);assert.equal(report.writingTasks,0);});
test('ingles_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'ingles'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,8);assert.equal(report.questions,48);assert.equal(report.writingTasks,0);});
test('vendas_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'vendas'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,20);assert.equal(report.questions,120);assert.equal(report.writingTasks,0);});
test('financeira_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'financeira'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,7);assert.equal(report.questions,42);assert.equal(report.writingTasks,0);});
test('informatica_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'informatica'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,21);assert.equal(report.questions,126);assert.equal(report.writingTasks,0);});
test('redacao_ready',()=>{const root=loadEditorialRoot();const report=verifyContestContent(root,{disciplineId:'redacao'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,5);assert.equal(report.questions,30);assert.equal(report.writingTasks,6);assert.deepEqual(root.disciplines.find(d=>d.id==='redacao').modules.map(m=>m.writingTasks.length),[1,1,1,1,2]);});
test('full_catalog_ready',()=>{const root=loadEditorialRoot();const r=verifyContestContent(root,{}),v=verifyContestMetadata(root);assert.deepEqual(r.errors,[]);assert.deepEqual(v.errors,[]);assert.deepEqual([r.modules,r.questions,r.writingTasks,v.lessons],[126,756,6,18]);});
test('reading_quiz_questions_carry_their_original_passage',()=>{const root=loadEditorialRoot();const english=root.disciplines.find(d=>d.id==='ingles');for(const [moduleIndex,numbers] of [[0,[1,2,3,6]],[2,[1,2,3,4]],[4,[1,2,6]],[5,[1,2,3]],[6,[1,2,3,4,5]],[7,[1,2,3,4,5,6]]]){const m=english.modules[moduleIndex],passage=m.blocks.find(b=>b.title==='Passagem original').text;for(const n of numbers)assert.ok(m.questions[n-1].prompt.includes(passage),m.questions[n-1].id);}});

// A syllabus link alone does not show that its named subtopics are taught.
for(const [id,subtopics] of [
 ['bb2026-b06',[/crédito rural/i,/crédito direto ao consumidor/i]],
 ['bb2026-b12',[/recuperação de crédito/i]],
 ['bb2026-b14',[/penhor mercantil/i,/fiança bancária/i]],
 ['bb2026-v12',[/leads/i,/copywriting/i,/gatilhos mentais/i,/inbound marketing/i]],
]) test(`${id}_historical_subtopics_have_instruction_application_and_practice`,()=>{
 const m=loadEditorialRoot().disciplines.flatMap(d=>d.modules).find(m=>m.id===id);
 for(const pattern of subtopics){
  const objectiveIndex=m.objectives.findIndex(text=>pattern.test(text));
  assert.ok(objectiveIndex>=0,`${id}: missing objective for ${pattern}`);
  const rows=m.coverage.filter(row=>row.objectiveIndex===objectiveIndex);
  assert.ok(rows.length>0,`${id}: missing coverage for ${pattern}`);
  for(const row of rows){
   assert.ok(row.blockIndexes.some(i=>m.blocks[i].type==='text'&&pattern.test(m.blocks[i].text)),`${id}: missing explanation for ${pattern}`);
   const example=m.blocks[row.exampleBlockIndex];
   assert.ok(pattern.test([example.problem,...example.steps,example.answer].join(' ')),`${id}: missing application for ${pattern}`);
   assert.ok(row.questionIds.some(id=>{const q=m.questions.find(q=>q.id===id);return pattern.test(q.prompt)&&pattern.test(q.explanation);}),`${id}: missing practice for ${pattern}`);
  }
  assert.match(m.notes,pattern,`${id}: Steve context omits ${pattern}`);
 }
});
test('pension_supervisor_example_identifies_entity_not_only_employee_access',()=>{
 const m=loadEditorialRoot().disciplines[0].modules[0];
 const example=m.blocks.find(block=>block.type==='example');
 assert.match(example.problem,/EFPC/);
 assert.match(example.problem,/EAPC/);
 assert.match(example.check,/coletiv/i);
 assert.match(m.notes,/EAPC/);
 assert.match(m.questions[4].explanation,/entidade/i);
});
