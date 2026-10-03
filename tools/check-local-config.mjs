import {readFile} from 'node:fs/promises';
import {isAbsolute,win32} from 'node:path';
import {pathToFileURL} from 'node:url';
import pg from 'pg';
const state=(status,issues=[])=>({status,issues});
const present=v=>typeof v==='string'&&v.trim().length>0;
const requiredColumns={User:['id','externalId'],StudyGoal:['id','userId','contextKey','dailyTarget','timezone'],StudyAnswer:['id','userId','goalId','topicId','contentVersion','questionId','optionIndex','source','correct','receivedAt','ordinal'],StudyQuestionError:['userId','goalId','topicId','contentVersion','questionId','status','wrongCount'],AiDailyUsage:['dayUTC','scope','count'],AiQuotaReservation:['id','userId','releasedAt']};
export const localProbe={
 async database(url){
  const client=new pg.Client({connectionString:url,connectionTimeoutMillis:4000,query_timeout:4000});
  try{await client.connect();const {rows}=await client.query("SELECT table_name,column_name FROM information_schema.columns WHERE table_schema='public'");const found=new Set(rows.map(r=>r.table_name+':'+r.column_name));return {connected:true,schema:Object.entries(requiredColumns).every(([table,columns])=>columns.every(c=>found.has(table+':'+c)))};}finally{await client.end().catch(()=>{});}
 },
 async firebase(path){return JSON.parse(await readFile(path,'utf8'));},
};
export async function checkLocalConfig(env,probe=localProbe){
 const result={database:state('missing',['Preencha DATABASE_URL.']),firebase:state('missing',['Configure Firebase e-mail/senha, chave Web e credencial Admin.']),steve:state('missing',['Preencha OPENAI_API_KEY e STEVE_MODEL.']),cors:state('missing',['Preencha CORS_ORIGINS.']),readyForLiveTest:false};
 if(present(env.DATABASE_URL)){
  let valid=false;try{const u=new URL(env.DATABASE_URL);valid=['postgres:','postgresql:'].includes(u.protocol)&&!!u.hostname&&u.pathname.length>1;}catch{}
  if(!valid)result.database=state('invalid',['DATABASE_URL tem formato inválido.']);
  else try{const d=await probe.database(env.DATABASE_URL);result.database=d.connected&&d.schema?state('verified'):state('invalid',[d.connected?'Banco acessível, mas schema incompleto; aplique as migrações.':'Banco indisponível.']);}catch{result.database=state('invalid',['Não foi possível verificar conexão e schema do banco.']);}
 }
 const fields=['FIREBASE_PROJECT_ID','FIREBASE_WEB_API_KEY','GOOGLE_APPLICATION_CREDENTIALS'];
 if(fields.some(k=>present(env[k]))){
  if(!fields.every(k=>present(env[k])))result.firebase=state('missing',['Complete FIREBASE_PROJECT_ID, FIREBASE_WEB_API_KEY e GOOGLE_APPLICATION_CREDENTIALS.']);
  else if(!/^[a-z][a-z0-9-]{4,29}$/.test(env.FIREBASE_PROJECT_ID)||!/^[A-Za-z0-9_-]{20,200}$/.test(env.FIREBASE_WEB_API_KEY)||!(isAbsolute(env.GOOGLE_APPLICATION_CREDENTIALS)||win32.isAbsolute(env.GOOGLE_APPLICATION_CREDENTIALS))||(env.NODE_ENV==='production'&&present(env.FIREBASE_AUTH_EMULATOR_HOST)))result.firebase=state('invalid',['Formato de configuração Firebase inválido.']);
  else try{const c=await probe.firebase(env.GOOGLE_APPLICATION_CREDENTIALS);result.firebase=c.type==='service_account'&&c.project_id===env.FIREBASE_PROJECT_ID&&typeof c.private_key==='string'&&c.private_key.startsWith('-----BEGIN PRIVATE KEY-----')&&typeof c.client_email==='string'&&c.client_email.endsWith('.iam.gserviceaccount.com')?state('configured'):state('invalid',['Credencial Admin inválida ou de outro projeto.']);}catch{result.firebase=state('invalid',['Não foi possível ler a credencial Admin.']);}
 }
 if(present(env.OPENAI_API_KEY)||present(env.STEVE_MODEL)){
  const limit=Number(env.STEVE_DAILY_LIMIT??10),global=Number(env.STEVE_GLOBAL_DAILY_LIMIT??1000);
  if(!present(env.OPENAI_API_KEY)||!present(env.STEVE_MODEL))result.steve=state('missing',['Chave e modelo do Steve devem ser preenchidos juntos.']);
  else if(!/^sk-[A-Za-z0-9_-]{20,}$/.test(env.OPENAI_API_KEY)||!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(env.STEVE_MODEL)||!Number.isSafeInteger(limit)||limit<1||limit>1000||!Number.isSafeInteger(global)||global<limit||global>100000)result.steve=state('invalid',['Formato de chave, modelo ou cotas do Steve inválido.']);
  else result.steve=state('configured');
 }
 if(present(env.CORS_ORIGINS)){
  const origins=env.CORS_ORIGINS.split(',').map(s=>s.trim());let preview;
  try{preview=new URL(env.PREVIEW_URL??'http://127.0.0.1:4174').origin;const valid=origins.every(s=>{const u=new URL(s);return u.origin===s&&['http:','https:'].includes(u.protocol)&&(env.NODE_ENV!=='production'||u.protocol==='https:');});result.cors=valid&&origins.includes(preview)?state('verified'):state('invalid',[valid?'CORS_ORIGINS não inclui a origem de PREVIEW_URL (padrão 127.0.0.1:4174).':'CORS_ORIGINS deve conter somente origens exatas.']);}catch{result.cors=state('invalid',['CORS_ORIGINS ou PREVIEW_URL inválido.']);}
 }
 result.readyForLiveTest=result.database.status==='verified'&&result.cors.status==='verified'&&result.firebase.status==='configured'&&result.steve.status==='configured';return result;
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){const report=await checkLocalConfig(process.env);console.log(JSON.stringify(report,null,2));process.exitCode=report.readyForLiveTest?0:2;}
