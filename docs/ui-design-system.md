# Named · Mobile UI Design System

**Status:** v1.0 implementation baseline
**Visual direction:** Warm Editorial Minimalism
**Product authority:** [PRD V1.0](prd-v1.0.md)
**Experience direction:** [UI/UX design](ui-ux-design.md)
**Reference build:** [HTML prototype](prototypes/named.html)

This document is the contract for the Flutter app. It defines the visual language, reusable tokens, component behaviour, and screen patterns. New screens must consume these rules instead of inventing local styles.

## 1. Principles

1. **Life first, interface second.** A real photo, a remembered scene, or one honest sentence is the visual focus. Chrome stays quiet.
2. **Warm, not cute.** Ivory paper, forest green, serif headlines, and restrained borders. No gradients, glass, neon, AI glow, or decorative illustration.
3. **Editorial hierarchy.** Large Latin serif headlines create rhythm; Chinese and body copy stay highly legible in the system sans font.
4. **One clear action.** Every screen has one primary action. Secondary actions are outlined or text-only.
5. **Content is personal, never gamified.** No mastery scores, streak pressure, leaderboards, or fake progress.
6. **Calm in every state.** Loading, empty, error, and retry states keep the same composition and never discard user input.
7. **Accessible by default.** AA contrast, 44 px touch targets, dynamic type, screen-reader labels, and reduced-motion support are requirements.

## 2. Color tokens

Use semantic tokens, never raw hex values in feature code. Feature widgets read `Theme.of(context).colorScheme` or the `AppPalette` theme extension.

### Light

| Token | Hex | Use |
| --- | --- | --- |
| `canvas` | `#F5F2E9` | App background, page canvas |
| `surface` | `#FFFFFF` | Cards, fields, sheets |
| `surfaceMuted` | `#E5E9DF` | Chips, selected tiles, quiet blocks |
| `primary` | `#526B4B` | Primary actions, active nav, identity |
| `primaryPressed` | `#43583E` | Pressed / hover primary |
| `onPrimary` | `#FFFFFF` | Text and icons on primary |
| `ink` | `#30372F` | Main text |
| `muted` | `#646A60` | Supporting text, metadata |
| `accent` | `#A7BC96` | Quiet accents, illustration fallback |
| `warm` | `#E8DDCC` | Warm callouts, user-message surface |
| `line` | `#D4D8CD` | Borders and dividers |
| `warningSurface` | `#F1E6D7` | Retry / warning background |
| `warningText` | `#77512D` | Retry / warning text |
| `error` | `#A13D32` | Destructive actions and errors |

### Dark

| Token | Hex | Use |
| --- | --- | --- |
| `canvas` | `#1C211D` | App background, page canvas |
| `surface` | `#252C26` | Cards, fields, sheets |
| `surfaceMuted` | `#303930` | Chips, selected tiles, quiet blocks |
| `primary` | `#A7BC96` | Primary actions, active nav, identity |
| `primaryPressed` | `#8FA57F` | Pressed / hover primary |
| `onPrimary` | `#1C211D` | Text and icons on primary |
| `ink` | `#E9E8DF` | Main text |
| `muted` | `#B8BDB2` | Supporting text, metadata |
| `accent` | `#718568` | Quiet accents, illustration fallback |
| `warm` | `#3A352D` | Warm callouts, user-message surface |
| `line` | `#485246` | Borders and dividers |
| `warningSurface` | `#3C342A` | Retry / warning background |
| `warningText` | `#E8DDCC` | Retry / warning text |
| `error` | `#E6A09A` | Destructive actions and errors |

### Color rules

- Photos keep their real color. Text is never placed directly over a busy photo; use an opaque `surface` or `canvas` block.
- Green is reserved for action, identity, and active state. Do not use it as a decorative background across whole cards.
- Never use color alone to communicate state. Pair it with text, icon, or shape.
- Validate every rendered foreground/background pair at 4.5:1 for normal text and 3:1 for large text in both themes.

## 3. Typography

### Families

- **Editorial / display:** `Lora` (bundled), fallback `Georgia`, then the platform serif. Used for Latin headlines, numbers, and page titles.
- **Interface / body:** platform sans (`SF Pro` on iOS, `Roboto` / `Noto Sans` on Android). Used for body copy, labels, controls, and CJK text.
- **CJK editorial fallback:** `Songti SC`, `Noto Serif CJK SC`, then the system font. Do not ship a large CJK serif font in the first release.

### Scale

