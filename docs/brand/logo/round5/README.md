# Named — identity 04

**Every name starts a conversation.** A speech bubble and a wordmark. Nothing else.

## Files

| File | Use |
| --- | --- |
| `named-symbol.svg` | Terracotta speech bubble. |
| `named-symbol-ink.svg` | One-colour bubble. |
| `named-wordmark.svg` | `Named` in Manrope 800, outlined. |
| `named-lockup-horizontal.svg` / `-stacked.svg` | Bubble + wordmark. |
| `named-app-icon.svg` | Primary app icon: terracotta tile, paper bubble. |
| `named-app-icon-paper.svg` | Alternate: paper tile, terracotta bubble. |
| `named-app-icon-square.svg` | Full-bleed terracotta master for iOS / App Store. |
| `exports/` | Black/white/mono SVGs, 1200px PNGs, favicon + PWA icons, webmanifest, head snippet. |
| `board.png` / `board.html` | Presentation board. |

## Colour

- Terracotta `#B05230`
- Ink `#232A31`
- Paper `#FBF8F2`
- Cobalt `#2F4A6B` (UI only; not in the logo)

## Type

- Wordmark: Manrope 800, tracking `-0.03em`, outlined. Manrope is SIL OFL.
- UI type stays Lora.
- One bubble, one wordmark; no other detail.

## Usage

- Clear space: one bubble-tail width around the mark.
- Minimum: symbol `16px`; wordmark `160px` wide; horizontal lockup `200px` wide.
- App icon: terracotta tile + paper bubble is primary; paper tile + terracotta bubble is the quiet alternate. iOS uses the full-bleed square master.
- One-colour: use `named-symbol-ink.svg` or the black/white/mono files in `exports/`.
- Do not add shadows, gradients, or extra detail; do not rotate the wordmark.

## In the app

The app icon and splash are wired:

- `app/assets/branding/app_icon.png` — terracotta square icon
- `app/assets/branding/splash_mark.png` — light splash (terracotta bubble on paper)
- `app/assets/branding/splash_mark_dark.png` — dark splash (paper bubble on ink)
- Run `make icons` / `make splash` after changes.
