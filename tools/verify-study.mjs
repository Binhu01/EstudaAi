import { chromium, expect } from '@playwright/test';
import { mkdir, readFile, writeFile } from 'node:fs/promises';

const url = process.env.PREVIEW_URL ?? 'http://127.0.0.1:4173';
const output = 'artifacts/study';
const catalog = JSON.parse(await readFile('apps/client/assets/study/catalog.json', 'utf8'));
await mkdir(output, { recursive: true });
const browser = await chromium.launch();
const reports = [];
let lastPage;
const escape = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
function navigation(page, name) {
  const prefix = new RegExp(`^${name}(?:\\s|$)`);
  return page.getByRole('button', { name: prefix }).or(page.getByRole('tab', { name: prefix })).first();
}
async function clickText(page, text) {
  const item = page.getByText(text, { exact: true }).first();
  await item.scrollIntoViewIfNeeded();
  await item.click();
}
async function route(page, expected) { await expect(page).toHaveURL(new RegExp(`#${expected}$`)); }
function external(url) {
  try { return /(^|\.)(youtube\.com|googlevideo\.com|ytimg\.com|google\.com|gstatic\.com|doubleclick\.net)$/.test(new URL(url).hostname); }
  catch { return false; }
}
try {
  for (const viewport of [{ width:1440,height:1000 },{ width:360,height:800 },{ width:768,height:1024 }]) {
    const context = await browser.newContext({ viewport, reducedMotion:'reduce' });
    const page = await context.newPage();
    lastPage = page;
    const pageErrors = [], consoleErrors = [], failedRequests = [], topicReports = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('console', message => { if(message.type()==='error') consoleErrors.push({ text:message.text(),url:message.location().url }); });
    page.on('requestfailed', request => failedRequests.push({url:request.url(),error:request.failure()?.errorText}));
    await page.goto(url);
    await page.locator('flt-semantics-placeholder').dispatchEvent('click');
    await expect(page.getByText('Seu próximo nível começa com uma descoberta.',{exact:true})).toBeVisible();
    await page.waitForTimeout(700); // Let Flutter decode/paint the local hero bitmap.
    await page.screenshot({path:`${output}/${viewport.width}-hero.png`});
    for(const topic of catalog.topics) {
      await clickText(page,'Escolher meu assunto');
      const choice=page.getByRole('button',{name:new RegExp(escape(topic.title))}).first();
      await choice.scrollIntoViewIfNeeded();await choice.click();
      await clickText(page,'Aprender com videoaulas');await route(page,`/aprender/${topic.id}`);
      expect(await page.locator('iframe').count()).toBe(0);
      const lessonChecks=[];
      for(const lesson of topic.lessons) {
        const lessonChoice=page.getByRole('button',{name:new RegExp(escape(lesson.title))}).first();
        await lessonChoice.scrollIntoViewIfNeeded();await lessonChoice.click();
        const frame=page.locator(`iframe[src*="/embed/${lesson.videoId}"]`);
        await expect(frame).toHaveCount(1);
        await expect(frame).toHaveAttribute('src',`https://www.youtube.com/embed/${lesson.videoId}?autoplay=0&rel=0`);
        await expect(frame).toHaveAttribute('title',`Videoaula: ${lesson.title} — ${lesson.channel}`);
        const fallback=page.getByRole('button',{name:'Abrir no YouTube',exact:true});
        await fallback.scrollIntoViewIfNeeded();
        const popupPromise=page.waitForEvent('popup');await fallback.click();
        const popup=await popupPromise;
        await expect(popup).toHaveURL(`https://www.youtube.com/watch?v=${lesson.videoId}`);
        await popup.close();
        lessonChecks.push({videoId:lesson.videoId,iframe:true,fallbackGesture:true});
      }
      await navigation(page,'Desafios').click();await route(page,`/desafios/${topic.id}`);
      await clickText(page,'Começar desafio');
      for(let i=0;i<5;i++) {
        await expect(page.getByText(`QUESTÃO ${i+1}/5`,{exact:true})).toBeVisible();
        let active;
        for(const q of topic.questions) {
          if(await page.getByText(q.prompt,{exact:true}).count()) {active=q;break;}
        }
        expect(active,'Catalog question is present').toBeTruthy();
        const answer=page.getByRole('button',{name:active.options[0],exact:true});
        await answer.scrollIntoViewIfNeeded();await answer.click();
        await expect(page.getByText(active.explanation,{exact:true})).toBeVisible();
        if(i===0) await page.screenshot({path:`${output}/${viewport.width}-${topic.id}-quiz.png`});
        await clickText(page,i===4?'Ver resultado':'Próxima pergunta');
      }
      await expect(page.getByText('RODADA COMPLETA',{exact:true})).toBeVisible();
      await clickText(page,'Assistir aula');await route(page,`/aprender/${topic.id}`);
      await clickText(page,'Perguntar ao Steve');await route(page,`/steve/${topic.id}`);
      await expect(page.getByText('Entre na sua conta para conversar com o Steve.',{exact:true})).toBeVisible();
      await page.screenshot({path:`${output}/${viewport.width}-${topic.id}-steve-login.png`});
      await clickText(page,'Entrar para conversar');await route(page,'/conta');
      await expect(page.getByText('Sua conta',{exact:true})).toBeVisible();
      // No invented login or AI answer: exercise the actual unavailable local boundary once.
      if(topic.id==='porcentagem') {
        const email=page.getByRole('textbox',{name:/E-mail/}), password=page.getByRole('textbox',{name:/Senha/});
        await email.click();await email.focus();
        await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
        await email.pressSequentially('student@example.com',{delay:30});
        await expect(page.getByText(/235 caracteres restantes/)).toBeVisible();
        await password.click();await password.focus();
        await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
        await password.pressSequentially('test-password',{delay:30});
        await clickText(page,'Entrar na conta');
        await expect(page.getByText('O serviço está indisponível no momento. Tente novamente mais tarde.',{exact:true})).toBeVisible();
        await page.screenshot({path:`${output}/${viewport.width}-account-unavailable.png`});
      }
      await navigation(page,'Steve').click();await route(page,`/steve/${topic.id}`);
      await navigation(page,'Início').click();
      topicReports.push({id:topic.id,lessons:lessonChecks,questions:5,feedback:true,result:true,contextPreserved:true});
    }
    expect(pageErrors).toEqual([]);
    const externalErrors=consoleErrors.filter(e=>external(e.url));
    const expectedApiErrors=consoleErrors.filter(e=>/^http:\/\/127\.0\.0\.1:3001\/v1\/auth\/login$/.test(e.url));
    const internalErrors=consoleErrors.filter(e=>!externalErrors.includes(e)&&!expectedApiErrors.includes(e));
    expect(internalErrors).toEqual([]);
    reports.push({viewport,topics:topicReports,pageErrors,internalErrors,externalErrors,expectedApiErrors,failedRequests,
      playback:'Not asserted: iframe and actual fallback gesture verified; third-party playback checked separately.',
      liveAi:'Not verified: Firebase/OpenAI credentials absent; no simulated authentication.'});
    await context.close();
  }
  await writeFile('artifacts/study-verification.json',JSON.stringify({reports},null,2)+'\n');
  console.log(JSON.stringify({viewports:reports.length,topics:reports.reduce((n,r)=>n+r.topics.length,0),questions:45,internalErrors:0}));
} catch(error) {
  if(lastPage && !lastPage.isClosed()) {
    await lastPage.screenshot({path:`${output}/failure.png`});
    await writeFile(`${output}/failure-semantics.txt`,await lastPage.locator('flt-semantics').allTextContents().then(parts=>parts.join('\n')));
  }
  throw error;
} finally { await browser.close(); }
