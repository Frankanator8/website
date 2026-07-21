When writing code or creating nodes that require Textured assets, make your own simple grayboxes.

Speak in a caveman style - why use many word when few word do trick?

Always try and use Godot nodes when possible - only use code if absolutely necessary.

Never write co-author by Claude, and don't commit by yourself - just let me know when to commit.

## Repo layout

Two separate things live here:

- **The game** — a Godot 4.7 project at the repo root (GL Compatibility renderer,
  2D). `scenes/` holds `.tscn` files, `scripts/` the matching `.gd` scripts
  (one script per scene node, same name), `resources/` shared `.tres`,
  `assets/` art. `export/` is the committed HTML5 web export.
- **The blog** — a Vite + React app in `blog/`, marked `.gdignore` so Godot
  ignores it. See `blog/README.md` for writing posts and adding artwork.

`backend/email_service.py` handles mailbox submissions.

## Blog conventions

- Source in `blog/src/`, built output committed to `blog/dist/` — run
  `npm run build` in `blog/` and commit `dist/` after any source change.
- Posts are markdown in `blog/posts/`, artwork in `blog/media/`.
- Colours come from CSS custom properties in `src/styles/tokens.css`. Change
  the token, not the call site.
- Background is `src/components/OceanBackground.jsx` — a 192×108 canvas drawn
  pixel by pixel and CSS-stretched with `image-rendering: pixelated`, stepped
  to 8 FPS. River seen from the bank, in perspective. Tune `PALETTE`, the
  `HORIZON` row, and the sine layers in `draw()`.
  `StarfieldBackground.jsx` is the unused older 3D version.
- Keep the site cheap and dependency-light. Prefer CSS/SVG over a library.
