import assert from 'node:assert/strict';
import { test } from 'node:test';
import { brainClip, shaderClip } from '../hero-motion-geometry.mjs';

const viewport = { width: 1440, height: 1000 };
const action = { x: 730, y: 420, width: 240, height: 56 };
const inlineBadge = { x: 730, y: 190, width: 280, height: 18 };

test('shader crop samples the inline strip, never the badge or brain', () => {
  const clip = shaderClip({ badge: inlineBadge, action, viewport });
  assert.deepEqual(clip, { x: 692, y: 198, width: 24, height: 2 });
  assert.ok(clip.x + clip.width < inlineBadge.x);
  assert.ok(clip.y + clip.height < action.y);
});

test('compact wrapped shader remains centred above the badge', () => {
  const clip = shaderClip({
    badge: { x: 25, y: 120, width: 310, height: 36 },
    action: { x: 60, y: 430, width: 240, height: 56 },
    viewport: { width: 360, height: 800 },
  });
  assert.deepEqual(clip, { x: 168, y: 107, width: 24, height: 2 });
  assert.ok(clip.y + clip.height < 120);
});

test('subpixel shader bounds stay inside the four-pixel strip', () => {
  const clip = shaderClip({
    badge: { ...inlineBadge, x: 730.25, y: 190.25 },
    action: { ...action, x: 730.25 }, viewport,
  });
  assert.equal(clip.width, 24);
  assert.equal(clip.height, 2);
  assert.ok(clip.y >= 197.25 && clip.y + clip.height <= 201.25);
});

test('incoherent badge geometry fails instead of sampling unrelated content', () => {
  assert.throws(() => shaderClip({ badge: { ...inlineBadge, x: 790 }, action, viewport }), /align/);
});

test('offscreen shader crop must be revealed before capture', () => {
  assert.throws(() => shaderClip({ badge: { ...inlineBadge, y: -30 }, action, viewport }), /viewport/);
});

test('desktop brain crop excludes button and hint', () => {
  const hint = { x: 755, y: 804, width: 190, height: 18 };
  const clip = brainClip({ action, hint, viewport });
  assert.deepEqual(clip, { x: 745, y: 541, width: 210, height: 210 });
  assert.ok(clip.y > action.y + action.height);
  assert.ok(clip.y + clip.height < hint.y);
});

test('compact brain crop is bounded by the actual 240px layout', () => {
  const clip = brainClip({
    action: { x: 60, y: 300, width: 240, height: 56 },
    hint: { x: 85, y: 624, width: 190, height: 18 },
    viewport: { width: 360, height: 800 },
  });
  assert.deepEqual(clip, { x: 96, y: 412, width: 168, height: 168 });
});

test('unknown brain dimensions fail rather than broadening the crop', () => {
  assert.throws(() => brainClip({ action, hint: { x: 755, y: 754, width: 190, height: 18 }, viewport }), /size/);
});

test('invalid or missing rectangles cannot yield motion evidence', () => {
  assert.throws(() => shaderClip({ badge: null, action, viewport }), /rectangle/);
  assert.throws(() => brainClip({ action, hint: { x: NaN, y: 804, width: 190, height: 18 }, viewport }), /rectangle/);
});

test('CUA desktop geometry locates both independent painted crops', () => {
  const observed = {
    badge: { x: 756.987, y: 129.5, width: 225.891, height: 19.059 },
    action: { x: 735.377, y: 431.5, width: 229.234, height: 57 },
    hint: { x: 756.425, y: 816.5, width: 160.918, height: 19.059 },
    viewport: { width: 1440, height: 900 },
  };
  assert.deepEqual(shaderClip(observed), { x: 719, y: 139, width: 24, height: 2 });
  assert.deepEqual(brainClip(observed), { x: 745, y: 554, width: 210, height: 210 });
});

test('CUA mobile geometry excludes the brain from the inline shader crop', () => {
  const observed = {
    badge: { x: 86.987, y: 92, width: 225.891, height: 19.059 },
    action: { x: 65.377, y: 389, width: 229.234, height: 57 },
    hint: { x: 86.425, y: 714, width: 160.918, height: 6.353 },
    viewport: { width: 360, height: 800 },
  };
  assert.deepEqual(shaderClip(observed), { x: 49, y: 101, width: 24, height: 2 });
  assert.deepEqual(brainClip(observed), { x: 96, y: 502, width: 168, height: 168 });
});
