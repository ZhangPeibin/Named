# Named — identity round 7

Three candidate identities, each built as a complete, comparable kit. All three
keep the existing Named palette, the Manrope 800 wordmark and the warm editorial
tone, so the choice is about the idea rather than the styling.

**Selected: C · The Weave.** A and B remain complete alternates.

## Start here

| View | File |
| --- | --- |
| Greyscale concept sheet | `concepts.png` |
| Colour comparison | `comparison/concepts-color.png` |
| App-icon comparison | `comparison/app-icons.png` |
| N refinement record | `c-weave/refinements/refinements.png` |
| Full boards | `a-label/board.png` · `b-doorway/board.png` · `c-weave/board.png` |

## The three kits

| Kit | Idea | Mark type | Primary lockup | App icon |
| --- | --- | --- | --- | --- |
| **A · The Label** | Every thing you name gets a label. | Pictorial label | Symbol + wordmark | Paper label on cobalt |
| **B · The Doorway** | Every name opens a world; the dot is the word waiting inside. | Architectural arch | Symbol + wordmark | Paper doorway on cobalt |
| **C · The Weave** | One thread over and under: the word tied to what you already know. | Woven letterform | N symbol + wordmark | Paper N on cobalt |

Each folder contains the primary symbol, on-dark and small-size cuts, wordmark,
horizontal and stacked lockups, app icons, exports (black / white / mono, PNG,
favicon / PWA), board, slides and a compact usage README.

## Selected: C · The Weave

**C · The Weave** is the chosen identity. It is the only mark that states the
product's differentiator — a relationship between words, experiences and memory.
The selected **Thread** refinement thins the strokes, curves the stems and tapers
the terracotta thread from a thin start to a soft finish; the N now feels drawn
rather than constructed. The primary lockup is the separate N symbol plus the
standard wordmark, because the Thread N is deliberately lighter than Manrope 800.

- **A · The Label** is the warmest and most direct. It makes the act of naming
  visible immediately; the risk is a price-tag read, so keep it in personal,
  editorial and app contexts.
- **B · The Doorway** is the quietest and most editorial. It maps directly to
  Personal English World; the risk is the common doorway/portal metaphor, which
  the threshold and dot help own.

## Status

- **C · The Weave** is selected, with the **Thread** N refinement. Its app icon
  and splash are wired into the Flutter app from `c-weave/exports/`:
  - `app/assets/branding/app_icon.png` ← `c-app-icon-1024.png`
  - `app/assets/branding/splash_mark.png` ← `c-splash-mark.png`
  - `app/assets/branding/splash_mark_dark.png` ← `c-splash-mark-dark.png`
- `make icons` and `make splash` have been run in `app/`.
- The primary C lockup is the N symbol + standard wordmark; the woven wordmark
  remains an alternate because the lighter N does not match Manrope 800.
- A · The Label and B · The Doorway remain complete alternates.
- The generated `exports/named-*-app-icon.svg` files are simplified PWA tiles
  from the small cuts, not the primary iOS masters.
- No trademark clearance has been performed. Manrope is SIL OFL; the wordmark is
  outlined in every file.

## Concept record

The concept-stage sources are in `concepts/`; the greyscale `concepts.png` and
`color-hint.svg` are the round-7 concept record. The three kits are the next
stage, built from the approved directions.
