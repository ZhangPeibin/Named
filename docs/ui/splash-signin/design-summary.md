# Splash + Sign in — design summary

Feature: `splash-signin`
Mode: adopt (to-be spec for `app/lib/features/loading/presentation/loading_page.dart` and
`app/lib/features/auth/presentation/sign_in_page.dart`)
Branch: `feature/splash-signin-refresh`

## Purpose

Cold start should feel like one continuous brand moment: the native splash hands off to an
in-app splash with the same ground and the same woven-N mark, then the sign-in screen carries
the brand lockup while asking for native language and an email code.

## Hierarchy

**Splash**

1. The woven-N symbol, centered.
2. A 96 × 2 px indeterminate line near the bottom.

There is no title, no wordmark, and no action. The screen exists for under a second and its
only job is to avoid a visual jump from the native splash.

**Sign in**

1. Primary element: the horizontal brand lockup (woven N + `Named`), fixed across both steps.
2. Step indicator: two bars, active bar wider and in `primary`.
3. Primary action: `Continue` on step 1, `Verify` on step 2.
4. Secondary: `I already have an account` (text button), `Send code` (outlined), back
   (icon button, step 2 only).
5. Everything else (eyebrow, editorial title, intro, fields) descends from that.

## Why these choices

- The brand kit (`docs/brand-identity.md`, `docs/brand/logo/round7/c-weave/`) retires the old
  Lora + leaf mark. The lockup is the primary horizontal lockup, rendered from the outlined
  Manrope 800 artwork so the wordmark is not retyped in Lora.
- The native splash is `#FBF8F2` light and `#171A1D` dark. The in-app splash uses the same
  fixed grounds (`color.splash_ground`) instead of the family `canvas`, so the first Flutter
  frame cannot flash a different paper. Sign-in then moves to the family `canvas`, which is
  intentional: the splash is brand ground, the form is app surface.
- The splash shows the symbol only because that is exactly what the native splash shows. The
  wordmark appears on sign-in, so nothing has to resize or move during handoff.
- The shipped flow has two steps, so the indicator has one bar per step. The design-system note
  now states this rather than a fixed four bars.

## Layout

- Splash: `safe_area` → `stack`; mark centered at `size.logo_symbol`; progress line at
  `bottom_center` with `space.s32` margin. Background `color.splash_ground`.
- Sign in: `safe_area` → `column` with `space.page_horizontal` side padding and `space.s8`
  top. Header stack is `size.logo_lockup_height` tall; lockup is `size.logo_lockup_width`
  wide and centered; the back button is a 48 dp target aligned `center_start`, so it overlaps
  the header instead of pushing the lockup off-center.
- Step panel: vertical `scroll_view` with `space.s32` top/bottom padding, `cross_axis_alignment:
  stretch`, `gap: space.s12`. Titles use `type.editorial`, intros `type.body_large` in
  `color.muted`, fields are `outlined` 56 dp, primary actions are 52 dp full width.

## States

| Screen state | Visible | Hidden |
| --- | --- | --- |
| splash / loading (default) | mark, progress | — |
| splash / leaving | — | mark, progress |
| sign_in / language_step (default) | language panel | email panel, back, code block, verify, errors |
| sign_in / language_error | language panel, language error | email panel, back, code block, verify, email error |
| sign_in / email_step | email panel, back | language panel, code block, verify, errors |
| sign_in / sending_code | email panel, back | language panel, code block, verify, errors |
| sign_in / code_sent | email panel, back, code block, verify | language panel, errors |
| sign_in / verifying | email panel, back, code block, verifying button | language panel, errors |
| sign_in / verify_error | email panel, back, code block, verify, email error | language panel, language error |

Loading lives inside the acting button (`Send code`, `Verify`); the page never blanks. Empty
cannot occur because both steps are single-field forms. Splash error cannot occur as a screen
state: a failed session read is treated as signed out and the router shows sign in. Every
error keeps the typed language, email, and code.

Component states: `send_code_button` has `disabled` (invalid email, 40% opacity), `sending`
(spinner), and `counting_down` (content becomes `00:59`); `verify_button` has `loading`;
`step_bar_email` has `active`.

## Interactions