| Token | Size / line | Weight | Family | Use |
| --- | --- | --- | --- | --- |
| `display` | 40 / 44 | 500 | Lora | Hero editorial statement |
| `editorial` | 32 / 38 | 500 | Lora | Timeline / Soul headline |
| `pageTitle` | 26 / 32 | 500 | Lora | Top-bar page name |
| `sectionTitle` | 21 / 28 | 500 | Lora | Section heading |
| `bodyLarge` | 16 / 24 | 400 | Sans | Primary reading copy |
| `body` | 15 / 23 | 400 | Sans | Default body |
| `bodySmall` | 13 / 20 | 400 | Sans | Metadata, helper copy |
| `label` | 13 / 18 | 600 | Sans | Buttons, field labels |
| `caption` | 11 / 16 | 500 | Sans | Dense metadata |
| `eyebrow` | 10 / 14 | 600 | Sans | Uppercase brand / section kicker, tracking 1.6 |

### Type rules

- Use sentence case. Avoid all-caps except the small eyebrow label.
- Keep body text at 15–16 px; never shrink below 13 px for essential copy.
- Limit editorial headlines to two lines on a 390 px canvas.
- Use tabular figures for counts and dates when available.
- English display type may use negative tracking (`-0.4` to `-1.0`); Chinese text must not.

## 4. Layout, spacing, and shape

### Grid

- Base unit: **4 px**. Preferred steps: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.
- Page horizontal padding: **24 px**.
- Section gap: **32 px**. Card internal padding: **20 px**. Inline gap: **12 px**.
- Content max width: **520 px** on large screens; the app remains phone-first.
- Bottom action area: fixed, with `safeArea + 16 px`, and content scrolls behind it.

### Radius

| Token | Value | Use |
| --- | --- | --- |
| `r8` | 8 | Small badges, compact controls |
| `r12` | 12 | Inputs, small buttons |
| `r16` | 16 | Cards, tiles |
| `r24` | 24 | Hero blocks, bottom sheets |
| `pill` | 999 | Chips, avatars, progress dots |

### Elevation

- Default cards: `surface` + 1 px `line` border, no shadow.
- Floating / temporary only: soft shadow `0 14 38 rgba(48,55,47,0.06)`.
- Do not stack shadows. Do not use Material elevation tints.

## 5. Core components

### Top bar

- Height 56 px plus status bar; transparent canvas background; no divider unless content scrolls under it.
- Leading icon 24 px inside a 44 × 44 touch target.
- Title uses `pageTitle`, left aligned. Optional eyebrow above in `eyebrow`.
- Right actions are icon-only with semantic labels or text actions in `label`.

### Buttons

- Height: **52 px**. Full-width by default in forms and single-action screens.
- Primary: `primary` fill, `onPrimary` label, radius 12, no shadow.
- Secondary: `surface` fill, 1 px `line`, `primary` label.
- Text: no fill, `primary` label, 44 px minimum height.
- Disabled: 40% opacity, no press animation.
- Pressed: scale to 0.98 over 120 ms. Loading replaces the label with a small spinner and keeps width.

### Inputs

- Height 56 px; `surface` fill; 1 px `line`; radius 12.
- Label above the field in `label`; placeholder in `muted`.
- Focus: 2 px `primary` border, no glow.
- Error: `error` border plus one-line message below in `bodySmall`.
- Keyboard type and action are always explicit. Never rely on placeholder as the only label.

### Cards and tiles

- `surface`, radius 16, 1 px `line`, padding 20.
- A tappable card has a pressed state (scale 0.98 or `surfaceMuted`) and one chevron at most.
- Hero cards may use an image with a 16:9 or 4:3 crop and a 24 px radius; text sits on an opaque block, not on the photo.
- Do not nest cards more than one level.

### Chips

- Height 32 px, horizontal padding 12, radius pill, `surfaceMuted` background, `ink` label.
- Selected: `primary` background, `onPrimary` label, optional check icon.
- Use chips for interests, filters, and compact metadata, not for primary actions.

### Timeline home

- No bottom tabs. Timeline is the single home surface.
- Scrollable day-grouped timeline and fixed bottom Named composer.
- Word cards and talk events share the same timeline.
- Bottom composer is an entry point, not a chat box: “What did you see?”.
- The composer has a send button and a separate `+` page menu.
- `+` opens Words / Me / Settings as a bottom sheet.
- Talk opens as a focused full-screen route from a word card or talk event.

### Bottom sheets

- Top radius 24, `surface` background, drag handle 32 × 4 in `line`.
- Padding 24; title in `sectionTitle`; primary action at the bottom.
- Respect keyboard insets; scroll content, never clip the primary action.

### Lists and dividers

- Row minimum height 64; two-line rows 72.
- Divider: 1 px `line`, inset 24 px from the leading content edge.
- Metadata uses `bodySmall` / `muted`; titles use `bodyLarge` or `label`.

### Feedback

