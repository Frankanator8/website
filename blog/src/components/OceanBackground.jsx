/* Pixel-art river. A tiny canvas (a couple hundred pixels wide) is drawn
   per frame and stretched over the viewport with image-rendering: pixelated,
   so every "pixel" is a fat visible block. Motion is quantised to a low
   frame rate too — smooth interpolation would give the game feel away.

   The scene is drawn at FULL brightness — saturated golden-hour colour. The
   page dims it with a pure-black veil (.bg-canvas::after), which keeps the
   hues intact instead of washing them out toward grey-purple. That veil is
   heaviest across the top of the viewport, so header text always lands on a
   near-black band no matter what the sky is doing behind it. */

import { useEffect, useRef } from 'react';

const W = 192; // internal canvas size, in fat pixels
const H = 108;
const FPS = 16; // stepped, game-like motion — still held frames, just more of them
const WATER_SPEED = 0.22; // water's own clock, slower than sky/window time

// Golden hour. Water is lit → shadowed; index 0 is the sun catching a crest.
const WATER = [
  [255, 243, 214], // sun sparkle
  [248, 199, 120], // gold crest
  [222, 146,  86], // lit ripple
  [134, 112, 122], // mid — where warm light gives way to cool shadow
  [ 66,  90, 132], // shadowed, reflecting the cool part of the sky
  [ 36,  57,  96], // deep
  [ 20,  34,  62], // darkest
];

// Dusk sky, top of frame → horizon.
const SKY = [
  [ 42, 54, 104],
  [ 92, 62, 102],
  [168, 82,  84],
  [226, 122, 68],
  [255, 176, 88],
];

const BANK = [24, 27, 50];        // far shore, backlit into near-silhouette
const CITY_FAR = [58, 52, 92];    // back row of towers, hazed by distance
const CITY_NEAR = [26, 24, 46];   // front row, near-silhouette
const WINDOW = [255, 208, 120];   // a lit office
const WINDOW_DIM = [186, 140, 108];

// Cheap integer hash → 0..1, for scattering sparkle pixels.
function hash(x, y, t) {
  // Math.imul throughout: a plain `*` here goes through a double and drops
  // the low bits, which skews every result below 0.5.
  let n = (Math.imul(x, 374761393) + Math.imul(y, 668265263) + Math.imul(t, 1442695040)) | 0;
  n = Math.imul(n ^ (n >>> 13), 1274126177);
  return ((n ^ (n >>> 16)) >>> 0) / 4294967296;
}

const HORIZON = Math.floor(H * 0.30); // where the far bank meets the water

// Deterministic pseudo-random, so the skyline is the same every reload.
function rng(seed) {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) % 4294967296;
    return s / 4294967296;
  };
}

/* Manhattan across the water: two rows of towers. Each row is a run of
   boxes of random width and height, with the odd spire or setback on top.
   Stored as a top-y per column — 0 columns mean "no building here". */
function buildSkyline(seed, minH, maxH, spireChance) {
  const top = new Int16Array(W).fill(HORIZON);
  const rand = rng(seed);
  let x = 0;
  while (x < W) {
    const w = 3 + Math.floor(rand() * 9);
    const gap = rand() < 0.18 ? 1 + Math.floor(rand() * 3) : 0;
    const h = minH + Math.floor(rand() * (maxH - minH));
    const roof = HORIZON - h;

    for (let i = 0; i < w && x + i < W; i += 1) top[x + i] = roof;

    // A setback step or a needle spire on the taller towers.
    if (rand() < spireChance && w >= 4) {
      const sx = x + Math.floor(w / 2);
      const sh = 2 + Math.floor(rand() * 5);
      if (sx < W) top[sx] = roof - sh;
      if (sx + 1 < W && rand() < 0.5) top[sx + 1] = roof - sh;
    } else if (rand() < 0.35 && w >= 5) {
      for (let i = 1; i < w - 1 && x + i < W; i += 1) top[x + i] = roof - 1;
    }

    x += w + gap;
  }
  return top;
}

const CITY_BACK = buildSkyline(20240719, 5, 15, 0.3);
const CITY_FRONT = buildSkyline(981221, 3, 10, 0.18);

/* Two landmark towers, so the skyline has a profile instead of an even run
   of boxes — one broad-shouldered, one needle. */
function landmark(top, cx, width, height, spire) {
  const roof = HORIZON - height;
  for (let i = -width; i <= width; i += 1) {
    const x = cx + i;
    if (x < 0 || x >= W) continue;
    // shoulders step in as the tower rises
    top[x] = roof + (Math.abs(i) > width - 2 ? 3 : 0);
  }
  for (let i = 0; i < spire; i += 1) {
    if (cx + i < W) top[cx + i] = roof - (i === 0 ? 8 : 5);
  }
}
landmark(CITY_BACK, 54, 4, 22, 1);
landmark(CITY_BACK, 139, 3, 26, 2);

