import {chromium,expect} from '@playwright/test';
import {mkdir,writeFile} from 'node:fs/promises';
const url=process.env.PREVIEW_URL??'http://127.0.0.1:4174';
const output='artifacts/rotina-estudo/browser';await mkdir(output,{recursive:true});
const userA='11111111-1111-4111-8111-111111111111',userB='22222222-2222-4222-8222-222222222222';
const goals={freeStudy:'33333333-3333-4333-8333-333333333333',bb2026:'44444444-4444-4444-8444-444444444444'};
const browser=await chromium.launch({headless:true});const reports=[];let lastPage;
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
  const context=await browser.newContext({viewport,reducedMotion:'reduce'});const page=await context.newPage();lastPage=page;const pageErrors=[];page.on('pageerror',e=>pageErrors.push(e.message));
  const history=new Map(),targets=new Map();const currentDate='2026-10-02';
  const goal=(scope)=>({id:goals[scope],scope,timezone:'America/Sao_Paulo',dailyTarget:targets.get(scope)??10});
  await context.route('http://127.0.0.1:3001/**',async route=>{
   const request=route.request(),path=new URL(request.url()).pathname,body=request.postDataJSON(),owner=request.headers().authorization?.includes('token-b')?userB:userA;
   let data={},status=200;
   if(path.endsWith('/login')||path.endsWith('/register'))data={idToken:body.email==='b@example.com'?'token-b':'token-a',refreshToken:'test-refresh',expiresInSeconds:3600};
   else if(path==='/v1/me')data={id:owner,plan:'FREE'};
   else if(path.endsWith('/ensure'))data=goal(path.includes('/bb2026/')?'bb2026':'freeStudy');
   else if(path.endsWith('/daily-target')){const scope=path.includes(goals.bb2026)?'bb2026':'freeStudy';targets.set(scope,body.dailyTarget);data=goal(scope);}
   else if(path.endsWith('/dashboard')){
    const scope=path.includes(goals.bb2026)?'bb2026':'freeStudy',events=history.get(owner+scope)??[];
    const today={date:currentDate,differentQuestions:new Set(events.map(e=>e.topicId+':'+e.questionId)).size,attempts:events.length,correct:events.filter(e=>e.correct).length};
    data={goal:goal(scope),today,pendingErrors:0,activity:[...['2026-09-26','2026-09-27','2026-09-28','2026-09-29','2026-09-30','2026-10-01'].map(date=>({date,differentQuestions:0,attempts:0,correct:0})),today],subjects:[],resume:events.length?{topicId:events.at(-1).topicId,contentVersion:1}:null};
   }else if(path.endsWith('/errors'))data={items:[],nextCursor:null};
   else if(request.method()==='OPTIONS')data={};else{status=503;data={code:'UNAVAILABLE'};}
   await route.fulfill({status,json:data,headers:{'access-control-allow-origin':new URL(url).origin,'access-control-allow-headers':'authorization,content-type','access-control-allow-methods':'GET,POST,PUT,PATCH,OPTIONS'}});
  });
  await page.goto(url+'/#/meu-estudo');await page.locator('flt-semantics-placeholder').dispatchEvent('click');
  await expect(page.locator('flt-semantics').getByText('Entrar para salvar meu estudo',{exact:true})).toBeVisible();
  await login(page,'a@example.com');await page.getByRole('button',{name:/^Meu estudo(?:\s|$)/}).first().click();
  await expect(page.locator('flt-semantics').getByText('0 de 10 questões diferentes',{exact:true})).toBeVisible();
  history.set(userA+'freeStudy',[{topicId:'porcentagem',questionId:'fixture-one',correct:true},{topicId:'porcentagem',questionId:'fixture-two',correct:false},{topicId:'porcentagem',questionId:'fixture-two',correct:false}]);
  await click(page,'Atualizar meu estudo');
  await expect(page.locator('flt-semantics').getByText('2 de 10 questões diferentes',{exact:true})).toBeVisible();
  await expect(page.locator('flt-semantics').getByText('1 acerto em 3 tentativas',{exact:true})).toBeVisible();
  await click(page,'10 questões');await page.getByRole('menuitem',{name:'5 questões',exact:true}).click();
  await expect(page.locator('flt-semantics').getByText('2 de 5 questões diferentes',{exact:true})).toBeVisible();
  await page.screenshot({path:`${output}/${viewport.width}-dashboard.png`,fullPage:true});
  await page.getByRole('checkbox',{name:'Banco do Brasil',exact:true}).click();await expect(page.locator('flt-semantics').getByText('0 de 10 questões diferentes',{exact:true})).toBeVisible();
  await page.goto(url+'/#/conta');await click(page,'Sair da conta');await login(page,'b@example.com');await page.getByRole('button',{name:/^Meu estudo(?:\s|$)/}).first().click();
  await expect(page.locator('flt-semantics').getByText('0 de 10 questões diferentes',{exact:true})).toBeVisible();
  expect(pageErrors).toEqual([]);reports.push({viewport,flows:5,internalErrors:pageErrors,transport:'controlled test fixture; no live Firebase/OpenAI'});await context.close();
 }
 await writeFile(`${output}/report.json`,JSON.stringify({reports},null,2));console.log(JSON.stringify({viewports:reports.length,flows:reports.reduce((n,r)=>n+r.flows,0),internalErrors:0,transport:'controlled'},null,2));
}catch(error){if(lastPage&&!lastPage.isClosed()){await lastPage.screenshot({path:`${output}/failure.png`});await writeFile(`${output}/failure-aria.txt`,await lastPage.locator('body').ariaSnapshot());}throw error;}finally{await browser.close();}
