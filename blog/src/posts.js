const modules = import.meta.glob('../posts/*.md', {
  eager: true,
  query: '?raw',
  import: 'default',
});

// Card artwork lives in blog/media/. Vite hashes these and rewrites the URLs.
const mediaFiles = import.meta.glob('../media/*.{png,jpg,jpeg,gif,svg,webp,avif}', {
  eager: true,
  query: '?url',
  import: 'default',
});

const mediaByName = Object.fromEntries(
  Object.entries(mediaFiles).map(([path, url]) => [path.split('/').pop(), url])
);

function parseFrontmatter(raw) {
  const match = /^---\n([\s\S]*?)\n---\n?/.exec(raw);
  if (!match) return { meta: {}, content: raw };
  const meta = {};
  for (const line of match[1].split('\n')) {
    const idx = line.indexOf(':');
    if (idx === -1) continue;
    meta[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
  }
  return { meta, content: raw.slice(match[0].length) };
}

// Accepts a filename from blog/media/, or any absolute/relative URL as-is.
function resolveMedia(value) {
  if (!value) return null;
  if (mediaByName[value]) return mediaByName[value];
  if (/^(https?:)?\/\/|^\.{0,2}\//.test(value)) return value;
  return null;
}

export const posts = Object.entries(modules)
  .map(([path, raw]) => {
    const slug = path.split('/').pop().replace(/\.md$/, '');
    const { meta, content } = parseFrontmatter(raw);
    const image = resolveMedia(meta.image);
    const gif = resolveMedia(meta.gif);
    return {
      slug,
      title: meta.title || slug,
      date: meta.date || '',
      description: meta.description || '',
      // Still frame shown at rest; gif takes over on hover. Either may be absent.
      image: image || gif,
      gif,
      content,
    };
  })
  .sort((a, b) => b.date.localeCompare(a.date));

export function getPost(slug) {
  return posts.find((p) => p.slug === slug);
}
