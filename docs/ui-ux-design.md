# Named · Final Mobile UI/UX Direction

**Design basis:** the user-supplied seven-page UI/UX guidelines, applied to **Named**.  
**Product authority:** [PRD V1.0](prd-v1.0.md).  
**Deliverable:** the current photographic mobile UI, both themes, connected click-through flows and review boards.

The reference PDF supplies visual and interaction guidance only. Its “Everyday” name and its proposed MVP phases do not replace Named or change our agreed features and delivery priorities. Soul, Experience, Personal English World and flexible-cycle Challenge remain in scope.

**Implementation contract:** [Mobile UI Design System](ui-design-system.md)

## 1. Visual direction

**Ink & Cobalt (default).** A thoughtful lifestyle journal, personal memory and an efficient conversation companion. Settings also offers **Ink & Parchment** and **Plum & Sand**.

- Real-life photography supplies the visual content. Local sample images stand in for learners' actual discoveries.
- Soft paper is the light canvas; cool charcoal is the dark canvas. Cobalt carries primary actions and selected states; terracotta is a small warm accent.
- Editorial serif headlines and large English words sit alongside legible Chinese interface and native-language support.
- Bounded white or dark surfaces, restrained borders and clear hierarchy replace repetitive colored cards.
- A quiet photographic reference portrait presents Milo as a virtual partner. It does not identify a real tutor.
- Optional correction details and sentence/word help keep natural conversation in focus.
- No decorative gradients, glass panels or AI glow. Reduced-motion settings disable waveform animation.

## 2. Semantic color system

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | `#F7F6F2` | `#171A1D` |
| Surface | `#FFFFFF` | `#20252A` |
| Secondary surface | `#E8EFF7` | `#2A3138` |
| Primary action / selected foreground | `#2F4A6B` | `#A9C2DC` |
| Main text | `#232A31` | `#E7EBEF` |
| Supporting text | `#5F6B76` | `#AAB3BC` |
| Accent / secondary brand | `#B05230` | `#E09A74` |
| Warm surface | `#F0E5D8` | `#352B24` |
| Text on primary | `#FFFFFF` | `#171A1D` |

Alternate families use the same roles; see [Mobile UI Design System](ui-design-system.md#theme-families).

Warning surfaces and borders have additional semantic tokens. Components consume tokens instead of fixed light-theme colors.

### Theme behavior

- Default palette: Ink & Cobalt.
- Palette overrides: Settings → Theme (Ink & Cobalt, Ink & Parchment, Plum & Sand).
- Light/dark follows the system color scheme.
- The palette choice is retained locally; changing it preserves input and does not reset conversation state.
- Photos retain their real colors. Text over a photo uses an opaque readable surface.

### Readability

Targets are 4.5:1 for normal text and 3:1 for large text. Validate rendered foreground/background pairs, including secondary text on warm user-message surfaces, in both themes. Warm-bubble supporting text uses main text color because the secondary palette color alone would fall below the normal-text target there.

## 3. Information architecture

The home surface is a personal **Timeline**. Secondary destinations are reached from the composer's `+` menu:

| Destination | Responsibility |
| --- | --- |
| **Timeline** | Name what you see; read word cards and talk events in a day-grouped IM timeline |
| **Words · 词语** | The named words collected from the timeline |
| **Me · 我** | Soul, personal activity, and preferences |
| **Settings · 设置** | Language and account actions |

**Talk** opens as a focused full-screen experience from a word card or talk event. It is not a tab.

### Current screen map

1. Sign in and native language.
2. Timeline empty state.
3. Timeline with a word card.
4. Talk event.
5. Talk.
6. Words.
7. Me / Soul.
8. Settings and language.

Key states include first use, empty timeline, processing, request failure, long history, and keyboard-visible composer. There is no candidate confirmation in MVP: the agent returns one top-1 result.

## 4. Main journeys

### First naming

Soul → Timeline → Name a thing or describe a moment → Word card or Moment card → Talk → Talk event.

The composer is the product entry point: the learner sees something, names it, or describes what happened, and gets one English result. A word or short noun phrase becomes a Word card; a complete sentence becomes a Moment card with natural English and key chunks. There is no candidate picker. Challenge/task prompts are deferred; when added they must not turn the timeline into a course dashboard.

### Revisit words

`+` → Review 3 → word prompt → Show meaning → Next / Finish → Back to timeline.

Review is a short active-recall loop over the learner's own words. It is not a scored quiz, does not claim mastery, and does not add a dashboard or tab.

### Return to a conversation

Timeline → Talk event → Continue → Additional messages → Return.

The talk event shows the last message snippet. Returning to the timeline refreshes the snippet without creating a new conversation.

### Revisit a word

`+` → Words → Named word → Talk.

Words is a filtered view of the same timeline; it does not keep a second copy of the data.

### Challenge

Me → Challenges → Name, duration, explicit content selection → Continue selected discoveries → End the round → Revisit later.

Duration is a plan; reaching a date does not delete content or imply mastery. Visited-content progress is labelled accordingly. Multiple rounds can remain accessible. These interaction details remain design proposals within the existing Challenge feature.

## 5. Conversation and history

- The upper region contains a restrained virtual-person reference, topic and status.
- The lower region contains synchronized-text presentation and fixed text/voice controls.
- The composer's `Aa` action opens `Help me say it`; the helper returns one natural English expression, optional note, audio, and `Use this`, and never creates a conversation message.
- Users can pause, retry unclear speech, replay, choose slower playback and continue an old exchange.
- Useful words are quietly underlined. Sentence help includes the original sentence, native explanation, relevant IPA/keywords and listening controls.
- Expression suggestions are separate, expandable and preserve the user's original wording.
- Conversation, global History, word-level history and Experience source links use the same session objects in the design model. The production implementation must preserve this single-source invariant with reliable persistence.
- History cards foreground a date, scene/topic and personal context, not anonymous timestamps.
- An Experience summary can be adjusted without replacing its source transcript.
- Me shows actual discoveries, exchanges and saved expressions. There are no invented mastery scores or leaderboard-driven progress.

## 6. Interaction and accessibility foundations

- Reference canvas: 390 × 844. Verify 360 and 430 widths as well.
- Fixed bottom controls, independently scrolling content and clear touch targets.
- Strong keyboard focus, modal focus containment, Escape dismissal and focus return.
- Visible retry states retain user input and conversation text.
- Appearance controls update only visual state, preserving text drafts.
- Shared tokens establish the foundation for later website and TV adaptations. This delivery implements the current mobile design; TV directional navigation and desktop knowledge layouts require their platform-specific layouts.

## 7. Current deliverables and verification

- [Interactive UI](prototypes/named.html).
- [Light core screens](prototypes/named-overview.png) / [Dark core screens](prototypes/named-overview-dark.png).
- [Personal screens](prototypes/named-personal-world.png) / [Dark personal screens](prototypes/named-personal-world-dark.png).
- [Prototype guide](prototypes/named-guide.md).
- [Bundled photo credits](prototypes/assets/README.md).

The previous illustration implementation has been removed and previous screenshots replaced. Both theme preview sets represent the current design.

Browser verification covers the learning and revisit journeys, shared history, source-preserving edits, themes and system changes, sentence help, Challenges, empty/retry states and layouts. Rendered text foreground/background pairs are checked against AA contrast targets. AI, recognition, speech, extraction and backend persistence remain simulations; this is the reviewable UI/UX deliverable.
