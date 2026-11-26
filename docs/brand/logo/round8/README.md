# Named — identity 08

**One line, one point.** A continuous brand-red line curls into an open loop with
a single dot held inside it. The mark is abstract: it reads as a kept moment or a
word returned to, not as a letter. It replaces the woven N from round 7.

Source artwork: `docs/brand/logo/纯图标.svg`.

## Files

| File | Use |
| --- | --- |
| `named-symbol.svg` | Primary symbol: brand red on transparent, 256 canvas. |
| `named-symbol-on-dark.svg` | Paper reverse for dark grounds. |
| `named-wordmark.svg` / `named-wordmark-on-dark.svg` | `Named` in Manrope 800, outlined. |
| `named-lockup-horizontal.svg` | **Primary lockup**: red symbol + ink wordmark. |
| `named-lockup-horizontal-on-dark.svg` | Paper symbol + paper wordmark for dark grounds. |
| `named-lockup-stacked.svg` / `-on-dark.svg` | Square-canvas lockup. |
| `named-app-icon.svg` | Rounded preview tile: paper ground, red symbol. |
| `named-app-icon-square.svg` | Full-bleed master for iOS / stores. |
| `named-splash-mark.svg` / `named-splash-mark-dark.svg` | 1024 transparent splash marks. |
| `exports/` | PNG, favicon and PWA exports listed below. |
| `generate.py` | Rebuilds every SVG and PNG in this folder. |

## Exports

- `app-icon-1024.png`, `app-icon-512.png`
- `splash-mark.png`, `splash-mark-dark.png`
- `splash-symbol.png`, `splash-symbol-dark.png`
- `symbol-1024.png`
- `lockup-horizontal.png`, `lockup-horizontal-on-dark.png` (1400 × 512)
- `favicon.svg`, `favicon-16.png`, `favicon-32.png`, `favicon-48.png`, `favicon.ico`
- `icon-192.png`, `icon-512.png`, `maskable-512.png`, `apple-touch-icon.png`

## Colour

| Name | HEX | Use |
| --- | --- | --- |
| Brand Red | `#D94F58` | The mark on light grounds. |
| Ink | `#232A31` | Wordmark on light grounds. |
| Paper | `#FBF8F2` | App-icon ground, wordmark and mark on dark grounds. |

Cobalt `#2F4A6B` and terracotta `#B05230` remain UI palette colors. They are not
part of the logo.

## Type

Wordmark: **Manrope 800**, tracking `-0.03em`, outlined. Do not retype it. UI type
stays **Lora**.

## Usage

- Clear space: at least one dot diameter on every side.
- Minimums: symbol `16 px`; wordmark `160 px` wide; horizontal lockup `200 px`
  wide; stacked lockup `80 px` high.
- Light grounds use `named-symbol.svg` (red). Dark grounds use
  `named-symbol-on-dark.svg` (paper).
- App icon: paper tile + red mark. Use `named-app-icon-square.svg` for iOS and
  store masters; the platform applies the mask.
- Favicons and PWA: use `exports/favicon.*`, `icon-192.png`, `icon-512.png`,
  `maskable-512.png` and `apple-touch-icon.png`.
- Do not rotate, stretch, outline, gradient-fill, or recolour the mark; do not
  detach the dot or use it as a standalone bullet.

## In the app

- `app/assets/branding/app_icon.png` ← `exports/app-icon-1024.png`
- `app/assets/branding/splash_mark.png` ← `exports/splash-mark.png`
- `app/assets/branding/splash_mark_dark.png` ← `exports/splash-mark-dark.png`
- `app/assets/branding/marks/symbol_light.png` ← `exports/splash-symbol.png`
- `app/assets/branding/marks/symbol_dark.png` ← `exports/splash-symbol-dark.png`
- `app/assets/branding/marks/lockup_light.png` ← `exports/lockup-horizontal.png`
- `app/assets/branding/marks/lockup_dark.png` ← `exports/lockup-horizontal-on-dark.png`

Run `make icons` and `make splash` in `app/` after replacing the source PNGs.

## Regenerate

```bash
python3 docs/brand/logo/round8/generate.py
```

The script uses headless Google Chrome to rasterise PNGs. Set `CHROME` to a
different browser path if needed.
