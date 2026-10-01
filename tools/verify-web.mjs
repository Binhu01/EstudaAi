import { chromium, expect } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';

const url = process.env.PREVIEW_URL ?? 'http://127.0.0.1:4173';
const output = 'artifacts/screenshots';
await mkdir(output, { recursive: true });
const browser = await chromium.launch();
const reports = [];
async function enableSemantics(page) {
  await page.locator('flt-semantics-placeholder').waitFor();
  await page.locator('flt-semantics-placeholder').dispatchEvent('click');
  await expect(page.getByText('Minha jornada', { exact: true })).toBeVisible();
}
async function stableFrame(page, label) {
  await page.waitForTimeout(700);
  const clip = await shaderClip(page);
  const first = await page.screenshot({ clip });
  await page.waitForTimeout(600);
  const second = await page.screenshot({ clip });
  await page.screenshot({ path: `${output}/${label}.png` });
  expect(second.equals(first), `Paused shader keeps its pixels unchanged: ${label}`).toBe(true);
}
async function shaderClip(page) {
  const heading = await page.getByText(/O que vamos/).boundingBox();
  expect(heading).toBeTruthy();
  const width = page.viewportSize().width;
  return { x: width - (width < 600 ? 16 : 32) - 12, y: heading.y - 12, width: 6, height: 64 };
}
function navigation(page, name) {
  const prefix = new RegExp(`^${name}(?:\\s|$)`);
  return page.getByRole('button', { name: prefix }).or(page.getByRole('tab', { name: prefix })).first();
}
try {
  for (const viewport of [{ width: 1440, height: 1000 }, { width: 360, height: 800 }, { width: 768, height: 1024 }]) {
    const context = await browser.newContext({ viewport, colorScheme: 'light' });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    await page.goto(url);
    await enableSemantics(page);
    await page.waitForTimeout(500);
    await page.screenshot({ path: `${output}/${viewport.width}-light.png` });
    const clip = await shaderClip(page);
    const light = await page.screenshot({ clip });
    await page.waitForTimeout(800);
    const animated = await page.screenshot({ clip });
    expect(animated.equals(light), 'Shader visibly changes').toBe(false);
    await navigation(page, 'Preferências').click();
    await expect(page.getByText('Aparência', { exact: true })).toBeVisible();
    await page.getByRole('checkbox', { name: 'Escuro', exact: true }).click();
    const motion = page.getByRole('switch');
    await motion.scrollIntoViewIfNeeded();
    await motion.click();
    await page.waitForTimeout(300);
    expect(await page.evaluate(() => localStorage.getItem('flutter.theme'))).toBe('"dark"');
    expect(await page.evaluate(() => localStorage.getItem('flutter.animate'))).toBe('false');
    await navigation(page, 'Início').click();
    await expect(page.getByText('Minha jornada', { exact: true })).toBeVisible();
    await stableFrame(page, `${viewport.width}-dark-paused`);
    await page.reload();
    await enableSemantics(page);
    await stableFrame(page, `${viewport.width}-dark-reopened`);
    expect(await page.evaluate(() => localStorage.getItem('flutter.theme'))).toBe('"dark"');
    // A real keyboard pass: Tab focuses a control and Enter opens preferences.
    await navigation(page, 'Preferências').focus();
    await page.keyboard.press('Enter');
    await expect(page.getByText('Aparência', { exact: true })).toBeVisible();
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.getAttribute('role'));
    expect(focused).toBeTruthy();
    expect(errors).toEqual([]);
    reports.push({ viewport, consoleErrors: errors.length, animated: true, paused: true, persisted: true, keyboard: true });
    await context.close();
  }
  const reduced = await browser.newContext({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce' });
  const page = await reduced.newPage();
  await page.goto(url);
  await enableSemantics(page);
  await stableFrame(page, 'desktop-reduced-motion');
  await reduced.close();
  await writeFile('artifacts/web-verification.json', JSON.stringify({ reports, reducedMotion: true }, null, 2) + '\n');
  console.log(JSON.stringify({ reports, reducedMotion: true }));
} finally { await browser.close(); }