| Node | Trigger | Action | Outcome |
| --- | --- | --- | --- |
| splash root | appear | navigate → `sign_in` | Router replace; a saved session goes to the timeline instead |
| `language_field` | submit | set_state → `email_step` | Validates and stores the language |
| `continue_button` | tap | set_state → `email_step` | Same as submit |
| `existing_account_button` | tap | set_state → `email_step` | Skips the initial Soul |
| `back_button` | tap | set_state → `language_step` | Keeps typed values |
| `email_field` | blur | custom | Changing the address clears the sent code |
| `send_code_button` | tap | custom + set_state | Requests a code, starts the 60 s countdown, reveals the code block |
| `otp_field` | submit | custom | Verifies when all six digits are present |
| `verify_button` | tap | custom | Verifies and the router replaces the route with the timeline |

## Responsive behaviour

Breakpoints: compact 0–599, medium 600–1600. At medium the sign-in column is capped at
`size.page_max_width` (520) and stays centered. The header uses a stack, so the 200 dp lockup
never competes with the 48 dp back target at 320–360 dp widths. All panels scroll, so 200%
text scaling cannot clip the primary action.

## Dependencies

- `backend:auth.request-code` — send the 6-digit email code.
- `backend:auth.verify` — exchange email + code (+ optional initial Soul) for a session.
- `screen:timeline` — post-sign-in destination, already exists; not re-specified here.
- Native splash colors (`#FBF8F2` / `#171A1D`) must stay equal to `color.splash_ground` in
  both design-system files.

## Out of scope

- Legal links, marketing carousel, social login, and password login.
- Changing the auth backend or the two-step order.
- Restyling the rest of the app or the unused `SplashWidget` template leftover.
- Dark-mode family switching inside this flow; it inherits `design-system.dark.json`.

## What changed

- Replaced the old Lora + leaf header with the woven-N horizontal lockup from the brand kit.
- Removed the `Named` + leaf title from the splash; the symbol alone now matches the native
  splash, and the ground is fixed brand paper instead of the family canvas.
- Added the branded eyebrow (`YOUR EVERYDAY, IN ENGLISH`) to the language step, using the
  existing `auth.brandEyebrow` string.
- Reworked the header into a stack so the back button is a 48 dp target without off-centering
  the lockup.
- Replaced the implicit/decorative progress dots with a two-bar step indicator that matches
  the two real steps, aligned to the button language (52 dp primary, outlined secondary).
- Restyled `Send code` from a 38 dp pill to the standard 52 dp outlined button with its
  countdown kept as a state.
- Documented and enforced loading/error states with input preservation in the spec.

## Implementation contract

Files:
- docs/ui/splash-signin/mobile-ui.json
- docs/ui/design-system.json
- docs/ui/design-system.dark.json

Standards:
- button filled → FilledButton (at most one per step)
- button outlined → OutlinedButton
- button text → TextButton
- text_field outlined → TextField / AppTextField
- icon_button standard → IconButton with 48 dp target
- progress_indicator linear → LinearProgressIndicator
- image → Image.asset with semanticLabel

Invariants:
1. Screen hierarchy: splash = centered woven-N mark + 2 px line; sign in = centered lockup, 2-bar step indicator, one step panel at a time, one primary action per step.
2. States: language step → email step → code sent → verifying; errors stay inline and keep typed input; loading lives in the acting button.
3. Tokens only; no color or spacing literal in feature code — the splash ground comes from the theme layer, not a feature widget.

Deviations:
- splash background = `color.splash_ground` instead of `color.canvas` — must equal the native splash color to avoid a cold-start flash across theme families.
- `otp_field` = existing six-box `AppOtpField` instead of a single standard field — a 6-digit code needs per-digit boxes and auto-submit.
- `send_code_button` = outlined button with content-only countdown state — preserves the 60 s resend guard without adding a second component.
- `brand_lockup` = image asset, not text — the wordmark is outlined Manrope 800 and Manrope is not bundled.
- splash shows the symbol only, no wordmark — mirrors the native splash image exactly.

Dependencies:
- backend:auth.request-code
- backend:auth.verify
- screen:timeline

Acceptance:
- "$SKILL_DIR/scripts/ui" check docs/ui/splash-signin
- "$SKILL_DIR/scripts/library" check
- (cd app && make check)
