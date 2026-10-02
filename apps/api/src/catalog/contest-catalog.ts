import {readFileSync} from 'node:fs';
import {join} from 'node:path';
import type {ContestCourse,ContestDiscipline,ContestLocation,ContestModule,CoverageRow,MaterialBlock,WritingTask} from './contest-models';
import type {StudyLesson,StudyQuestion,StudySource} from './study-catalog';

export const CONTEST_LAYOUT = Object.freeze({bancarios:['b',22,23],atualidades:['a',12,15],portugues:['p',13,9],matematica:['m',18,11],ingles:['e',8,1],vendas:['v',20,17],financeira:['f',7,4],informatica:['i',21,14],redacao:['r',5,0]} as const);
function fail(message:string):never {throw new Error(`Catálogo de concursos: ${message}`);}
function object(v:unknown):Record<string,unknown> {if(!v||typeof v!=='object'||Array.isArray(v))fail('objeto inválido');return v as Record<string,unknown>;}
function text(v:unknown):string {if(typeof v!=='string'||!v.trim())fail('texto vazio');return v;}
function list<T>(v:unknown,parse:(v:unknown)=>T,empty=false):readonly T[]{if(!Array.isArray(v)||(!empty&&!v.length))fail('lista inválida');return Object.freeze(v.map(parse));}
function unique(v:readonly unknown[]):void {if(new Set(v).size!==v.length)fail('valor duplicado');}
function integer(v:unknown,min=0,max=Number.MAX_SAFE_INTEGER):number {if(!Number.isSafeInteger(v)||Number(v)<min||Number(v)>max)fail('inteiro inválido');return Number(v);}
function id(v:unknown):string {const s=text(v);if(!/^[a-z0-9-]+$/.test(s))fail('ID inválido');return s;}
function date(v:unknown):string {const s=text(v);if(!/^\d{4}-\d{2}-\d{2}$/.test(s)||Number.isNaN(Date.parse(s))||new Date(s).toISOString().slice(0,10)!==s)fail('data inválida');return s;}
function source(v:unknown):StudySource {const s=object(v),url=text(s.url);let u:URL;try{u=new URL(url);}catch{fail('URL inválida');}if(u.protocol!=='https:'||!u.hostname||u.username||u.password)fail('fonte insegura');return Object.freeze({title:text(s.title),url});}
function lesson(v:unknown):StudyLesson {const l=object(v),videoId=text(l.videoId);if(!/^[A-Za-z0-9_-]{11}$/.test(videoId))fail('vídeo inválido');return Object.freeze({id:id(l.id),title:text(l.title),channel:text(l.channel),description:text(l.description),level:text(l.level),videoId});}
function question(v:unknown):StudyQuestion {const q=object(v),options=list(q.options,text);if(options.length!==4)fail('quatro alternativas exigidas');unique(options.map(s=>s.trim().toLocaleLowerCase('pt-BR')));return Object.freeze({id:id(q.id),prompt:text(q.prompt),options,correctIndex:integer(q.correctIndex,0,3),explanation:text(q.explanation)});}
function block(v:unknown):MaterialBlock {
  const b=object(v),title=text(b.title);
  switch(b.type){
    case 'text':return Object.freeze({type:'text',title,text:text(b.text)});
    case 'list':return Object.freeze({type:'list',title,items:list(b.items,text)});
    case 'example':return Object.freeze({type:'example',title,problem:text(b.problem),steps:list(b.steps,text),answer:text(b.answer),check:text(b.check)});
    case 'formula':return Object.freeze({type:'formula',title,expression:text(b.expression),variables:list(b.variables,v=>{const x=object(v);return Object.freeze({name:text(x.name),meaning:text(x.meaning),unit:text(x.unit)});}),conditions:list(b.conditions,text)});
    case 'table':{const columns=list(b.columns,text),rows=list(b.rows,v=>list(v,text));if(rows.some(r=>r.length!==columns.length))fail('tabela irregular');return Object.freeze({type:'table',title,columns,rows,caption:text(b.caption)});}
    default:return fail('tipo de bloco desconhecido');
  }
}
function writing(v:unknown):WritingTask {const w=object(v);return Object.freeze({id:id(w.id),title:text(w.title),prompt:text(w.prompt),motivatingText:text(w.motivatingText),planning:list(w.planning,text),selfReview:list(w.selfReview,text)});}
function coverage(v:unknown):CoverageRow {const c=object(v);return Object.freeze({referenceItem:text(c.referenceItem),objectiveIndex:integer(c.objectiveIndex),blockIndexes:list(c.blockIndexes,v=>integer(v)),exampleBlockIndex:integer(c.exampleBlockIndex),questionIds:list(c.questionIds,id),sourceUrls:list(c.sourceUrls,text)});}
export function parseContestCourse(v:unknown):ContestCourse {
  const c=object(v);if(c.id!=='bb2026'||c.status!=='preparation')fail('curso/status inválido');
  return Object.freeze({id:c.id,title:text(c.title),track:text(c.track),status:c.status,referenceDate:date(c.referenceDate),statusSources:list(c.statusSources,source),syllabusSource:source(c.syllabusSource)});
}
export function parseContestHeader(v:unknown):Omit<ContestDiscipline,'modules'> {
  const d=object(v),disciplineId=id(d.id);if(!Object.hasOwn(CONTEST_LAYOUT,disciplineId))fail('disciplina desconhecida');
  const lessons=list(d.lessons,lesson);if(lessons.length!==2)fail('duas aulas exigidas');unique(lessons.map(l=>l.id));unique(lessons.map(l=>l.videoId));
  if(lessons.some(l=>!l.id.startsWith(`bb2026-${disciplineId}-`)))fail('aula fora da disciplina');
  return Object.freeze({id:disciplineId,title:text(d.title),summary:text(d.summary),lessons});
}
function referenceItems(disciplineId:string):readonly string[] {
  const layout=CONTEST_LAYOUT[disciplineId as keyof typeof CONTEST_LAYOUT];
  return disciplineId==='redacao'?['7.3.3a','7.3.3b','7.3.3c','7.3.3d','7.3.3e','7.3.4','7.3.5','7.3.6']:Array.from({length:layout[2]},(_,i)=>String(i+1));
}
export function parseContestDiscipline(v:unknown):ContestDiscipline {
  const d=object(v),h=parseContestHeader(d),[prefix,count]=CONTEST_LAYOUT[h.id as keyof typeof CONTEST_LAYOUT],refs=referenceItems(h.id);
  const modules=list(d.modules,(v):ContestModule=>{
    const m=object(v),moduleId=id(m.id),researchId=text(m.researchId);
    if(!new RegExp(`^bb2026-${prefix}\\d{2}$`).test(moduleId)||researchId!==moduleId.slice(7).toUpperCase())fail('módulo fora da disciplina');
    const objectives=list(m.objectives,text),blocks=list(m.blocks,block),questions=list(m.questions,question),sources=list(m.sources,source),rows=list(m.coverage,coverage),lessonIds=list(m.lessonIds,id),writingTasks=list(m.writingTasks,writing,true),suggestions=list(m.suggestions,text),notes=text(m.notes);
    if(questions.length!==6||suggestions.length!==3||notes.length>4000||!blocks.some(b=>b.type==='example'))fail('módulo incompleto');
    unique(questions.map(q=>q.id));unique(lessonIds);unique(sources.map(s=>s.url));unique(writingTasks.map(w=>w.id));
    if(questions.some((q,i)=>q.id!==`${moduleId}-q${String(i+1).padStart(2,'0')}`)||lessonIds.length>2||lessonIds.some(l=>!h.lessons.some(x=>x.id===l)))fail('vínculo de questão/aula inválido');
    const number=Number(moduleId.slice(-2));const expectedWriting=h.id==='redacao'?(number===5?2:1):0;
    if(writingTasks.length!==expectedWriting||writingTasks.some(w=>!w.id.startsWith(`${moduleId}-`)))fail('tarefas de escrita inválidas');
    for(const c of rows){
      unique(c.blockIndexes);unique(c.questionIds);unique(c.sourceUrls);
      if(!refs.includes(c.referenceItem)||c.objectiveIndex>=objectives.length||c.blockIndexes.some(i=>i>=blocks.length||blocks[i]?.type==='example')||blocks[c.exampleBlockIndex]?.type!=='example'||c.questionIds.some(q=>!questions.some(x=>x.id===q))||c.sourceUrls.some(u=>!sources.some(s=>s.url===u)))fail('cobertura com vínculo inválido');
    }
    if(objectives.some((_,i)=>!rows.some(c=>c.objectiveIndex===i))||questions.some(q=>!rows.some(c=>c.questionIds.includes(q.id))))fail('objetivo/prática sem cobertura');
    return Object.freeze({id:moduleId,researchId,title:text(m.title),level:text(m.level),summary:text(m.summary),objectives,prerequisites:list(m.prerequisites,text,true),blocks,pitfalls:list(m.pitfalls,text),recap:list(m.recap,text),retrieval:list(m.retrieval,text),notes,suggestions,sources,updatedAt:date(m.updatedAt),lessonIds,questions,writingTasks,coverage:rows});
  });
  if(modules.length!==count||modules.some((m,i)=>m.id!==`bb2026-${prefix}${String(i+1).padStart(2,'0')}`))fail('sequência de módulos incompleta');
  if(refs.some(item=>!modules.some(m=>m.coverage.some(c=>c.referenceItem===item))))fail('item histórico ausente');
  return Object.freeze({...h,modules});
}
export function parseContestMetadata(v:unknown):Readonly<{course:ContestCourse;disciplines:readonly Omit<ContestDiscipline,'modules'>[];catalogVersion:number}> {
  const r=object(v);if(r.schemaVersion!==1)fail('schema inválido');const catalogVersion=integer(r.catalogVersion,1),course=parseContestCourse(r.course),disciplines=list(r.disciplines,parseContestHeader);
  unique(disciplines.map(d=>d.id));if(disciplines.length!==9)fail('nove disciplinas exigidas');
  unique(disciplines.flatMap(d=>d.lessons.map(l=>l.id)));unique(disciplines.flatMap(d=>d.lessons.map(l=>l.videoId)));
  return Object.freeze({course,disciplines,catalogVersion});
}
export class ContestCatalog {
  private constructor(readonly catalogVersion:number,readonly course:ContestCourse,readonly disciplines:readonly ContestDiscipline[]){Object.freeze(this);}
  static fromJson(v:unknown):ContestCatalog {const metadata=parseContestMetadata(v),root=object(v);return new ContestCatalog(metadata.catalogVersion,metadata.course,list(root.disciplines,parseContestDiscipline));}
  find(topicId:string):ContestLocation|undefined {for(const discipline of this.disciplines){const module=discipline.modules.find(m=>m.id===topicId);if(module)return Object.freeze({discipline,module});}return undefined;}
  findDiscipline(disciplineId:string):ContestDiscipline|undefined {return this.disciplines.find(d=>d.id===disciplineId);}
}
export function loadContestCatalog():ContestCatalog {return ContestCatalog.fromJson(JSON.parse(readFileSync(join(__dirname,'contests/bb2026/catalog.json'),'utf8')));}
