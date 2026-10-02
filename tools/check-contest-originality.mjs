import {readFileSync,writeFileSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {pathToFileURL} from 'node:url';

function tokens(text){return text.normalize('NFKD').replace(/\p{M}/gu,'').toLocaleLowerCase('pt-BR').match(/[\p{L}\p{N}]+/gu)??[];}
const minimum=12;
/** Exact consecutive-token overlap is a review aid, not proof of originality. */
export function findSourceMatches(text,sources){
 const authored=tokens(text),matches=[];
 for(const source of sources){
  const original=tokens(source.text),index=new Map();
  for(let j=0;j<=original.length-minimum;j++){const key=original.slice(j,j+minimum).join(' ');const offsets=index.get(key)??[];offsets.push(j);index.set(key,offsets);}
  const longestByStart=new Map();
  for(let i=0;i<=authored.length-minimum;i++){
   const offsets=index.get(authored.slice(i,i+minimum).join(' '))??[];
   for(const j of offsets){
    // A matching previous pair means this occurrence belongs to an earlier run.
    if(i>0&&j>0&&authored[i-1]===original[j-1])continue;
    let count=minimum;while(i+count<authored.length&&j+count<original.length&&authored[i+count]===original[j+count])count++;
    longestByStart.set(i,Math.max(longestByStart.get(i)??0,count));
   }
  }
  for(const [start,tokenCount] of longestByStart)matches.push({sourceId:source.id,start,tokenCount});
 }
 return matches.sort((a,b)=>a.start-b.start||a.sourceId.localeCompare(b.sourceId));
}
export function collectAuthoredText(root){
 const collected=[];
 const add=value=>{if(typeof value==='string')collected.push(value);else if(Array.isArray(value))value.forEach(add);};
 for(const discipline of root?.disciplines??[])for(const m of discipline.modules??[]){
  for(const key of ['title','level','summary','objectives','prerequisites','pitfalls','recap','retrieval','notes','suggestions'])add(m[key]);
  for(const block of m.blocks??[]){
   for(const key of ['title','text','items','problem','steps','answer','check','expression','conditions','columns','rows','caption'])add(block[key]);
   for(const variable of block.variables??[])for(const key of ['name','meaning','unit'])add(variable[key]);
  }
  for(const q of m.questions??[])for(const key of ['prompt','options','explanation'])add(q[key]);
  for(const task of m.writingTasks??[])for(const key of ['title','prompt','motivatingText','planning','selfReview'])add(task[key]);
 }
 return collected.join('\n');
}
function main(){
 const args=process.argv.slice(2),value=name=>{const i=args.indexOf(name);return i<0?undefined:args[i+1];};
 const sourcesDir=value('--sources'),reportPath=value('--report');
 if(!sourcesDir||!reportPath||args.length!==4)throw new Error('Use --sources <directory> --report <path>.');
 const sources=Array.from({length:8},(_,i)=>{const id=`source-${String(i+1).padStart(2,'0')}`;return {id,text:readFileSync(join(sourcesDir,`${id}.txt`),'utf8')};});
 const root=JSON.parse(readFileSync('apps/client/assets/contests/bb2026/catalog.json','utf8'));
 const authored=collectAuthoredText(root),matches=findSourceMatches(authored,sources);
 const report={method:'Unicode/case/punctuation normalized exact consecutive tokens, minimum12; maximal runs by authored token position.',sources:sources.map(s=>s.id),authoredTokens:tokens(authored).length,matches,reviewRequired:matches.length>0,limitation:'A zero match count does not guarantee universal originality. A match needs editorial examination; no automatic rewriting.'};
 writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({sources:8,authoredTokens:report.authoredTokens,matches:matches.length,report:reportPath}));
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){try{main();}catch(error){console.error(error.message);process.exitCode=1;}}
