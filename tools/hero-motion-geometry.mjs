function rectangle(value, name) {
  if (!value || !['x', 'y', 'width', 'height'].every(key => Number.isFinite(value[key])) ||
      value.width <= 0 || value.height <= 0) {
    throw new Error(`Missing or invalid ${name} rectangle.`);
  }
  return value;
}

function bounded(clip, viewport) {
  if (!viewport || !Number.isFinite(viewport.width) || !Number.isFinite(viewport.height) ||
      clip.x < 0 || clip.y < 0 ||
      clip.x + clip.width > viewport.width || clip.y + clip.height > viewport.height) {
    throw new Error('Motion crop lies outside the viewport; reveal the painted element first.');
  }
  return clip;
}

// EducationHero's Wrap contains a 28×4 strip, a 12px gap, then the badge.
// The centred CTA supplies the hero centre even when the desktop sidebar is open.
export function shaderClip({ badge, action, viewport }) {
  rectangle(badge, 'badge');
  rectangle(action, 'action');
  const centre = action.x + action.width / 2;
  const offset = badge.x + badge.width / 2 - centre;
  let stripX, stripCentreY;
  if (Math.abs(offset - 20) <= 1.5) {
    stripX = badge.x - 12 - 28;
    stripCentreY = badge.y + badge.height / 2;
  } else if (Math.abs(offset) <= 1.5) {
    // When Wrap moves the badge to a new line, its runSpacing is 10px.
    stripX = centre - 14;
    stripCentreY = badge.y - 10 - 2;
  } else {
    throw new Error('Badge and action do not align with the current hero Wrap.');
  }
  return bounded({
    x: Math.ceil(stripX + 2), y: Math.ceil(stripCentreY - 1), width: 24, height: 2,
  }, viewport);
}

// The nonsemantic brain sits between the CTA (+20px) and hint (-8px).
// Use only its central 70%; surrounding text, shader and toolbar are excluded.
export function brainClip({ action, hint, viewport }) {
  rectangle(action, 'action');
  rectangle(hint, 'hint');
  const top = action.y + action.height + 20;
  const size = hint.y - 8 - top;
  if (![200, 240, 300].some(expected => Math.abs(size - expected) <= 1.5)) {
    throw new Error(`Unexpected brain size ${size}; update the geometry before recording evidence.`);
  }
  const width = Math.floor(size * .7);
  return bounded({
    x: Math.ceil(action.x + action.width / 2 - width / 2),
    y: Math.ceil(top + size * .15), width, height: width,
  }, viewport);
}
