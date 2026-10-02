import {test} from 'node:test';
import assert from 'node:assert/strict';
import {findSourceMatches,collectAuthoredText} from '../check-contest-originality.mjs';
const phrase='um dois tres quatro cinco seis sete oito nove dez onze doze';
test('flags12_tokens_with_normalization_and_ignores_shorter',()=>{
 assert.deepEqual(findSourceMatches(phrase,[{id:'s',text:phrase}]),[{sourceId:'s',start:0,tokenCount:12}]);
 assert.equal(findSourceMatches('UM, dois; TRÊS! quatro cinco\nseis sete oito nove dez onze doze',[{id:'s',text:phrase}]).length,1);
 assert.deepEqual(findSourceMatches(phrase.split(' ').slice(1).join(' '),[{id:'s',text:phrase}]),[]);
});
test('returns_maximal_runs_with_token_positions_and_all_sources',()=>{
 const extended=phrase+' treze quatorze';
 assert.deepEqual(findSourceMatches('prefixo '+extended+' fim',[{id:'a',text:'x '+extended+' y'},{id:'b',text:phrase}]),[{sourceId:'a',start:1,tokenCount:14},{sourceId:'b',start:1,tokenCount:12}]);
 assert.deepEqual(findSourceMatches(phrase,[{id:'s',text:phrase+' '+phrase}]),[{sourceId:'s',start:0,tokenCount:12}]);
});
test('collects_pedagogical_fields_without_reference_metadata',()=>{
 const text=collectAuthoredText({course:{title:'course-metadata'},disciplines:[{title:'discipline-metadata',lessons:[{title:'video-metadata'}],modules:[{id:'module-id',title:'Material próprio',summary:'Resumo',objectives:['Objetivo'],blocks:[{type:'text',title:'Ler',text:'Explicação'},{type:'list',title:'Lista',items:['Item']},{type:'example',problem:'Problema',steps:['Passo'],answer:'Resposta',check:'Conferência'},{type:'formula',expression:'x=1',variables:[{name:'x',meaning:'variável',unit:'unidade'}],conditions:['Condição']},{type:'table',columns:['Coluna'],rows:[['Célula']],caption:'Legenda'}],notes:'Notas',questions:[{id:'question-id',prompt:'Pergunta',options:['Opção'],explanation:'Comentário'}],writingTasks:[{title:'Proposta',prompt:'Comando',motivatingText:'Motivador',planning:['Plano'],selfReview:['Revisar']}],sources:[{title:'source-metadata',url:'https://source.example'}],coverage:[{referenceItem:'item-id',sourceUrls:['https://source.example']}]}]}]});
 for(const value of ['Explicação','Item','Passo','Conferência','x=1','variável','Célula','Comentário','Motivador','Revisar'])assert.ok(text.includes(value),value);
 for(const value of ['course-metadata','discipline-metadata','video-metadata','module-id','question-id','source-metadata','https://','item-id'])assert.ok(!text.includes(value),value);
});
