import {mkdir,readFile,writeFile} from 'node:fs/promises';
import {randomUUID} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {checkLocalConfig,localProbe} from './check-local-config.mjs';

async function httpRequest(origin,path,{method='GET',body,token}={}){
 const response=await fetch(origin+path,{method,headers:{...(body?{'content-type':'application/json'}:{}),...(token?{authorization:'Bearer '+token}:{})},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(45000),redirect:'error'});
 let data;try{data=await response.json();}catch{data=null;}return {status:response.status,data};
}
export async function verifyLiveStudy({env=process.env,probe=localProbe,request,resetPassword=false}={}){
 const config=await checkLocalConfig(env,probe),report={status:'pending',checks:[],issues:[]};
 if(!config.readyForLiveTest){report.issues=['Configuração incompleta. Execute check:config e conclua o guia de serviços reais.'];return report;}
 if(!env.LIVE_TEST_EMAIL||!env.LIVE_TEST_PASSWORD||env.LIVE_TEST_PASSWORD.length<8){report.issues=['Forneça LIVE_TEST_EMAIL e LIVE_TEST_PASSWORD em ambiente local privado.'];return report;}
 let origin;try{const u=new URL(env.LIVE_API_ORIGIN??'http://127.0.0.1:3001');if(u.origin!==u.href.replace(/\/$/,'')||u.username||u.password||!(u.protocol==='https:'||(u.protocol==='http:'&&['localhost','127.0.0.1','[::1]'].includes(u.hostname))))throw Error();origin=u.origin;}catch{report.issues=['LIVE_API_ORIGIN inválida.'];return report;}
 const send=request??((path,options)=>httpRequest(origin,path,options));let step='configuration';
 const check=(ok,name)=>{step=name;if(!ok)throw new Error('Check failed');report.checks.push({name,status:'passed'});};
 const auth=async(mode,password=env.LIVE_TEST_PASSWORD)=>send('/v1/auth/'+mode,{method:'POST',body:{email:env.LIVE_TEST_EMAIL,password}});
 try{
  if(resetPassword){step='password_reset_explicit';const r=await send('/v1/auth/password-reset',{method:'POST',body:{email:env.LIVE_TEST_EMAIL}});check(r.status===200&&r.data?.accepted===true,step);report.status='passed';return report;}
  if(env.LIVE_REGISTER==='1'){step='registration';const r=await auth('register');check(r.status===200&&typeof r.data?.idToken==='string',step);}
  step='login';let login=await auth('login');check(login.status===200&&typeof login.data?.idToken==='string'&&typeof login.data?.refreshToken==='string'&&login.data.expiresInSeconds>0,step);
  let token=login.data.idToken,refresh=login.data.refreshToken;
  step='profile';const me=await send('/v1/me',{token});check(me.status===200&&typeof me.data?.id==='string',step);const user=me.data.id;
  step='wrong_password';const wrong=await auth('login',randomUUID()+randomUUID());check(wrong.status===401,step);
  step='token_refresh';const renewed=await send('/v1/auth/refresh',{method:'POST',body:{refreshToken:refresh}});check(renewed.status===200&&typeof renewed.data?.idToken==='string'&&typeof renewed.data?.refreshToken==='string',step);token=renewed.data.idToken;refresh=renewed.data.refreshToken;
  check((await send('/v1/me',{token})).data?.id===user,'refreshed_identity');
  const free=JSON.parse(await readFile('apps/client/assets/study/catalog.json','utf8')),bb=JSON.parse(await readFile('apps/client/assets/contests/bb2026/catalog.json','utf8'));
  const entries=[{scope:'freeStudy',version:free.catalogVersion,topic:free.topics[0]},{scope:'bb2026',version:bb.catalogVersion,topic:bb.disciplines[0].modules[0]}];
  const goals=[];
  for(const entry of entries){step='context_'+entry.scope;const r=await send('/v1/study-contexts/'+entry.scope+'/ensure',{method:'POST',body:{},token});check(r.status===200&&r.data?.scope===entry.scope,step);goals.push(r.data);}
  check(goals[0].id!==goals[1].id,'distinct_goals');
  let remaining;
  for(let i=0;i<3;i++){
   const entry=entries[i%2];step='steve_'+(i+1);
   const r=await send('/v1/steve/messages',{method:'POST',token,body:{topicId:entry.topic.id,message:i===2?'Como usar aulas e desafios nesta plataforma?':`Explique ${entry.topic.title} com um exemplo breve.`,history:[]}});
   const known=(entry.topic.sources??[]).map(s=>s.url);
   check(r.status===200&&r.data?.status==='completed'&&typeof r.data.text==='string'&&r.data.text.length>0&&r.data.topicId===entry.topic.id&&Array.isArray(r.data.sources)&&r.data.sources.every(s=>known.includes(s.url))&&Number.isInteger(r.data.quota?.remaining)&&r.data.quota.remaining>=0&&!Number.isNaN(Date.parse(r.data.quota.resetAt))&&(remaining===undefined||r.data.quota.remaining===remaining-1),step);remaining=r.data.quota.remaining;
  }
  for(let i=0;i<entries.length;i++){
   const entry=entries[i],goal=goals[i],q=entry.topic.questions[0],body={topicId:entry.topic.id,contentVersion:entry.version,questionId:q.id,optionIndex:(q.correctIndex+1)%4,source:'quiz'},id=randomUUID();
   step='answer_'+entry.scope;const ack=await send(`/v1/goals/${goal.id}/answers/${id}`,{method:'PUT',body,token});check(ack.status===200&&ack.data?.answerId===id&&ack.data.correct===false,step);
   const retry=await send(`/v1/goals/${goal.id}/answers/${id}`,{method:'PUT',body,token});check(retry.status===200&&retry.data?.receivedAt===ack.data.receivedAt,'idempotent_'+entry.scope);
   const errors=await send(`/v1/goals/${goal.id}/errors`,{token});check(errors.status===200&&errors.data?.items.some(e=>e.questionId===q.id&&e.topicId===entry.topic.id&&e.status==='pending'),'notebook_'+entry.scope);
  }
  // Logout is client memory disposal; this backend does not revoke Firebase sessions on logout.
  token=undefined;refresh=undefined;login=undefined;
  check((await send('/v1/me',{})).status===401,'logout_private_access');
  step='return_login';const again=await auth('login');check(again.status===200&&typeof again.data?.idToken==='string',step);token=again.data.idToken;
  check((await send('/v1/me',{token})).data?.id===user,'same_account_return');
  for(let i=0;i<entries.length;i++){const r=await send(`/v1/goals/${goals[i].id}/dashboard`,{token});check(r.status===200&&r.data?.resume?.topicId===entries[i].topic.id,'resume_'+entries[i].scope);}
  report.status='passed';
 }catch{report.status='failed';report.issues=[`Falha no passo ${step}. Confira a configuração e repita com a conta de teste; detalhes privados não foram registrados.`];}
 return report;
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
 const report=await verifyLiveStudy({resetPassword:process.argv.includes('--password-reset')});
 await mkdir('artifacts/rotina-estudo',{recursive:true});await writeFile('artifacts/rotina-estudo/live-report.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));process.exitCode=report.status==='passed'?0:report.status==='pending'?2:1;
}
