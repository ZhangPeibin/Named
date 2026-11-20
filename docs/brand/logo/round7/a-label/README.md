# Named — The Label

**Every thing you name gets a label: a found moment becomes yours.**

A name label with a terracotta grommet and a 60° point. The mark is the act of
naming made physical: something found in the world gets a tag, and from then on
it belongs to your English world.

## Files

| File | Use |
| --- | --- |
| `a-symbol.svg` | Primary symbol: ink label + terracotta grommet. |
| `a-symbol-on-dark.svg` | Paper label + terracotta grommet for cobalt or ink grounds. |
| `a-symbol-small.svg` | 16 px cut: the grommet simplifies to a solid terracotta dot. |
| `a-symbol-small-on-dark.svg` | Reversed 16 px cut for favicons and PWA icons. |
| `a-wordmark.svg` / `a-wordmark-on-dark.svg` | `Named` in Manrope 800, outlined. |
| `a-lockup-horizontal.svg` / `-on-dark.svg` | Symbol + wordmark. |
| `a-lockup-stacked.svg` / `-on-dark.svg` | Stacked lockup. |
| `a-app-icon.svg` | Rounded cobalt tile, paper label + terracotta grommet. |
| `a-app-icon-square.svg` | Full-bleed cobalt master for iOS / App Store (no rounded corners). |
| `a-app-icon-paper.svg` | Quiet alternate: paper tile, ink label. |
| `exports/` | One-colour and reversed SVGs, PNGs, favicon/PWA icons, webmanifest, head snippet. |
| `exports/a-app-icon-1024.png` | 1024 px app-icon master from the full-bleed square. |
| `board.html` / `board.png` / `slides/` | Presentation board. |
| `spec.json` | Board specification. |

## Colour

| Name | HEX | Use |
| --- | --- | --- |
| Cobalt | `#2F4A6B` | App-icon tile, UI primary |
| Terracotta | `#B05230` | Grommet, the named moment |
| Ink | `#232A31` | Label, wordmark, connections |
| Paper | `#FBF8F2` | Reversed label, light grounds |

Paper on cobalt is the primary app-icon pair. Terracotta is an accent and is
never the only carrier of meaning.

## Type

- Wordmark: **Manrope 800**, tracking `-0.03em`, outlined. Manrope is SIL OFL.
- UI type stays **Lora**; the wordmark is an asset, not a type style to recreate.
- The label is constructed geometry, not a font glyph.

## Usage

- **Clear space:** one grommet diameter around the logo.
- **Minimum sizes:** symbol `24 px` (use `a-symbol-small.svg` below that; `16 px`
  for favicon); wordmark `160 px` wide; horizontal lockup `200 px` wide.
- **Primary app icon:** paper label + terracotta grommet on cobalt. Use
  `a-app-icon-square.svg` for iOS / App Store; the platform applies the mask.
- **Favicon / PWA:** use `exports/favicon-16/32/48.png`, `favicon.ico`,
  `icon-192.png`, `icon-512.png`, `maskable-512.png` and
  `apple-touch-icon.png`. They are generated from the simplified small cut.
- **One-colour / reversed:** use `exports/named-a-symbol-black.svg`,
  `-white.svg`, `-mono-2f4a6b.svg`, and the matching lockup/stacked files.
  For dark grounds, `a-symbol-on-dark.svg` keeps the terracotta accent.
- **Do not** add shadows, gradients, rotation, strings, extra labels or a second
  hole; do not recolour outside the palette; do not retype the wordmark.

The generated `exports/named-a-symbol-app-icon.svg` is the simplified PWA tile
(dot cut). It is not the primary iOS master; use `a-app-icon-square.svg` there.

## Notes

- A label can read as a price tag. The 60° point, grommet and paper tone make it
  a name label; keep it in app, editorial and personal contexts rather than
  retail promotions.
- Audit: 99/100. 16 / 32 / 64 px, one-colour, reversed and dark-ground versions
  were checked.
- No trademark clearance has been performed. Commission a professional search
  before launch.