- Snackbar: `ink` background, `canvas` text, radius 12, bottom above the composer.
- Inline error / retry: `warningSurface` block with `warningText`; keep the original input.
- Empty state: one editorial line + one sentence + one action. No illustrations required.
- Loading: skeleton blocks using `surfaceMuted`, or a small spinner in the primary action. Avoid full-screen spinners for content that can skeleton.

## 6. Screen patterns

### Sign in / onboarding

1. Brand wordmark `Named` in Lora + small leaf mark.
2. Eyebrow: `YOUR EVERYDAY, IN ENGLISH`.
3. Editorial title: short, human, one idea.
4. One sentence of context.
5. One field group and one primary action.
6. Secondary text action below.
7. Step progress as 4 small bars; current step uses `primary`.

Do not show a marketing carousel, social login wall, or fake testimonials.

### Timeline

1. No app bar. Start directly with the day-grouped timeline.
2. Day-grouped IM timeline, oldest at the top and newest at the bottom.
3. The timeline opens at the newest entry.
4. A Named entry is one complete word card: input → English word, IPA, POS, common usage, example, Talk.
5. A talk event appears only after the first message; it shows the last message snippet and Continue.
6. `+` opens Words / Me / Settings.
7. Empty state: “What did you see today?” plus the bottom composer.
8. Load earlier history from the top; keep the composer fixed.
9. Do not use public leaderboards or rank learners against each other.

### Soul / Me

1. Page name `Me` in the top bar.
2. Editorial title: “Your world is growing.”
3. One-line supporting sentence.
4. Three quiet counts (discoveries, conversations, saved expressions) with labels.
5. Profile block: age, gender, native language as inline metadata.
6. Interest chips.
7. One short self-description.
8. “My rhythm” / challenge entry.
9. Recent experience card.
10. Reached from the composer’s `+` menu; no bottom tab.

### Named / Word card / Talk event / Talk

- **Named entry:** one text input in the bottom composer. The agent returns a single top-1 result; there is no candidate or correction UI in MVP.
- **Word card:** input → English word, IPA, POS, primary definition, 3–5 natural chunks with examples, grammar note, meaningful US/UK note when relevant, primary example, collapsed scene extensions, Talk. Keep it in the timeline; do not open a separate understanding page.
- **Talk event:** after at least one message, show the last message snippet, time, and Continue. Tapping opens the same conversation.
- **Talk:** focused full-screen chat with fixed text composer above the keyboard. Return refreshes the timeline snippet.
- **Words:** filtered list of named words, reached from the `+` menu.

## 7. Motion

- Micro interactions: 120 ms, `easeOut`.
- Page / sheet transitions: 220–280 ms, `easeOutCubic`.
- Respect `MediaQuery.disableAnimations`; disable waveform and looping motion.
- Never animate text size, layout height, or background color for decoration.

## 8. Accessibility and content

- Touch targets: minimum 44 × 44, preferred 48 × 48.
- Body text contrast: 4.5:1. Large text: 3:1.
- Support system text scaling up to 200%; allow wrapping and scrolling instead of truncating essential copy.
- Every icon-only action has a semantic label. Every image has a purpose; decorative images are excluded from semantics.
- Focus order follows reading order. Sheets trap focus and return it on close.
- Copy: calm, specific, first-person where appropriate. No exclamation marks, hype, or productivity guilt.
- English headlines may be editorial; Chinese and native-language support copy must be plain and direct.

## 9. Flutter implementation map

| Spec | Code |
| --- | --- |
| Semantic colors | `lib/app/theme/app_colors.dart` + `AppPalette` theme extension |
| Type scale | `lib/app/theme/app_text_styles.dart` |
| Spacing / radius / sizes | `lib/app/theme/app_spacing.dart` |
| Material theme | `lib/app/theme/app_theme.dart` |
| Page shell | `lib/core/widgets/app_scaffold.dart` |
| Buttons | `lib/core/widgets/app_button.dart` |
| Fields | `lib/core/widgets/app_text_field.dart` |
| Sheets | `lib/core/widgets/app_bottom_sheet.dart` |

Rules for feature code:

- Read colors from `Theme.of(context).colorScheme` or `context.appPalette`.
- Read type from `Theme.of(context).textTheme`.
- Use `AppSpacing` / `AppRadius`; do not hardcode pixel values except for one-off illustration geometry.
- Do not reference `AppColors` constants directly in feature widgets; they are raw palette values, not semantic state.
- Every new reusable visual pattern goes into `core/widgets` and is documented here before being copied into a feature.

## 10. Definition of done for a screen

- Uses only design-system tokens and components.
- Passes light and dark mode.
- Passes 360, 390, and 430 px widths.
- Has loading, empty, error, and retry states where data is involved.
- Has 44 px touch targets and semantic labels.
- Preserves user input on failure.
- Passes `make check` and has a widget or golden test for the primary state.
