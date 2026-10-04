import {chromium,expect} from '@playwright/test';
import {mkdir,writeFile,readFile} from 'node:fs/promises';
import { navigate, revealPainted } from './web-verification-helpers.mjs';
const url=process.env.PREVIEW_URL??'http://127.0.0.1:4174';
const output='artifacts/rotina-estudo/browser';await mkdir(output,{recursive:true});
const userA='11111111-1111-4111-8111-111111111111',userB='22222222-2222-4222-8222-222222222222';
const goals={freeStudy:'33333333-3333-4333-8333-333333333333',bb2026:'44444444-4444-4444-8444-444444444444'};
const otherGoals={freeStudy:'66666666-6666-4666-8666-666666666666',bb2026:'77777777-7777-4777-8777-777777777777'};
const scopeForPath=path=>path.includes(goals.bb2026)||path.includes(otherGoals.bb2026)?'bb2026':'freeStudy';
const browser=await chromium.launch({headless:true});const reports=[];let lastPage;
const free=JSON.parse(await readFile('apps/client/assets/study/catalog.json','utf8'));
const contests=JSON.parse(await readFile('apps/client/assets/contests/bb2026/catalog.json','utf8'));
const topics=[...free.topics,...contests.disciplines.flatMap(d=>d.modules)];
const subjectFor=id=>{const d=contests.disciplines.find(d=>d.modules.some(m=>m.id===id));const t=free.topics.find(t=>t.id===id);return d?{id:d.id,title:d.title}:{id:t.id,title:t.title};};
async function click(page,text){const l=page.locator('flt-semantics').getByText(text,{exact:true}).first();await l.scrollIntoViewIfNeeded();await l.click();}
async function login(page,email){
 await page.goto(url+'/#/conta');
 if(await page.locator('flt-semantics-placeholder').count())await page.locator('flt-semantics-placeholder').dispatchEvent('click');
 const field=page.getByRole('textbox',{name:/E-mail/});await field.click();await field.focus();await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));await field.pressSequentially(email,{delay:15});
 const password=page.getByRole('textbox',{name:/Senha/});await password.click();await password.focus();await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));await password.pressSequentially('test-password',{delay:15});await click(page,'Entrar na conta');
 await expect(page.locator('flt-semantics').getByText('Sair da conta',{exact:true})).toBeVisible();
}
try{
 for(const viewport of [{width:360,height:800},{width:768,height:1024},{width:1440,height:1000}]){
  const timezoneId=viewport.width===360?'America/New_York':'America/Sao_Paulo';
  const dates=viewport.width===360?['2026-03-03','2026-03-04','2026-03-05','2026-03-06','2026-03-07','2026-03-08','2026-03-09']:['2026-09-26','2026-09-27','2026-09-28','2026-09-29','2026-09-30','2026-10-01','2026-10-02'];
  const context=await browser.newContext({viewport,timezoneId,reducedMotion:'reduce'});const page=await context.newPage();lastPage=page;const pageErrors=[];page.on('pageerror',e=>pageErrors.push(e.message));
  const history=new Map(),targets=new Map(),acks=new Map(),errors=new Map(),reviewCalls=[];let loseReview=true;const currentDate=dates.at(-1);
  const goal=(scope,owner=userA)=>({id:(owner===userA?goals:otherGoals)[scope],scope,timezone:'America/Sao_Paulo',dailyTarget:targets.get(owner+scope)??10});
  await context.route('http://127.0.0.1:3001/**',async route=>{
   const request=route.request(),path=new URL(request.url()).pathname,body=request.postDataJSON(),owner=request.headers().authorization?.includes('token-b')?userB:userA;
   let data={},status=200;
   if(path.endsWith('/login')||path.endsWith('/register'))data={idToken:body.email==='b@example.com'?'token-b':'token-a',refreshToken:'test-refresh',expiresInSeconds:3600};
   else if(path==='/v1/me')data={id:owner,plan:'FREE'};
   else if(path.endsWith('/ensure'))data=goal(path.includes('/bb2026/')?'bb2026':'freeStudy',owner);
   else if(path.endsWith('/daily-target')){const scope=scopeForPath(path);targets.set(owner+scope,body.dailyTarget);data=goal(scope,owner);}
   else if(request.method()==='PUT'&&path.includes('/answers/')){
    const scope=scopeForPath(path),id=path.split('/').at(-1),key=owner+scope+id;
    const topic=topics.find(t=>t.id===body.topicId),q=topic.questions.find(q=>q.id===body.questionId);
    if(body.source==='review')reviewCalls.push({id,body});
    if(!acks.has(key)){
     const ack={...body,answerId:id,goalId:goal(scope,owner).id,correct:body.optionIndex===q.correctIndex,receivedAt:currentDate+'T12:00:00.000Z'};
     acks.set(key,ack);history.set(owner+scope,[...(history.get(owner+scope)??[]),ack]);
     const errorKey=owner+scope+body.topicId+body.questionId,previous=errors.get(errorKey);
     if(!ack.correct||previous)errors.set(errorKey,{topicId:body.topicId,contentVersion:body.contentVersion,questionId:body.questionId,wrongCount:(previous?.wrongCount??0)+(ack.correct?0:1),firstWrongAt:previous?.firstWrongAt??ack.receivedAt,lastWrongAt:ack.correct?previous.lastWrongAt:ack.receivedAt,lastAnswerAt:ack.receivedAt,lastOptionIndex:body.optionIndex,status:ack.correct?'reviewed':'pending',contentStatus:'current'});
    }
    data=acks.get(key);if(body.source==='review'&&loseReview){loseReview=false;status=503;data={code:'UNAVAILABLE'};}
   }
   else if(path.endsWith('/dashboard')){
    const scope=scopeForPath(path),events=history.get(owner+scope)??[],stats=new Map();
    for(const event of events){const subject=subjectFor(event.topicId),stat=stats.get(subject.id)??{...subject,attempts:0,correct:0};stat.attempts++;stat.correct+=event.correct?1:0;stats.set(subject.id,stat);}
    const today={date:currentDate,differentQuestions:new Set(events.map(e=>e.topicId+':'+e.contentVersion+':'+e.questionId)).size,attempts:events.length,correct:events.filter(e=>e.correct).length};
    data={goal:goal(scope,owner),today,pendingErrors:[...errors.entries()].filter(([key,e])=>key.startsWith(owner+scope)&&e.status==='pending').length,activity:[...dates.slice(0,-1).map(date=>({date,differentQuestions:0,attempts:0,correct:0})),today],subjects:[...stats.values()],resume:events.length?{topicId:events.at(-1).topicId,contentVersion:scope==='freeStudy'?free.catalogVersion:contests.catalogVersion}:null};
   }else if(path.endsWith('/errors')){const scope=scopeForPath(path),query=new URL(request.url()).searchParams;data={items:[...errors.entries()].filter(([key,e])=>key.startsWith(owner+scope)&&e.status===(query.get('status')??'pending')&&(!query.has('subjectId')||subjectFor(e.topicId).id===query.get('subjectId'))).map(([,e])=>e),nextCursor:null};}
   else if(request.method()==='OPTIONS')data={};else{status=503;data={code:'UNAVAILABLE'};}
   await route.fulfill({status,json:data,headers:{'access-control-allow-origin':new URL(url).origin,'access-control-allow-headers':'authorization,content-type','access-control-allow-methods':'GET,POST,PUT,PATCH,OPTIONS'}});
  });
  await page.goto(url+'/#/meu-estudo');await page.locator('flt-semantics-placeholder').dispatchEvent('click');
  await expect(page.locator('flt-semantics').getByText('Entrar para salvar meu estudo',{exact:true})).toBeVisible();
  await login(page,'a@example.com');await navigate(page,'Meu estudo');
  await expect(page.locator('flt-semantics').getByText('0 de 10 questões diferentes',{exact:true})).toBeVisible();
  const seed=free.topics.find(t=>t.id==='porcentagem');history.set(userA+'freeStudy',[{topicId:seed.id,contentVersion:free.catalogVersion,questionId:seed.questions[0].id,correct:true},{topicId:seed.id,contentVersion:free.catalogVersion,questionId:seed.questions[1].id,correct:false},{topicId:seed.id,contentVersion:free.catalogVersion,questionId:seed.questions[1].id,correct:false}]);
  await click(page,'Atualizar meu estudo');
  await expect(page.locator('flt-semantics').getByText('2 de 10 questões diferentes',{exact:true})).toBeVisible();
  await expect(page.locator('flt-semantics').getByText('1 acerto em 3 tentativas',{exact:true})).toBeVisible();
  const dailyTarget=page.getByRole('button',{name:/^Questões por dia(?:\s|$)/});
  await expect(dailyTarget).toHaveAccessibleName('Questões por dia 10 questões');
  await revealPainted(page,dailyTarget);await dailyTarget.click();
  await page.getByRole('menuitem',{name:'5 questões',exact:true}).click();
  await expect(dailyTarget).toHaveAccessibleName('Questões por dia 5 questões');
  await expect(page.locator('flt-semantics').getByText('2 de 5 questões diferentes',{exact:true})).toBeVisible();
  await page.screenshot({path:`${output}/${viewport.width}-dashboard.png`,fullPage:true});
  for(const [scope,topic,quizPath]of [['freeStudy',free.topics[0],`/desafios/${free.topics[0].id}`],['bb2026',contests.disciplines[0].modules[0],`/concursos/${contests.course.id}/${contests.disciplines[0].id}/${contests.disciplines[0].modules[0].id}/desafio`]]){
   await page.goto(url+'/#'+quizPath);await click(page,'Começar desafio');await expect(page.getByText('QUESTÃO 1/5',{exact:true})).toBeVisible();let q;
   for(const candidate of topic.questions)if(await page.getByText(candidate.prompt,{exact:true}).count()){q=candidate;break;}
   expect(q).toBeTruthy();const wrong=page.getByRole('button',{name:q.options[(q.correctIndex+1)%4],exact:true});await wrong.scrollIntoViewIfNeeded();await wrong.click();
   await expect(page.locator('flt-semantics').getByText('Resposta salva na sua conta.',{exact:true})).toBeVisible();
   await page.goto(url+'/#/meus-erros');await expect(page.getByText('Seu caderno de erros',{exact:true})).toBeVisible();await click(page,'Revisar questão');
   await expect(page.getByText(q.explanation,{exact:true})).toHaveCount(0);
   const right=page.getByRole('button',{name:q.options[q.correctIndex],exact:true});await right.scrollIntoViewIfNeeded();await right.click();
   if(scope==='freeStudy'){await expect(page.locator('flt-semantics').getByText('Não foi possível confirmar o registro desta resposta. Tente novamente ou continue estudando.',{exact:true})).toBeVisible();await expect(page.locator('flt-semantics').getByText('Revisado',{exact:true})).toHaveCount(0);await click(page,'Tentar novamente');}
   await expect(page.locator('flt-semantics').getByText('Revisado',{exact:true})).toBeVisible();if(scope==='freeStudy'){expect(reviewCalls.length).toBe(2);expect(reviewCalls[0]).toEqual(reviewCalls[1]);}await click(page,'Voltar ao caderno');await page.getByRole('checkbox',{name:'Revisados',exact:true}).click();await expect(page.getByText(q.prompt,{exact:true})).toBeVisible();
   await page.screenshot({path:`${output}/${viewport.width}-${scope}-reviewed.png`,fullPage:true});
  }
  await page.goto(url+'/#/meu-estudo');await page.getByRole('checkbox',{name:'Estudo livre',exact:true}).click();
  await page.getByRole('checkbox',{name:'Banco do Brasil',exact:true}).click();await expect(page.locator('flt-semantics').getByText('1 de 10 questões diferentes',{exact:true})).toBeVisible();
  await page.goto(url+'/#/conta');await click(page,'Sair da conta');await login(page,'b@example.com');await navigate(page,'Meu estudo');
  await expect(page.locator('flt-semantics').getByText('0 de 10 questões diferentes',{exact:true})).toBeVisible();
  expect(pageErrors).toEqual([]);reports.push({viewport,timezoneId,activityDates:dates,flows:10,internalErrors:pageErrors,transport:'controlled test fixture; no live Firebase/OpenAI'});await context.close();
 }
 await writeFile(`${output}/report.json`,JSON.stringify({reports},null,2));console.log(JSON.stringify({viewports:reports.length,flows:reports.reduce((n,r)=>n+r.flows,0),internalErrors:0,transport:'controlled'},null,2));
}catch(error){if(lastPage&&!lastPage.isClosed()){await lastPage.screenshot({path:`${output}/failure.png`});await writeFile(`${output}/failure-aria.txt`,await lastPage.locator('body').ariaSnapshot());}throw error;}finally{await browser.close();}
