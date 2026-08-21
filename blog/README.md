# Blog

Vite + React. Source lives here, built output is committed to `dist/`.

```bash
npm install     # once
npm run dev     # local dev with hot reload
npm run build   # writes dist/ — commit it
```

## Writing a post

Export from Google Docs as `.html` and drop it into `posts/`. The filename
is the URL slug (`posts/my-post.html` → `#/post/my-post`). The post title
is read from the Google Docs title paragraph in the export.

Optional metadata for the post card goes in an HTML comment at the very top
of the file, before `<html>`:

```html
<!--
---
date: 2026-07-22
description: One line shown on the post card.
image: my-post.png
gif: my-post.gif
---
-->
```

All fields are optional. Posts are sorted newest first by `date`
(use `YYYY-MM-DD`).

Inline images referenced in the HTML (e.g. `images/photo.png`) go in
`posts/images/` or a similar path under `posts/`.

## Artwork

Each post card is a full-bleed image, darkened, with the title, date and
description sitting on top. On hover the card cross-fades to the gif.
Off hover it shows the first frame only (the gif is unmounted so it
actually stops, not just hidden).

Drop card artwork into `media/` and reference it by filename in the comment
block:

- `image:` — the still frame shown at rest
- `gif:` — the animated version shown on hover (also works with animated
  webp/avif, or an animated svg)

Give only a `gif` and the card freezes frame 0 at rest, then plays on hover.
Give neither and the card falls back to a graybox stripe pattern. A full URL
also works if you'd rather host artwork elsewhere.

If you give a separate `image`, the gif is only downloaded once a card is
hovered, so a long list of posts stays cheap to load. Landscape artwork around
16:9 suits the card shape; it is cropped with `object-fit: cover` and rendered
with `image-rendering: pixelated` to match the game's art.

Then `npm run build` and commit `dist/`.
