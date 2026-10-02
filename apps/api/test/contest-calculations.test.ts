import {readFileSync} from 'node:fs';
import {join} from 'node:path';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import type {StudyQuestion} from '../src/catalog/study-catalog';
type Raw={disciplines:{id:string;modules:{id:string;questions:StudyQuestion[]}[]}[]};
function question(id:string):StudyQuestion {const root=JSON.parse(readFileSync(join(__dirname,'../../../../apps/client/assets/contests/bb2026/catalog.json'),'utf8')) as Raw;const q=root.disciplines.flatMap(d=>d.modules).flatMap(m=>m.questions).find(q=>q.id===id);assert.ok(q,`Missing ${id}`);return q;}
function label(id:string):string {const q=question(id);const value=q.options[q.correctIndex];assert.ok(value);return value;}
function number(id:string):number {const pt=label(id).replace(/−/g,'-').replace(/%$/,'');const normalized=pt.replace(/\.(?=\d{3}(?:\.|,|$))/g,'').replace(',','.');const value=Number(normalized);assert.ok(Number.isFinite(value),`Non-numeric answer ${id}: ${pt}`);return value;}
test('integer_precedence',()=>assert.equal(number('bb2026-m01-q04'),-8+3*4));
test('counting_order_repetition_and_combinations',()=>{
 const teams=new Set<string>();for(let a=0;a<5;a++)for(let b=0;b<5;b++)if(a!==b)teams.add([a,b].sort().join(','));
 assert.equal(number('bb2026-m02-q04'),teams.size);
 const pairs=[];for(const a of ['A','B','C'])for(const b of ['A','B','C'])if(a!==b)pairs.push(a+b);
 assert.equal(number('bb2026-m02-q05'),pairs.length);
 const passwords=[];for(let a=0;a<3;a++)for(let b=0;b<3;b++)passwords.push(`${a}${b}`);
 assert.equal(number('bb2026-m02-q06'),passwords.length);
});
test('dimensional_conversions',()=>{assert.equal(number('bb2026-m03-q04'),1.75*60);assert.equal(number('bb2026-m03-q05'),3*100*100);assert.equal(number('bb2026-m03-q06'),2.4*1000);});
test('proportional_division',()=>{const parts=[1,2,3].map(w=>72*w/6);assert.equal(parts.reduce((a,b)=>a+b,0),72);assert.equal(number('bb2026-m04-q04'),parts[2]);const inverseWeights=[3,2];assert.equal(number('bb2026-m04-q06'),120*inverseWeights[0]!/inverseWeights.reduce((a,b)=>a+b,0));});
test('work_units_conserved',()=>{assert.equal(number('bb2026-m05-q04'),(180/3)*5);assert.equal(number('bb2026-m05-q05'),4*12/6);assert.equal(number('bb2026-m05-q06'),(120/(2*3))*5*4);});
test('percentage_base_and_successive_variations',()=>{assert.equal(number('bb2026-m06-q04'),80-80*15/100);assert.ok(Math.abs(number('bb2026-m06-q05')-100*1.1*.9)<1e-9);assert.equal(number('bb2026-m06-q06'),(75-60)*100/60);});
test('truth_table_implication',()=>{const p=true,q=false;assert.equal(label('bb2026-m07-q06'),!p||q?'Verdadeira':'Falsa');});
test('contrapositive_equivalence_all_assignments',()=>{
 const rows=[[false,false],[false,true],[true,false],[true,true]] as const;
 const target=rows.map(([p,q])=>!p||q).join(',');
 const forms=[(p:boolean,q:boolean)=>!q||p,(p:boolean,q:boolean)=>p||!q,(p:boolean,q:boolean)=>q||!p,(p:boolean,q:boolean)=>p&&q];
 const matching=forms.map((f,i)=>rows.map(([p,q])=>f(p,q)).join(',')===target?i:-1).filter(i=>i>=0);
 assert.deepEqual(matching,[2]);assert.equal(label('bb2026-m08-q06'),['Q → P','¬P → ¬Q','¬Q → ¬P','P ∧ Q'][matching[0]!]);
});
test('sets_inclusion_exclusion',()=>{assert.equal(number('bb2026-m09-q04'),18+12-5);assert.equal(number('bb2026-m09-q05'),40-(18+12-5));});
test('function_evaluation_and_denominator_domain',()=>{assert.equal(number('bb2026-m10-q04'),2*4-3);assert.equal(number('bb2026-m10-q05')-2,0);});
test('quadratic_vertex_by_symmetry',()=>{const x=number('bb2026-m11-q06');const f=(x:number)=>x*x-5*x+6;assert.equal(f(x-1),f(x+1));assert.ok(f(x)<f(x-1));});
test('exponential_repeated_multiplication',()=>{let value=3;for(let n=0;n<3;n++)value*=2;assert.equal(number('bb2026-m12-q04'),value);assert.equal(2**number('bb2026-m12-q05'),32);});
test('logarithm_checked_by_exponent',()=>{assert.equal(2**number('bb2026-m13-q04'),32);assert.equal(10**number('bb2026-m13-q05'),.01);assert.equal(number('bb2026-m13-q06'),3**2);});
test('matrix_product_dimensions_and_dot_product',()=>{const a=[[1,2],[3,4]],b=[[2,0],[1,3]];assert.equal(number('bb2026-m14-q04'),a[0]!.reduce((sum,x,k)=>sum+x*b[k]![1]!,0));const rectangularA=[[1,2,3],[4,5,6]],rectangularB=[[1,2,3,4],[5,6,7,8],[9,10,11,12]];assert.equal(rectangularA[0]!.length,rectangularB.length);const product=rectangularA.map(row=>rectangularB[0]!.map((_,j)=>row.reduce((sum,x,k)=>sum+x*rectangularB[k]![j]!,0)));assert.equal(label('bb2026-m14-q06'),`${product.length} × ${product[0]!.length}`);});
test('determinant_by_permutations',()=>{const det=(m:number[][])=>m[0]![0]!*m[1]![1]!-m[0]![1]!*m[1]![0]!;assert.equal(number('bb2026-m15-q04'),det([[4,1],[2,3]]));assert.equal(number('bb2026-m15-q06'),det([[2,5],[2,5]]));});
test('linear_system_by_enumeration_and_substitution',()=>{const solutions=[];for(let x=0;x<=9;x++)for(let y=0;y<=9;y++)if(x+y===9&&x-y===1)solutions.push([x,y]);assert.deepEqual(solutions,[[5,4]]);assert.equal(number('bb2026-m16-q04'),solutions[0]![0]);const classify=(first:number[],second:number[])=>{const factor=second[0]!/first[0]!;return second[1]===first[1]!*factor?(second[2]===first[2]!*factor?'Infinitas soluções':'Sem solução'):'Solução única';};assert.equal(label('bb2026-m16-q05'),classify([1,1,2],[2,2,5]));assert.equal(label('bb2026-m16-q06'),classify([1,1,4],[2,2,8]));});
test('arithmetic_sequence_and_sum_by_iteration',()=>{const terms=Array.from({length:6},(_,i)=>7+3*i);assert.equal(number('bb2026-m17-q04'),terms.at(-1));const total=Array.from({length:10},(_,i)=>2+2*i).reduce((a,b)=>a+b,0);assert.equal(number('bb2026-m17-q05'),total);let a=1;for(let n=1;n<4;n++)a+=2*n;assert.equal(number('bb2026-m17-q06'),a);});
test('geometric_terms_sum_and_convergence',()=>{let term=3;for(let n=1;n<5;n++)term*=2;assert.equal(number('bb2026-m18-q04'),term);assert.equal(number('bb2026-m18-q05'),[2,6,18,54].reduce((a,b)=>a+b,0));let sum=0,t=1;for(let n=0;n<60;n++){sum+=t;t*=.5;}assert.ok(Math.abs(number('bb2026-m18-q06')-sum)<1e-12);});
