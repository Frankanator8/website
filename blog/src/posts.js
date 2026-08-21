const modules = import.meta.glob('../posts/*.html', {
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

const postAssets = import.meta.glob('../posts/**/*.{png,jpg,jpeg,gif,svg,webp,avif}', {
  eager: true,
  query: '?url',
  import: 'default',
});

const mediaByName = Object.fromEntries(
  Object.entries(mediaFiles).map(([path, url]) => [path.split('/').pop(), url])
);

const postAssetByPath = Object.fromEntries(
  Object.entries(postAssets).map(([path, url]) => {
    const key = path.replace(/^\.\.\/posts\//, '');
    return [key, url];
  })
);

function parseCommentFrontmatter(raw) {
  const match = /^<!--\s*\n---\n([\s\S]*?)\n---\n\s*-->\s*\n?/.exec(raw);
  if (!match) return { meta: {}, content: raw };
  const meta = {};
  for (const line of match[1].split('\n')) {
    const idx = line.indexOf(':');
    if (idx === -1) continue;
    meta[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
  }
  return { meta, content: raw.slice(match[0].length) };
}

function unwrapGoogleRedirect(href) {
  try {
    const url = new URL(href);
    if (url.hostname.includes('google.com') && url.pathname === '/url') {
      const target = url.searchParams.get('q');
      if (target) return target;
    }
  } catch {
    // leave href unchanged
  }
  return href;
}

function resolvePostAsset(relativePath) {
  const normalized = relativePath.replace(/^\.\//, '');
  if (postAssetByPath[normalized]) return postAssetByPath[normalized];
  const filename = normalized.split('/').pop();
  const match = Object.entries(postAssetByPath).find(([path]) => path.endsWith(`/${filename}`));
  return match ? match[1] : null;
}

function parseHtmlPost(raw, slug) {
  const doc = new DOMParser().parseFromString(raw, 'text/html');

  const titleEl = doc.querySelector('.title');
  const title = titleEl?.textContent.trim() || slug;
  titleEl?.remove();

  doc.querySelectorAll('h1').forEach((el) => {
    const h2 = doc.createElement('h2');
    h2.innerHTML = el.innerHTML;
    for (const attr of el.attributes) {
      h2.setAttribute(attr.name, attr.value);
    }
    el.replaceWith(h2);
  });

  doc.querySelectorAll('[style]').forEach((el) => el.removeAttribute('style'));

  doc.querySelectorAll('img').forEach((img) => {
    const src = img.getAttribute('src');
    if (!src || /^(https?:)?\/\//.test(src)) return;
    const resolved = resolvePostAsset(src);
    if (resolved) img.setAttribute('src', resolved);
  });

  doc.querySelectorAll('a[href]').forEach((a) => {
    a.setAttribute('href', unwrapGoogleRedirect(a.getAttribute('href')));
  });

  return {
    title,
    content: doc.body?.innerHTML || '',
  };
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
    const slug = path.split('/').pop().replace(/\.html$/, '');
    const { meta, content: htmlRaw } = parseCommentFrontmatter(raw);
    const { title, content } = parseHtmlPost(htmlRaw, slug);
    const image = resolveMedia(meta.image);
    const gif = resolveMedia(meta.gif);
    return {
      slug,
      title,
      date: meta.date || '',
      description: meta.description || '',
      // Still frame at rest; gif plays on hover. Gif-only posts freeze frame 0.
      image,
      gif,
      content,
    };
  })
  .sort((a, b) => b.date.localeCompare(a.date));

export function getPost(slug) {
  return posts.find((p) => p.slug === slug);
}
