import {readFileSync} from 'node:fs';
import {join} from 'node:path';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {ContestCatalog} from '../src/catalog/contest-catalog';
import {StudyCatalog} from '../src/catalog/study-catalog';
function fixture(): any { return JSON.parse(readFileSync(join(__dirname,'../../../../tools/test/fixtures/contest-catalog.json'),'utf8')); }
test('accepts_valid_contest_and_rejects_mutations',()=>{
  const c=ContestCatalog.fromJson(fixture());
  assert.equal(c.disciplines.flatMap(d=>d.modules).length,126);
  assert.equal(c.disciplines.flatMap(d=>d.modules).flatMap(m=>m.questions).length,756);
  assert.equal(c.find('bb2026-f07')?.discipline.id,'financeira');
  assert.equal(c.find('missing'),undefined);
  const mutations: ((r:any,m:any)=>void)[]=[
    r=>r.schemaVersion=2,r=>r.catalogVersion=1.5,r=>r.course.id='other',r=>r.course.referenceDate='2026-02-30',
    r=>r.disciplines[1].id='bancarios',r=>r.disciplines[0].modules.pop(),(r,m)=>m.id='bb2026-f01',
    (r,m)=>m.questions.pop(),(r,m)=>m.questions.push({...m.questions[0],id:m.id+'-q07'}),
    (r,m)=>m.questions[0].options=['A',' a ','C','D'],(r,m)=>m.questions[0].correctIndex=4,
    (r,m)=>m.blocks[0].type='html',(r,m)=>m.blocks[4].rows=[['one']],
    (r,m)=>m.blocks[1]={type:'text',title:'A',text:'B'},(r,m)=>m.lessonIds=['bb2026-financeira-video-1'],
    (r,m)=>m.sources[0].url='https://user:password@example.org/ref',
    (r,m)=>m.coverage=m.coverage.filter((x:any)=>x.objectiveIndex===0),
    (r,m)=>m.coverage[0].questionIds=['bb2026-f01-q01'],
    (r,m)=>m.writingTasks=[r.disciplines[8].modules[0].writingTasks[0]],
    r=>r.disciplines[0].lessons[0].videoId='bad',r=>r.disciplines[1].lessons[0].videoId=r.disciplines[0].lessons[0].videoId,
  ];
  for(const [i,mutate] of mutations.entries()) { const r=fixture(); mutate(r,r.disciplines[0].modules[0]); assert.throws(()=>ContestCatalog.fromJson(r),`mutation ${i}`); }
});
test('free_parser_remains_strict',()=>{
  const r=fixture(),m=r.disciplines[0].modules[0];
  assert.throws(()=>StudyCatalog.fromJson({schemaVersion:1,catalogVersion:1,topics:[{...m,subject:'Teste',lessons:r.disciplines[0].lessons}]}));
});
