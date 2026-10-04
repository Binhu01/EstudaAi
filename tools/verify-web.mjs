import { chromium, expect } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
import { enableSemantics, heroClip, navigate, navigationControl, revealPainted } from './web-verification-helpers.mjs';

const url = process.env.PREVIEW_URL ?? 'http://127.0.0.1:4173';
const output = 'artifacts/screenshots';
await mkdir(output, { recursive: true });
const browser = await chromium.launch();
const reports = [];
let lastPage;

async function openHome(page) {
  await enableSemantics(page);
  await expect(page.getByText('Seu próximo nível começa com uma descoberta.', { exact: true })).toBeVisible();
}

async function motionFrames(page, target, moving, label) {
  const clip = await heroClip(page, target);
  await page.waitForTimeout(700);
  const first = await page.screenshot({ clip, path: output + '/' + label + '-' + target + '-a.png' });
  await page.waitForTimeout(800);
  const second = await page.screenshot({ clip, path: output + '/' + label + '-' + target + '-b.png' });
  expect(second.equals(first), target + (moving ? ' visibly changes: ' : ' keeps its own pixels unchanged: ') + label).toBe(!moving);
  return { target, clip, moving, intervalMs: 800 };
}

async function disableHero(page) {
  await navigate(page, 'Preferências');
  await expect(page.getByText('Aparência', { exact: true })).toBeVisible();
  const motion = page.getByRole('switch', { name: /^Animação do hero(?:\s|$)/ });
  const readingSpacing = page.getByRole('switch', { name: /^Mais espaço entre linhas(?:\s|$)/ });
  await expect(motion).toBeChecked();
  await expect(readingSpacing).not.toBeChecked();
  await revealPainted(page, motion);
  await motion.click();
  await expect(motion).not.toBeChecked();
  await expect(readingSpacing).not.toBeChecked();
  await expect.poll(() => page.evaluate(() => localStorage.getItem('flutter.animate'))).toBe('false');
}

try {
  for (const viewport of [{ width: 1440, height: 1000 }, { width: 360, height: 800 }, { width: 768, height: 1024 }]) {
    const context = await browser.newContext({ viewport, colorScheme: 'light', reducedMotion: 'no-preference' });
    const page = await context.newPage();
    lastPage = page;
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    await page.goto(url);
    await openHome(page);
    await page.waitForTimeout(500);
    await page.screenshot({ path: output + '/' + viewport.width + '-light.png' });
    const active = [
      await motionFrames(page, 'shader', true, viewport.width + '-active'),
      await motionFrames(page, 'brain', true, viewport.width + '-active'),
    ];
    await navigate(page, 'Preferências');
    await expect(page.getByText('Aparência', { exact: true })).toBeVisible();
    const dark = page.getByRole('button', { name: 'Escuro', exact: true });
    await revealPainted(page, dark);
    await dark.click();
    await expect.poll(() => page.evaluate(() => localStorage.getItem('flutter.theme'))).toBe('"dark"');
    await disableHero(page);
    await navigate(page, 'Início');
    await openHome(page);
    const paused = [
      await motionFrames(page, 'shader', false, viewport.width + '-dark-paused'),
      await motionFrames(page, 'brain', false, viewport.width + '-dark-paused'),
    ];
    await page.screenshot({ path: output + '/' + viewport.width + '-dark-paused.png' });
    await page.reload();
    await openHome(page);
    const reopened = [
      await motionFrames(page, 'shader', false, viewport.width + '-dark-reopened'),
      await motionFrames(page, 'brain', false, viewport.width + '-dark-reopened'),
    ];
    await expect.poll(() => page.evaluate(() => localStorage.getItem('flutter.theme'))).toBe('"dark"');
    await expect.poll(() => page.evaluate(() => localStorage.getItem('flutter.animate'))).toBe('false');
    // Focus a real navigation control; utility pages may need the drawer.
    await (await navigationControl(page, 'Preferências')).focus();
    await page.keyboard.press('Enter');
    await expect(page.getByText('Aparência', { exact: true })).toBeVisible();
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.getAttribute('role'));
    expect(focused).toBeTruthy();
    expect(errors).toEqual([]);
    reports.push({ viewport, consoleErrors: errors.length, active, paused, reopened, persisted: true, keyboard: true });
    await context.close();
  }
  const reduced = await browser.newContext({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce' });
  const page = await reduced.newPage();
  lastPage = page;
  await page.goto(url);
  await openHome(page);
  const reducedMotion = {
    shader: await motionFrames(page, 'shader', false, 'desktop-reduced-motion'),
    // The user explicitly requested the brain to loop despite reduced motion.
    brain: await motionFrames(page, 'brain', true, 'desktop-reduced-motion-user-loop'),
  };
  await disableHero(page);
  await navigate(page, 'Início');
  await openHome(page);
  reducedMotion.brainDisabled = await motionFrames(page, 'brain', false, 'desktop-reduced-motion-disabled');
  await reduced.close();
  await writeFile('artifacts/web-verification.json', JSON.stringify({ reports, reducedMotion }, null, 2) + '\n');
  console.log(JSON.stringify({ reports, reducedMotion }));
} catch (error) {
  if (lastPage && !lastPage.isClosed()) {
    await Promise.allSettled([
      lastPage.screenshot({ path: output + '/failure.png' }),
      lastPage.locator('body').ariaSnapshot().then(snapshot => writeFile(output + '/failure-aria.txt', snapshot)),
    ]);
  }
  throw error;
} finally { await browser.close(); }
