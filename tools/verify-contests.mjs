import { chromium, expect } from '@playwright/test';
import { mkdir, readFile, writeFile } from 'node:fs/promises';

const url = process.env.PREVIEW_URL ?? 'http://127.0.0.1:4173';
const output = 'artifacts/concursos-bb2026/verification';
const catalog = JSON.parse(await readFile('apps/client/assets/contests/bb2026/catalog.json', 'utf8'));
expect(catalog.disciplines).toHaveLength(9);
expect(catalog.disciplines.flatMap(d => d.modules)).toHaveLength(126);
expect(catalog.disciplines.flatMap(d => d.modules.flatMap(m => m.questions))).toHaveLength(756);
await mkdir(output, { recursive: true });
const browser = await chromium.launch();
const reports = [];
let lastPage;
const escape = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
function navigation(page, name) {
  const prefix = new RegExp(`^${name}(?:\\s|$)`);
  return page.getByRole('button', {name:prefix}).or(page.getByRole('tab', {name:prefix})).first();
}
async function click(page, name, exact = true) {
  const item = page.getByRole('button', {name:exact ? name : new RegExp(escape(name)), exact}).first();
  await item.scrollIntoViewIfNeeded(); await item.click();
}
async function route(page, expected) { await expect(page).toHaveURL(new RegExp(`#${escape(expected)}$`)); }
async function enable(page) {
  const placeholder = page.locator('flt-semantics-placeholder');
  await page.locator('flt-semantics-placeholder, flt-semantics').first().waitFor({state:'attached'});
  if (await placeholder.count()) await placeholder.dispatchEvent('click');
}
async function revealPainted(page, locator) {
  // Flutter paints to canvas; DOM scrollIntoView alone can move only semantics.
  const surface = await page.locator('flutter-view').boundingBox();
  expect(surface).toBeTruthy();
  const viewport = page.viewportSize();
  await page.mouse.move(surface.x + surface.width / 2, surface.y + surface.height / 2);
  for (let attempt=0;attempt<30;attempt++) {
    const box = await locator.boundingBox();
    expect(box).toBeTruthy();
    if(box.y>=80 && box.y+box.height<viewport.height-150) return box;
    await page.mouse.wheel(0,box.y<80?-180:180);
    await page.waitForTimeout(120);
  }
  throw new Error(`Painted content did not enter the reading area: ${await locator.textContent()}`);
}
function external(address) {
  try { return /(^|\.)(youtube\.com|googlevideo\.com|ytimg\.com|google\.com|gstatic\.com|doubleclick\.net)$/.test(new URL(address).hostname); }
  catch { return false; }
}
try {
  for (const viewport of [{width:1440,height:1000},{width:360,height:800},{width:768,height:1024}]) {
    const context = await browser.newContext({viewport,reducedMotion:'reduce'});
    const page = await context.newPage(); lastPage = page;
    const pageErrors=[],consoleErrors=[],modules=[];
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('console', message => {if(message.type()==='error')consoleErrors.push({text:message.text(),url:message.location().url});});
    await page.goto(url); await enable(page);
    await expect(page.getByText('Seu próximo nível começa com uma descoberta.',{exact:true})).toBeVisible();
    await navigation(page,'Concursos').click(); await route(page,'/concursos');
    await click(page,catalog.course.title,false); await route(page,'/concursos/bb2026');
    await expect(page.getByText('Preparação',{exact:true})).toBeVisible();
    await page.screenshot({path:`${output}/${viewport.width}-curso.png`});
    for (const discipline of catalog.disciplines) {
      await click(page,discipline.title,false); await route(page,`/concursos/bb2026/${discipline.id}`);
      const module = discipline.modules[discipline.id==='financeira'?6:discipline.id==='informatica'?4:discipline.id==='redacao'?4:0];
      const prefix=`/concursos/bb2026/${discipline.id}/${module.id}`;
      await click(page,module.title,false); await route(page,`${prefix}/material`);
      await expect(page.getByText('Material autoral · Estuda Aí',{exact:true})).toBeVisible();
      for (const objective of module.objectives) expect(await page.getByText(objective,{exact:true}).count()).toBeGreaterThan(0);
      if(['financeira','informatica','redacao'].includes(discipline.id)) await page.screenshot({path:`${output}/${viewport.width}-${discipline.id}-material.png`});
      if(['financeira','informatica'].includes(discipline.id)) expect(module.blocks.some(block=>block.type==='table'),`${module.id} must exercise a real table`).toBe(true);
      const materialChecks=[];
      for (const type of ['formula','table']) {
        const block = module.blocks.find(block => block.type === type);
        if (block && ['financeira','informatica'].includes(discipline.id)) {
          const target=page.getByText(type==='formula'?block.expression:block.columns[0],{exact:true});
          const box=await revealPainted(page,target);
          await page.screenshot({path:`${output}/${viewport.width}-${discipline.id}-${type}.png`});
          if(type==='table') {
            const before=await page.getByText(block.columns.at(-1),{exact:true}).boundingBox();
            if(viewport.width===360) {
              // A physical horizontal gesture also exercises the painted table.
              await page.mouse.move(box.x+box.width/2,box.y+box.height/2);
              await page.mouse.wheel(block.columns.length*240,0);await page.waitForTimeout(200);
              const after=await page.getByText(block.columns.at(-1),{exact:true}).boundingBox();
              expect(after.x).toBeLessThan(before.x);
              expect(after.x+after.width).toBeLessThanOrEqual(viewport.width);
              await page.screenshot({path:`${output}/${viewport.width}-${discipline.id}-table-scrolled.png`});
            }
          }
          materialChecks.push({type,paintedBounds:box,horizontal: type==='table'&&viewport.width===360});
        }
      }
      await click(page,'Aulas de apoio'); await route(page,`${prefix}/aulas`);
      expect(await page.locator('iframe').count()).toBe(0);
      await click(page,discipline.lessons[0].title,false);
      await expect(page.locator(`iframe[src*="/embed/${discipline.lessons[0].videoId}"]`)).toHaveCount(1);
      expect(await page.getByRole('button',{name:'Abrir no YouTube',exact:true}).count()).toBe(1);
      await click(page,'Desafio 8 bits'); await route(page,`${prefix}/desafio`);
      await click(page,'Começar desafio');
      const ids=[];
      for (let index=0;index<5;index++) {
        await expect(page.getByText(`QUESTÃO ${index+1}/5`,{exact:true})).toBeVisible();
        let active;
        for (const question of module.questions) if(await page.getByText(question.prompt,{exact:true}).count()){active=question;break;}
        expect(active,'Current module question is present').toBeTruthy();
        ids.push(active.id);
        await click(page,active.options[active.correctIndex]);
        const feedback=page.getByText(active.explanation,{exact:true});await feedback.scrollIntoViewIfNeeded();await expect(feedback).toBeVisible();
        await click(page,index===4?'Ver resultado':'Próxima pergunta');
      }
      expect(new Set(ids).size).toBe(5);
      await expect(page.getByText('700 / 700 pontos',{exact:true})).toBeVisible();
      if(discipline.id==='ingles') await page.screenshot({path:`${output}/${viewport.width}-quiz.png`});
      await click(page,'Perguntar ao Steve'); await route(page,`${prefix}/steve`);
      await expect(page.getByText('Entre na sua conta para conversar com o Steve.',{exact:true})).toBeVisible();
      await click(page,'Entrar para conversar'); await route(page,'/conta');
      await navigation(page,'Steve').click(); await route(page,`${prefix}/steve`);
      await click(page,'Material'); await route(page,`${prefix}/material`);
      await click(page,'Voltar à disciplina'); await route(page,`/concursos/bb2026/${discipline.id}`);
      await click(page,'Voltar ao concurso');await route(page,'/concursos/bb2026');
      modules.push({discipline:discipline.id,module:module.id,questionIds:ids,score:700,material:true,materialChecks,lazyIframe:true,steveLogin:true,accountContext:true});
      console.log(`Verified ${viewport.width}: ${discipline.id}`);
    }
    await page.goto(`${url}/#/concursos/bb2026/matematica/bb2026-b01/material`);await enable(page);
    await expect(page.getByText('Conteúdo de concurso não encontrado',{exact:true})).toBeVisible();
    await click(page,'Voltar a Concursos');await route(page,'/concursos');
    await page.goto(`${url}/#/aprender/bb2026-b01`);await enable(page);
    await expect(page.getByText('Assunto não encontrado',{exact:true})).toBeVisible();
    await click(page,'Voltar ao início');
    await click(page,'Escolher meu assunto');await click(page,'Interpretação de texto',false);
    await click(page,'Aprender com videoaulas');await route(page,'/aprender/interpretacao-texto');
    await navigation(page,'Concursos').click();await click(page,catalog.course.title,false);
    await navigation(page,'Início').click();await navigation(page,'Aprender').click();await route(page,'/aprender/interpretacao-texto');
    await navigation(page,'Preferências').focus();await page.keyboard.press('Enter');
    await expect(page.getByText('Aparência',{exact:true})).toBeVisible();
    await page.getByRole('checkbox',{name:'Escuro',exact:true}).click();
    expect(await page.evaluate(()=>localStorage.getItem('flutter.theme'))).toBe('"dark"');
    await navigation(page,'Concursos').click();await click(page,catalog.course.title,false);
    await page.screenshot({path:`${output}/${viewport.width}-curso-escuro.png`});
    await page.keyboard.press('Tab');await page.keyboard.press('Control+,');
    await expect(page.getByText('Aparência',{exact:true})).toBeVisible();
    expect(pageErrors).toEqual([]);
    const internalErrors=consoleErrors.filter(error=>!external(error.url));expect(internalErrors).toEqual([]);
    reports.push({viewport,modules,invalidRelation:true,freeAliasRejected:true,freeSelectionPreserved:true,preferencesHeader:viewport.width<600,keyboard:true,dark:true,reducedMotion:true,pageErrors,internalErrors,externalErrors:consoleErrors.filter(error=>external(error.url))});
    await context.close();
  }
  await writeFile(`${output}/report.json`,JSON.stringify({reports,playback:'Iframe/link checked; playback not asserted.',liveAi:'Not verified; real credentials absent.'},null,2)+'\n');
  console.log(JSON.stringify({viewports:reports.length,flows:reports.reduce((n,r)=>n+r.modules.length,0),questions:135,internalErrors:0}));
} catch(error) {
  if(lastPage&&!lastPage.isClosed()) {await lastPage.screenshot({path:`${output}/failure.png`});await writeFile(`${output}/failure-semantics.txt`,(await lastPage.locator('flt-semantics').allTextContents()).join('\n'));}
  throw error;
} finally {await browser.close();}
