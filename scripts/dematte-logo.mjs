// One-off: these logo files were exported flattened onto a black matte
// (JPEG, no alpha) instead of true transparent PNGs. Recover transparency by
// un-premultiplying against black: for a foreground composited on black,
// displayed = color * alpha, so alpha = max(r,g,b) and
// unmultiplied = displayed * 255 / alpha. This correctly restores soft/
// anti-aliased edges (glow, gradients) instead of a hard chroma-key cutoff.
import sharp from "sharp";

// JPEG block noise means "pure black" background pixels aren't exactly
// (0,0,0) — dividing by a near-zero alpha amplifies that noise into wild
// fringe colors. A mild pre-blur smooths the noise, and a noise floor forces
// anything below it fully transparent instead of unmultiplying garbage.
const NOISE_FLOOR = 24;

async function dematte(inputPath, outputPath, matte) {
  const img = sharp(inputPath).blur(0.6).ensureAlpha();
  const { data, info } = await img.raw().toBuffer({ resolveWithObject: true });
  const { width, height, channels } = info;
  const out = Buffer.alloc(width * height * 4);

  for (let i = 0; i < width * height; i++) {
    const r = data[i * channels];
    const g = data[i * channels + 1];
    const b = data[i * channels + 2];
    // Composited-on-black: displayed = fg*alpha, so alpha = max(r,g,b).
    // Composited-on-white: displayed = 255 - (255-fg)*alpha, so
    // alpha = 255 - min(r,g,b) (distance of the darkest channel from white).
    const alpha = matte === "black" ? Math.max(r, g, b) : 255 - Math.min(r, g, b);

    if (alpha <= NOISE_FLOOR) {
      out[i * 4] = 0;
      out[i * 4 + 1] = 0;
      out[i * 4 + 2] = 0;
      out[i * 4 + 3] = 0;
    } else if (matte === "black") {
      out[i * 4] = Math.min(255, Math.round((r * 255) / alpha));
      out[i * 4 + 1] = Math.min(255, Math.round((g * 255) / alpha));
      out[i * 4 + 2] = Math.min(255, Math.round((b * 255) / alpha));
      out[i * 4 + 3] = alpha;
    } else {
      out[i * 4] = Math.max(0, Math.round((r - 255 * (1 - alpha / 255)) / (alpha / 255)));
      out[i * 4 + 1] = Math.max(0, Math.round((g - 255 * (1 - alpha / 255)) / (alpha / 255)));
      out[i * 4 + 2] = Math.max(0, Math.round((b - 255 * (1 - alpha / 255)) / (alpha / 255)));
      out[i * 4 + 3] = alpha;
    }
  }

  await sharp(out, { raw: { width, height, channels: 4 } })
    .png()
    .toFile(outputPath);
}

await dematte("public/Logo_WOWlab.png", "public/logo-wowlab.png", "black");
// NOTE: Logo_WOWlab_NEGATIV.png is a white mark flattened onto a white
// canvas — white foreground and white matte are numerically identical, so
// there is no way to recover transparency for it from this file alone. Not
// attempted here; not needed for the login page (colored mark on a white
// card). Would need a proper transparent export from the source design file.
console.log("done");
