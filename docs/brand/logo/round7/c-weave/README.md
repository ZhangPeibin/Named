# Named — The Weave

**One thread over and under: the new word tied to what you already know.**

The N is the brand initial and a woven thread. The terracotta thread passes over
the left stem and under the right stem, so the mark reads as a relationship, not
just a letter. The selected **Thread** refinement keeps the idea but thins the
strokes, curves the stems and tapers the thread from a thin start to a soft
finish, so the N feels drawn rather than constructed. It is the clearest
expression of the product's core idea: words are connected to experiences,
conversations and memories.

## Files

| File | Use |
| --- | --- |
| `c-symbol.svg` | Primary symbol: ink stems + terracotta thread. |
| `c-symbol-on-dark.svg` | Paper stems + terracotta thread for cobalt or ink grounds. |
| `c-symbol-small.svg` | 16 px cut. |
| `c-symbol-small-on-dark.svg` | Reversed 16 px cut for favicons and PWA icons. |
| `c-wordmark.svg` / `c-wordmark-on-dark.svg` | `Named` in Manrope 800, outlined. |
| `c-wordmark-woven.svg` / `-on-dark.svg` | Alternate woven wordmark: the first N is the mark. |
| `c-lockup-horizontal.svg` / `-on-dark.svg` | **Primary horizontal lockup**: N symbol + standard wordmark. |
| `c-lockup-horizontal-symbol.svg` / `-on-dark.svg` | Legacy alias of the primary horizontal lockup. |
| `c-lockup-stacked.svg` / `-on-dark.svg` | **Primary stacked lockup**: N symbol above the standard wordmark. |
| `c-lockup-horizontal-woven.svg` / `-on-dark.svg` | Alternate horizontal lockup using the woven wordmark. |
| `c-lockup-stacked-woven.svg` / `-on-dark.svg` | Alternate stacked lockup using the woven wordmark. |
| `c-app-icon.svg` | Rounded cobalt tile, paper N + terracotta thread. |
| `c-app-icon-square.svg` | Full-bleed cobalt master for iOS / App Store. |
| `c-app-icon-paper.svg` | Quiet alternate: paper tile, ink N. |
| `c-splash-mark.svg` / `c-splash-mark-dark.svg` | Transparent splash marks for light / dark backgrounds. |
| `exports/` | One-colour and reversed SVGs, PNGs, favicon/PWA icons, webmanifest, head snippet. |
| `exports/c-app-icon-1024.png` | 1024 px app-icon master from the full-bleed square. |
| `exports/c-splash-mark.png` / `-dark.png` | 1024 px transparent splash marks. |
| `board.html` / `board.png` / `slides/` | Presentation board. |
| `spec.json` | Board specification. |

## Status

Selected as the Named identity. The Flutter app icon and splash are wired from
this kit:

- `app/assets/branding/app_icon.png` ← `exports/c-app-icon-1024.png`
- `app/assets/branding/splash_mark.png` ← `exports/c-splash-mark.png`
- `app/assets/branding/splash_mark_dark.png` ← `exports/c-splash-mark-dark.png`

After changing any source, regenerate the PNGs and run `make icons` and
`make splash` in `app/`.

## Colour

| Name | HEX | Use |
| --- | --- | --- |
| Cobalt | `#2F4A6B` | App-icon tile, UI primary |
| Terracotta | `#B05230` | The thread that ties the word in |
| Ink | `#232A31` | N stems, wordmark |
| Paper | `#FBF8F2` | Reversed stems, light grounds |

Paper stems on cobalt are the primary app-icon pair. Terracotta is an accent and
is never the only carrier of meaning.

## Type

- Wordmark: **Manrope 800**, tracking `-0.03em`, outlined. Manrope is SIL OFL.
- The woven N is a custom symbol, not a font glyph. Do not retype it.
- UI type stays **Lora**.
- The primary horizontal lockup is **N symbol + standard wordmark**. The Thread
  N is deliberately lighter than Manrope 800; keeping the wordmark as type lets
  the symbol carry the thread character. The woven wordmark is an alternate for
  cases where the lighter N can be the wordmark's first letter.

## Usage

- **Clear space:** one stem width around the logo.
- **Minimum sizes:** symbol `16 px`; wordmark `160 px` wide; horizontal lockup
  `200 px` wide.
- **Primary app icon:** paper N + terracotta thread on cobalt. Use
  `c-app-icon-square.svg` for iOS / App Store; the platform applies the mask.
- **Favicon / PWA:** use `exports/favicon-16/32/48.png`, `favicon.ico`,
  `icon-192.png`, `icon-512.png`, `maskable-512.png` and
  `apple-touch-icon.png`.
- **One-colour / reversed:** use `exports/named-c-symbol-black.svg`,
  `-white.svg`, `-mono-2f4a6b.svg`, and the matching `named-c-lockup-*` /
  `named-c-stacked-*` files. For dark grounds, `c-symbol-on-dark.svg` keeps the
  terracotta thread.
- **Do not** add a second thread, change the over/under order, rotate the N,
  separate the terracotta thread from the N, or retype the wordmark.

The generated `exports/named-c-symbol-app-icon.svg` is the PWA tile. It is not
the primary iOS master; use `c-app-icon-square.svg` there.

## Notes

- The selected form is the **Thread** refinement: stems `23–27`, a tapered thread
  `8 → 26 → 16`, and gently curved stems. The comparison is in
  `refinements/refinements.png`.
- The Thread N is lighter than Manrope 800, so the primary lockup keeps the N as
  a separate symbol and uses the standard wordmark. The woven wordmark is an
  alternate; it reads noticeably lighter than the rest of the letters.
- The thin thread start can weaken at 16 px; the stems and terracotta diagonal
  still carry the N. Use the symbol cut for favicon/PWA.
- The terracotta thread can lose contrast on cobalt at very small sizes; the
  paper stems carry the silhouette, so the N remains legible.
- Audit: symbol and app icons `100/100`; lockups `98–99/100` (the shared Manrope
  wordmark carries most of the complexity). 16 / 32 / 64 px, one-colour,
  reversed, dark-ground and stacked versions were checked.
- No trademark clearance has been performed. Commission a professional search
  before launch.
