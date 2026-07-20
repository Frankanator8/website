# Blog

Vite + React. Source lives here, built output is committed to `dist/`.

```bash
npm install     # once
npm run dev     # local dev with hot reload
npm run build   # writes dist/ — commit it
```

## Writing a post

Drop a `.md` file into `posts/`. The filename is the URL slug
(`posts/my-post.md` → `#/post/my-post`). Frontmatter:

```md
---
title: My post
date: 2026-07-19
description: One line shown on the post card.
image: my-post.png
gif: my-post.gif
---

Body in markdown.
```

All fields are optional. Posts are sorted newest first by `date`
(use `YYYY-MM-DD`); a missing `title` falls back to the slug.

## Artwork

Each post card is a full-bleed image, darkened, with the title, date and
description sitting on top. On hover the card cross-fades to the gif.

Drop artwork into `media/` and reference it by filename:

- `image:` — the still frame shown at rest
- `gif:` — the animated version shown on hover (also works with animated
  webp/avif, or an animated svg)

Give only a `gif` and it is used for both states. Give neither and the card
falls back to a graybox stripe pattern. A full URL also works if you'd rather
host artwork elsewhere.

Gifs are only downloaded once a card is actually hovered, so a long list of
posts stays cheap to load. Landscape artwork around 16:9 suits the card shape;
it is cropped with `object-fit: cover` and rendered with `image-rendering:
pixelated` to match the game's art.

Then `npm run build` and commit `dist/`.
