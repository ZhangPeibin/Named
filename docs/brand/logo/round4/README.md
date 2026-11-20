# Named — identity 04

**See it. Name it. Talk about it.** The mark is a photo inside a speech bubble:
a real-life moment (sun over a hill) kept in a frame that speaks.

## Files

| File | Use |
| --- | --- |
| `named-symbol.svg` | Full-colour mark: cobalt frame, paper photo, terracotta sun, sage hill. |
| `named-symbol-ink.svg` | One-colour master. The photo window is a true hole; sun/hill are ink. |
| `named-wordmark.svg` | `Named`, Lora 500, outlined. |
| `named-lockup-horizontal.svg` / `-stacked.svg` | Full-colour lockups. |
| `named-lockup-horizontal-ink.svg` / `-stacked-ink.svg` | One-colour lockups for print/reverse. |
| `named-app-icon.svg` | Primary app icon: cobalt tile, paper frame. |
| `named-app-icon-square.svg` | Full-bleed cobalt master for iOS / App Store. |
| `named-app-icon-cream.svg` | Alternate app icon: paper tile, cobalt frame. |
| `named-app-icon-small.svg` | 16px cut: paper frame + sun, hill removed. |
| `exports/` | Black/white/mono SVGs, wordmark/lockup PNGs, favicon + PWA icons, webmanifest, head snippet. |
| `board.png` / `board.html` | Presentation board. |

## Colour

- Cobalt `#2F4A6B`
- Terracotta `#B05230`
- Sage `#6F8A62`
- Paper `#FBF8F2`
- Ink `#232A31`

## Type

- Wordmark: Lora 500, tracking `-0.02em`, outlined. Lora is SIL OFL.
- Do not retype the wordmark; use the SVG.
- The mark is constructed (rounded frame, tail, sun, hill), not a font glyph.

## Usage

- Clear space: one tail width around the mark.
- Minimum sizes: symbol `16px` (use `named-app-icon-small.svg`), wordmark `160px` wide, horizontal lockup `200px` wide.
- App icon: cobalt tile + paper frame is primary; paper tile + cobalt frame is the quiet alternate. iOS uses the full-bleed square master.
- One-colour: use the `-ink` masters. The photo window is a hole, so it takes the paper/background colour.
- Don't flatten the full-colour mark to one colour, add shadows/gradients, rotate the wordmark, or place the cobalt frame on a cobalt background.

## In the app

The app icon and splash are wired:

- `app/assets/branding/app_icon.png` — square cobalt icon
- `app/assets/branding/splash_mark.png` — light splash
- `app/assets/branding/splash_mark_dark.png` — dark splash
- Run `make icons` / `make splash` after changes.
