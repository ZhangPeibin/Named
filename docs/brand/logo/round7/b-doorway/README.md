# Named — The Doorway

**Every name opens a world; the dot is the word waiting inside.**

A doorway made of an arch, a terracotta threshold and a single terracotta dot.
The mark connects the product name to the idea of a Personal English World:
you step through a word into the experiences around it.

## Files

| File | Use |
| --- | --- |
| `b-symbol.svg` | Primary symbol: ink arch, terracotta dot and threshold. |
| `b-symbol-on-dark.svg` | Paper arch + terracotta dot/threshold for dark grounds. |
| `b-symbol-small.svg` | 16 px cut: arch + dot, threshold removed and mark enlarged. |
| `b-symbol-small-on-dark.svg` | Reversed 16 px cut for favicons and PWA icons. |
| `b-wordmark.svg` / `b-wordmark-on-dark.svg` | `Named` in Manrope 800, outlined. |
| `b-lockup-horizontal.svg` / `-on-dark.svg` | Symbol + wordmark. |
| `b-lockup-stacked.svg` / `-on-dark.svg` | Stacked lockup. |
| `b-app-icon.svg` | Rounded cobalt tile, paper doorway + terracotta accents. |
| `b-app-icon-square.svg` | Full-bleed cobalt master for iOS / App Store. |
| `b-app-icon-paper.svg` | Quiet alternate: paper tile, ink doorway. |
| `exports/` | One-colour and reversed SVGs, PNGs, favicon/PWA icons, webmanifest, head snippet. |
| `exports/b-app-icon-1024.png` | 1024 px app-icon master from the full-bleed square. |
| `board.html` / `board.png` / `slides/` | Presentation board. |
| `spec.json` | Board specification. |

## Colour

| Name | HEX | Use |
| --- | --- | --- |
| Cobalt | `#2F4A6B` | App-icon tile, UI primary |
| Terracotta | `#B05230` | Threshold and the word waiting inside |
| Ink | `#232A31` | Arch, wordmark |
| Paper | `#FBF8F2` | Reversed arch, light grounds |

Paper on cobalt is the primary app-icon pair. The dot is an accent; the arch
carries the silhouette.

## Type

- Wordmark: **Manrope 800**, tracking `-0.03em`, outlined. Manrope is SIL OFL.
- UI type stays **Lora**; do not retype the wordmark.
- The arch, dot and threshold are constructed geometry, not a font glyph.

## Usage

- **Clear space:** one dot diameter around the logo.
- **Minimum sizes:** symbol `24 px` (use `b-symbol-small.svg` below that; `16 px`
  for favicon); wordmark `160 px` wide; horizontal lockup `200 px` wide.
- **Primary app icon:** paper doorway + terracotta dot/threshold on cobalt. Use
  `b-app-icon-square.svg` for iOS / App Store; the platform applies the mask.
- **Favicon / PWA:** use `exports/favicon-16/32/48.png`, `favicon.ico`,
  `icon-192.png`, `icon-512.png`, `maskable-512.png` and
  `apple-touch-icon.png`. They are generated from the simplified small cut.
- **One-colour / reversed:** use `exports/named-b-symbol-black.svg`,
  `-white.svg`, `-mono-2f4a6b.svg`, and the matching lockup/stacked files.
  For dark grounds, `b-symbol-on-dark.svg` keeps the terracotta accents.
- **Do not** replace the threshold with a plain bar, remove the dot, add
  gradients/shadows, rotate the arch, or retype the wordmark.

The generated `exports/named-b-symbol-app-icon.svg` is the simplified PWA tile
(no threshold). It is not the primary iOS master; use `b-app-icon-square.svg`
there.

## Notes

- A doorway is a common metaphor. The threshold and the single dot make this one
  specific: a way in, with a word already waiting. At very small sizes it can
  read as a keyhole; the full mark keeps the threshold. Use the small cut only
  for favicon/PWA.
- Audit: 99/100. 16 / 32 / 64 px, one-colour, reversed and dark-ground versions
  were checked.
- No trademark clearance has been performed. Commission a professional search
  before launch.
