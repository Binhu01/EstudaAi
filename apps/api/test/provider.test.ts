import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OpenAiSteveProvider } from '../src/steve/openai.provider';
const input = {instructions:'Você é Steve.',message:'Como calcular 20%?',history:[{role:'user' as const,text:'Quero estudar.'},{role:'assistant' as const,text:'Vamos aprender.'}]};
const signal = new AbortController().signal;
test('Responses sends only safe configured fields and parses multiple REST text parts', async () => {
  let calls=0;
  const provider = new OpenAiSteveProvider('server-secret','configured-model',async (url,options) => {
    calls++; assert.equal(String(url),'https://api.openai.com/v1/responses');
    assert.equal(options?.redirect,'error');
    assert.equal((options?.headers as Record<string,string>).Authorization,'Bearer server-secret');
    const body = JSON.parse(String(options?.body));
    assert.equal(body.store,false); assert.equal(body.max_output_tokens,800);
    assert.equal(body.model,'configured-model');
    assert.deepEqual(body.input.map((m:any)=>m.role),['user','assistant','user']);
    assert.ok(!JSON.stringify(body).includes('server-secret'));
    assert.equal(body.tools,undefined);
    return Response.json({status:'completed',output:[{type:'reasoning',summary:[]},{type:'message',role:'assistant',content:[{type:'output_text',text:'Primeiro, '},{type:'output_text',text:'divida por cem.'}]}]});
  });
  assert.deepEqual(await provider.generate(input,signal),{status:'completed',text:'Primeiro, divida por cem.'});
  assert.equal(calls,1);
});
test('Responses distinguishes refusal, incomplete and malformed or empty completion', async () => {
  for (const [payload,expected] of [
    [{status:'completed',output:[{type:'message',role:'assistant',content:[{type:'refusal',refusal:'Não posso ajudar com esse pedido.'}]}]},'refused'],
    [{status:'incomplete',output:[{type:'message',role:'assistant',content:[{type:'output_text',text:'Uma parte'}]}]},'incomplete'],
    [{status:'incomplete',output:[{type:'reasoning',summary:[]}]},'incomplete'],
  ] as const) {
    const p = new OpenAiSteveProvider('secret','model',async()=>Response.json(payload));
    assert.equal((await p.generate(input,signal)).status,expected);
  }
  for (const payload of [{status:'completed',output:[]},{status:'failed',output:[]},{status:'completed',output:[{type:'message',content:[{type:'output_text',text:1}]}]},{}]) {
    const p = new OpenAiSteveProvider('secret','model',async()=>Response.json(payload));
    await assert.rejects(p.generate(input,signal),(e:any)=>e.getStatus()===503&&!e.message.includes('secret'));
  }
  const final = new OpenAiSteveProvider('secret','model',async()=>Response.json({status:'completed',output:[
    {type:'message',role:'assistant',phase:'commentary',content:[{type:'output_text',text:'Working...'}]},
    {type:'message',role:'assistant',phase:'final_answer',content:[{type:'output_text',text:'Resposta final'}]},
  ]}));
  assert.equal((await final.generate(input,signal)).text,'Resposta final');
});
test('provider timeout aborts the transport without retrying', async () => {
  let calls=0;
  const p = new OpenAiSteveProvider('secret','model',async (_url,options)=>new Promise((_,reject)=>{
    calls++; options!.signal!.addEventListener('abort',()=>reject(Error('private detail')),{once:true});
  }),20);
  await assert.rejects(p.generate(input,signal),(e:any)=>e.getStatus()===503);
  assert.equal(calls,1);
});
