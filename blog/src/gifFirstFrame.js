const stillCache = new Map();

function skipSubBlocks(bytes, i) {
  while (i < bytes.length) {
    const size = bytes[i];
    i += 1;
    if (size === 0) return i;
    i += size;
  }
  return -1;
}

// Slice the first frame out of a GIF so we can show a still without animation.
export function gifFirstFrameBytes(buffer) {
  const bytes = new Uint8Array(buffer);
  if (bytes.length < 13) return null;

  const sig = String.fromCharCode(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5]);
  if (sig !== 'GIF87a' && sig !== 'GIF89a') return null;

  const packed = bytes[10];
  let i = 13;
  if (packed & 0x80) i += 3 * (1 << ((packed & 0x07) + 1));
  if (i > bytes.length) return null;

  const header = bytes.subarray(0, i);
  let gce = null;
  let image = null;

  while (i < bytes.length) {
    const marker = bytes[i];
    if (marker === 0x3B) break;

    if (marker === 0x21) {
      if (i + 2 >= bytes.length) return null;
      const label = bytes[i + 1];
      const start = i;
      i = skipSubBlocks(bytes, i + 2);
      if (i < 0) return null;
      if (label === 0xF9) gce = bytes.subarray(start, i);
      continue;
    }

    if (marker === 0x2C) {
      const start = i;
      if (i + 10 > bytes.length) return null;
      const imgPacked = bytes[i + 9];
      i += 10;
      if (imgPacked & 0x80) i += 3 * (1 << ((imgPacked & 0x07) + 1));
      if (i >= bytes.length) return null;
      i += 1;
      i = skipSubBlocks(bytes, i);
      if (i < 0) return null;
      image = bytes.subarray(start, i);
      break;
    }

    return null;
  }

  if (!image) return null;

  const out = new Uint8Array(header.length + (gce ? gce.length : 0) + image.length + 1);
  let o = 0;
  out.set(header, o);
  o += header.length;
  if (gce) {
    out.set(gce, o);
    o += gce.length;
  }
  out.set(image, o);
  o += image.length;
  out[o] = 0x3B;
  return out;
}

export function stillFromGif(url) {
  if (!stillCache.has(url)) {
    stillCache.set(
      url,
      fetch(url)
        .then((res) => (res.ok ? res.arrayBuffer() : null))
        .then((buffer) => {
          if (!buffer) return null;
          const bytes = gifFirstFrameBytes(buffer);
          if (!bytes) return null;
          return URL.createObjectURL(new Blob([bytes], { type: 'image/gif' }));
        })
        .catch(() => null)
    );
  }
  return stillCache.get(url);
}
