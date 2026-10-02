// Synthetic structural fixture. Never packaged as educational content.
import {mkdirSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
const layouts = [
  ['bancarios','b',[[1],[2],[3],[3],[4],[5],[5],[5],[6],[7,8],[9,10,11],[12,13],[14],[15],[16],[17,18],[19],[19],[20],[21],[22],[23]]],
  ['atualidades','a',[[1,5,15],[2,3],[4],[6],[7],[8],[9],[10],[11],[12],[13],[14]]],
  ['portugues','p',[[1],[3],[3],[2],[5],[5],[6],[7],[7],[7],[8],[4],[9]]],
  ['matematica','m',[[1],[1],[2],[3],[3],[3],[4],[4],[5],[6],[6],[6],[6],[7],[8],[9],[10,11],[11]]],
  ['ingles','e',Array.from({length:8},()=>[1])],
  ['vendas','v',[[1],[1],[2],[3],[4],[5],[6],[7],[7],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17]]],
  ['financeira','f',[[1],[2],[3],[1,3],[1],[4],[4]]],
  ['informatica','i',[[1],[1],[2],[2],[2],[2],[3],[4],[5],[6],[6],[7],[8],[8],[9],[10],[11],[12],[13],[14],[14]]],
  ['redacao','r',[['7.3.3a','7.3.3b','7.3.4','7.3.5','7.3.6'],['7.3.3a','7.3.3b','7.3.3d'],['7.3.3d'],['7.3.3c'],['7.3.3e','7.3.4','7.3.5','7.3.6']]],
];
export function makeContestFixture({empty=false}={}) {
  const source={title:'Fonte sintética',url:'https://example.org/reference'};
  let video=0;
  return {schemaVersion:1,catalogVersion:1,course:{id:'bb2026',title:'Banco do Brasil 2026',track:'Escriturário — Agente Comercial',status:'preparation',referenceDate:'2026-10-01',statusSources:[source],syllabusSource:source},disciplines:layouts.map(([disciplineId,prefix,refs])=>{
    const lessons=[1,2].map(n=>({id:`bb2026-${disciplineId}-video-${n}`,title:`Vídeo sintético ${n}`,channel:'Teste',description:'Somente teste',level:'Fundamentos',videoId:`test${String(++video).padStart(7,'0')}`}));
    return {id:disciplineId,title:`Disciplina ${disciplineId}`,summary:'Resumo sintético',lessons,modules:empty?[]:refs.map((items,index)=>{
      const suffix=String(index+1).padStart(2,'0'),id=`bb2026-${prefix}${suffix}`;
      const questions=Array.from({length:6},(_,q)=>({id:`${id}-q${String(q+1).padStart(2,'0')}`,prompt:`Questão sintética ${q+1}`,options:['Primeira','Segunda','Terceira','Quarta'],correctIndex:q%4,explanation:'Explicação sintética.'}));
      return {id,researchId:`${prefix.toUpperCase()}${suffix}`,title:`Módulo sintético ${index+1}`,level:'Fundamentos',summary:'Resumo',objectives:['Reconhecer conceito','Aplicar conceito'],prerequisites:[],blocks:[{type:'text',title:'Explicação',text:'Texto sintético.'},{type:'example',title:'Exemplo',problem:'Problema sintético',steps:['Passo único'],answer:'Resposta',check:'Conferência independente'},{type:'list',title:'Lista',items:['Item']},{type:'formula',title:'Fórmula',expression:'x = y',variables:[{name:'x',meaning:'Valor',unit:'unidade'}],conditions:['Condição']},{type:'table',title:'Tabela',columns:['A','B'],rows:[['1','2']],caption:'Legenda'}],pitfalls:['Erro'],recap:['Revisão'],retrieval:['Pergunta'],notes:'Notas',suggestions:['Explique o conceito','Resolva um exemplo','Revise meu raciocínio'],sources:[source],updatedAt:'2026-10-01',lessonIds:[lessons[0].id],questions,writingTasks:disciplineId==='redacao'?Array.from({length:index===4?2:1},(_,n)=>({id:`${id}-writing-${n+1}`,title:'Tarefa sintética',prompt:'Produza um texto',motivatingText:'Texto motivador sintético',planning:['Planejar'],selfReview:['Revisar']})):[],coverage:items.flatMap(referenceItem=>[0,1].map(objectiveIndex=>({referenceItem:String(referenceItem),objectiveIndex,blockIndexes:[0],exampleBlockIndex:1,questionIds:questions.slice(objectiveIndex*3,objectiveIndex*3+3).map(q=>q.id),sourceUrls:[source.url]})))};
    })};
  })};
}
if(process.argv[1]===fileURLToPath(import.meta.url)) {
  mkdirSync(new URL('./fixtures/',import.meta.url),{recursive:true});
  writeFileSync(new URL('./fixtures/contest-catalog.json',import.meta.url),JSON.stringify(makeContestFixture(),null,2)+'\n');
}
