import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import catalog from '../apps/api/dist/src/catalog/contest-catalog.js';
const {ContestCatalog,parseContestDiscipline,parseContestMetadata}=catalog;
export function verifyContestMetadata(root){
  try{const c=parseContestMetadata(root);return {lessons:c.disciplines.flatMap(d=>d.lessons).length,errors:[]};}
  catch(e){return {lessons:0,errors:[e.message]};}
}
export function verifyContestContent(root,{disciplineId}={}){
  try{
    const disciplines=disciplineId?[parseContestDiscipline(root?.disciplines?.find(d=>d.id===disciplineId))]:ContestCatalog.fromJson(root).disciplines;
    const modules=disciplines.flatMap(d=>d.modules);
    return {modules:modules.length,questions:modules.flatMap(m=>m.questions).length,writingTasks:modules.flatMap(m=>m.writingTasks).length,errors:[]};
  }catch(e){return {modules:0,questions:0,writingTasks:0,errors:[e.message]};}
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
  const args=process.argv.slice(2);const disciplineId=args[0]==='--discipline'?args[1]:undefined;
  if((args[0]!=='--all'&&!disciplineId)||args.length>(disciplineId?2:1)){console.error('Uso: --all | --discipline <id>');process.exitCode=1;}
  else {try{const root=JSON.parse(readFileSync(new URL('../apps/client/assets/contests/bb2026/catalog.json',import.meta.url),'utf8'));const report=verifyContestContent(root,{disciplineId});console.log(JSON.stringify(report));if(report.errors.length)process.exitCode=1;}catch(e){console.error(e.message);process.exitCode=1;}}
}
