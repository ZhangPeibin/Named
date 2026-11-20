# Named — identity 05

**Every word becomes a star in your world.** A personal constellation: the words you name,
connected to the moments, conversations and memories around them.

## Files

| File | Use |
| --- | --- |
| `named-symbol.svg` | Constellation: ink nodes/lines, one terracotta node. |
| `named-symbol-white.svg` | Paper/terracotta version for dark backgrounds. |
| `named-symbol-ink.svg` | One-colour source. |
| `named-wordmark.svg` | `Named` in Manrope 800, outlined. |
| `named-lockup-horizontal.svg` / `-stacked.svg` | Constellation + wordmark. |
| `named-app-icon.svg` | Primary app icon: cobalt sky, paper constellation, terracotta node. |
| `named-app-icon-paper.svg` | Alternate: paper sky, ink constellation, terracotta node. |
| `named-app-icon-square.svg` | Full-bleed cobalt master for iOS / App Store. |
| `exports/` | Black/white/mono SVGs, 1200px PNGs, favicon + PWA icons, webmanifest, head snippet. |
| `board.png` / `board.html` | Presentation board. |

## Colour

- Cobalt `#2F4A6B` (sky / UI)
- Terracotta `#B05230` (the word you are naming now)
- Ink `#232A31` (connections, wordmark)
- Paper `#FBF8F2`

## Type

- Wordmark: Manrope 800, tracking `-0.03em`, outlined. Manrope is SIL OFL.
- UI type stays Lora.
- The constellation is constructed from filled line segments and circles; no strokes in the masters.

## Usage

- Clear space: one node diameter around the mark.
- Minimum: symbol `16px`; wordmark `160px` wide; horizontal lockup `200px` wide.
- App icon: cobalt sky is primary; paper sky is the quiet alternate. iOS uses the full-bleed square master.
- One-colour: use `named-symbol-ink.svg` or the black/white/mono files in `exports/`.
- Do not add shadows, gradients, or extra stars; do not rotate the wordmark.

## In the app

The app icon and splash are wired:

- `app/assets/branding/app_icon.png` — cobalt square icon
- `app/assets/branding/splash_mark.png` — light splash (ink constellation on paper)
- `app/assets/branding/splash_mark_dark.png` — dark splash (paper constellation on ink)
- Run `make icons` / `make splash` after changes.
