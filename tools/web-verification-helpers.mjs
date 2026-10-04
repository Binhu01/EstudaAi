import { expect } from '@playwright/test';
import { brainClip, shaderClip } from './hero-motion-geometry.mjs';

const escape = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export async function enableSemantics(page) {
  const placeholder = page.locator('flt-semantics-placeholder');
  await page.locator('flt-semantics-placeholder, flt-semantics').first().waitFor({ state: 'attached' });
  if (await placeholder.count()) await placeholder.dispatchEvent('click');
}

function destinations(page, name) {
  const prefix = new RegExp(`^${escape(name)}(?:\\s|$)`);
  return page.getByRole('button', { name: prefix }).or(page.getByRole('tab', { name: prefix }));
}

export async function navigationControl(page, name) {
  const controls = destinations(page, name);
  for (const control of await controls.all()) {
    if (await control.isVisible()) return control;
  }
  // Utility pages have no mobile bottom navigation; tablets use the drawer too.
  const menu = page.getByRole('button', {
    name: /^(?:Abrir menu de navegação|Expandir menu lateral)$/, exact: true,
  });
  await expect(menu).toBeVisible();
  await menu.click();
  await expect(controls.first()).toBeVisible();
  return controls.first();
}

export async function navigate(page, name) {
  await (await navigationControl(page, name)).click();
}

export async function revealPainted(page, locator) {
  // Flutter paints to canvas: scrolling only the semantics DOM is insufficient.
  const surface = await page.locator('flutter-view').boundingBox();
  expect(surface).toBeTruthy();
  const viewport = page.viewportSize();
  await page.mouse.move(surface.x + surface.width / 2, viewport.height / 2);
  for (let attempt = 0; attempt < 40; attempt++) {
    const box = await locator.boundingBox();
    expect(box).toBeTruthy();
    if (box.y >= 80 && box.y + box.height < viewport.height - 64) return box;
    await page.mouse.wheel(0, box.y < 80 ? -180 : 180);
    await page.waitForTimeout(120);
  }
  throw new Error(`Painted content did not enter the viewport: ${await locator.textContent()}`);
}

export async function heroClip(page, target) {
  const semantics = page.locator('flt-semantics');
  const action = page.getByRole('button', { name: 'Escolher meu assunto', exact: true });
  const anchor = semantics.getByText(
    target === 'shader' ? 'CONHECIMENTO ABRE CAMINHOS' : 'Explore os assuntos abaixo',
    { exact: true },
  );
  const anchorBox = await revealPainted(page, anchor);
  const actionBox = await action.boundingBox();
  const viewport = page.viewportSize();
  if (target === 'shader') return shaderClip({ badge: anchorBox, action: actionBox, viewport });
  if (target === 'brain') return brainClip({ hint: anchorBox, action: actionBox, viewport });
  throw new Error(`Unknown motion target: ${target}`);
}