function draw(img, frame) {
  const t = frame / FPS;
  const data = img.data;
  const depthRows = H - HORIZON;
  const skyRows = HORIZON - 5;
  const sunX = W * 0.62; // low sun, a little right of centre

  for (let y = 0; y < H; y += 1) {
    for (let x = 0; x < W; x += 1) {
      let col;

      if (y < HORIZON) {
        // Sky: full sunset ramp, indigo overhead → hot orange at the horizon.
        // Readability at the top of the page is the veil's job, not the
        // palette's (see .bg-canvas::after).
        const ramp = y / HORIZON;
        col = SKY[Math.min(SKY.length - 1, Math.floor(ramp * SKY.length))];

        // City. Front row wins where the two overlap.
        const near = y >= CITY_FRONT[x];
        const far = y >= CITY_BACK[x];
        if (near || far) {
          col = near ? CITY_NEAR : CITY_FAR;

          // Windows on a regular grid — the giveaway that it is a city and
          // not a mountain range. A few flip on and off over time.
          const onGrid = x % 3 !== 0 && y % 2 === 0 && y < HORIZON - 1;
          if (onGrid) {
            const lit = hash(x, y, 1);
            const flicker = hash(x, y, 2 + Math.floor(t / 2.5));
            if (lit > (near ? 0.6 : 0.78) && flicker > 0.25) {
              col = near ? WINDOW : WINDOW_DIM;
            }
          }
        }

        // Thin strip of shore where the city meets the water.
        if (y >= HORIZON - 1) col = BANK;
      } else {
        // Ground-plane projection. v runs 0 at the horizon → 1 at the near
        // edge; distance is 1/v, so equal steps of water occupy fewer and
        // fewer rows as they recede. That squeeze is the whole perspective.
        const v = (y - HORIZON + 0.5) / depthRows;
        const wz = Math.min(1.2 / v, 46);

        // Sideways spread widens with distance, and the whole surface slides
        // downstream past the bank (left to right) over time. Water runs on
        // its own slowed clock — WATER_SPEED — separate from t, which still
        // drives the sky (sun, window flicker) at normal pace.
        const wt = t * WATER_SPEED;
        const wx = (x - W / 2) * wz * 0.045 + wt * 3.2;

        let h =
          Math.sin(wz * 2.6 + wt * 1.2) +
          0.7 * Math.sin(wz * 1.3 + wx * 0.6 - wt * 0.9) +
          0.45 * Math.sin(wx * 1.5 - wz * 0.8 + wt * 2.4) +
          // fine chop, only close in — far water is too small to resolve it
          0.3 * v * Math.sin(wx * 4.1 + wz * 2.7 - wt * 3.6);

        // Distance haze: far water flattens toward a single mid tone (and
        // keeps the compressed rows near the horizon from aliasing).
        h *= 0.25 + 0.75 * v;

        // Sun glitter: a cone of light widening from the horizon toward us.
        // Only crests inside it catch the sun, which is what makes the
        // scattered gold path across the water.
        const spread = 7 + 60 * v;
        const d = (x - sunX) / spread;
        const glitter = Math.exp(-d * d);
        h += glitter * 1.5;

        let idx = Math.round(4.0 - h * 1.35);
        if (idx < 1) idx = 1;
        if (idx > 6) idx = 6;

        // Sparkle only where the sun actually reaches.
        if (glitter > 0.25 && h > 2.3) idx = 0;
        if (idx <= 2 && glitter > 0.3 && hash(x, y + Math.floor(wt * 24), Math.floor(wt * 8)) > 0.99) {
          idx = 0;
        }

        col = WATER[idx];
      }

      const p = (y * W + x) * 4;
      data[p] = col[0];
      data[p + 1] = col[1];
      data[p + 2] = col[2];
      data[p + 3] = 255;
    }
  }
}

export default function OceanBackground() {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return undefined;
    const ctx = canvas.getContext('2d');
    const img = ctx.createImageData(W, H);

    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduced) {
      draw(img, 0);
      ctx.putImageData(img, 0, 0);
      return undefined;
    }

    let raf = 0;
    let last = 0;
    let frame = 0;

    const loop = (now) => {
      raf = requestAnimationFrame(loop);
      if (now - last < 1000 / FPS) return; // hold each frame, no tweening
      last = now;
      draw(img, (frame += 1));
      ctx.putImageData(img, 0, 0);
    };

    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, []);

  return (
    <div className="bg-canvas" aria-hidden="true">
      <canvas
        ref={canvasRef}
        className="river"
        width={W}
        height={H}
      />
    </div>
  );
}
