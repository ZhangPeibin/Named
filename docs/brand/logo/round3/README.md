# Named — identity 01

**Every word has a story.** The asterisk is the footnote mark: a word with more behind it.
In the app, it quietly marks words that have an experience attached.

## Files

| File | Use |
| --- | --- |
| `named-wordmark.svg` | Primary wordmark: lowercase `named` in Lora 450 + terracotta asterisk. |
| `named-symbol.svg` | Asterisk symbol, terracotta. |
| `named-symbol-small.svg` | Thicker 16px cut for favicon/app icon. |
| `named-symbol-ink.svg` | One-colour source for exports. |
| `named-lockup-horizontal.svg` | Symbol + `named` (no superscript star). |
| `named-lockup-stacked.svg` | Symbol above `named`. |
| `named-app-icon.svg` | Rounded preview, paper tile (primary app icon). |
| `named-app-icon-square.svg` | Full-bleed paper master for iOS / App Store. |
| `named-app-icon-terracotta.svg` | Alternate app icon: paper asterisk on terracotta. |
| `named-app-icon-cobalt.svg` | Alternate app icon on cobalt. |
| `exports/` | Black/white/mono SVGs, 1200px PNGs, favicon + PWA icon set, manifest, head snippet. |

## Colour

- Ink `#232A31`
- Terracotta `#B05230`
- Paper `#FBF8F2`
- Cobalt `#2F4A6B` (UI primary; optional in the logo)

## Type & construction

- Wordmark: Lora 450, tracking `-0.01em`, outlined. Lora is SIL OFL.
- Asterisk: custom six-arm mark, flat ends; not a font glyph.
- Do not retype the wordmark; use the SVG.
- The colour logo keeps the asterisk terracotta. For one-colour, use the black/white/mono files.

## Usage

- Clear space: one asterisk arm length around the mark.
- Minimum sizes: symbol **16px**; wordmark **160px** wide; horizontal lockup **180px** wide.
- App icon: 1024px master; iOS uses the full-bleed square, other platforms use the rounded tile.
- Dark backgrounds: use the white or mono files. Print: black or one brand colour.
- Do not add shadows, gradients, outlines, or rotate the wordmark. Do not use the asterisk as a bullet at very small sizes without the 16px cut.

## Next step

Wire the icon into the Flutter app: replace `app/assets/branding/app_icon.png` with
`exports/app-icon-square-1024.png`, then run `make icons` and `make splash` from `app/`.
