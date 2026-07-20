---
title: Markdown kitchen sink
date: 2026-07-11
description: Tests headings, lists, code blocks, links, bold/italic, and images in body markdown.
image: graybox.svg
gif: graybox-anim.svg
---

Test post that throw many markdown thing at renderer, see what break.

## Heading two

### Heading three

Some **bold** word, some *italic* word, some `inline code`.

- List item one
- List item two
  - Nested item

1. First
2. Second
3. Third

> A blockquote, for good measure.

```gdscript
func _process(delta: float) -> void:
    position += Vector2.RIGHT * delta
```

A [link back home](https://hanyangliu.dev) to test link styling.

![graybox image in body](graybox.svg)

Delete later.
