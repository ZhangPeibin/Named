# Named · Final Mobile UI/UX Direction

**Design basis:** the user-supplied seven-page UI/UX guidelines, applied to **Named**.  
**Product authority:** [PRD V1.0](prd-v1.0.md).  
**Deliverable:** the current photographic mobile UI, both themes, connected click-through flows and review boards.

The reference PDF supplies visual and interaction guidance only. Its “Everyday” name and its proposed MVP phases do not replace Named or change our agreed features and delivery priorities. Soul, Experience, Personal English World and flexible-cycle Challenge remain in scope.

## 1. Visual direction

**Warm Editorial Minimalism.** A thoughtful lifestyle journal, personal memory and an efficient conversation companion.

- Real-life photography supplies the visual content. Local sample images stand in for learners' actual discoveries.
- Ivory is the light canvas; deep forest is the dark canvas. Green is reserved for primary actions, identity and interaction states.
- Editorial serif headlines and large English words sit alongside legible Chinese interface and native-language support.
- Bounded white or dark surfaces, restrained borders and clear hierarchy replace repetitive green cards.
- A quiet photographic reference portrait presents Milo as a virtual partner. It does not identify a real tutor.
- Optional correction details and sentence/word help keep natural conversation in focus.
- No decorative gradients, glass panels or AI glow. Reduced-motion settings disable waveform animation.

## 2. Semantic color system

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | `#F5F2E9` | `#1C211D` |
| Surface | `#FFFFFF` | `#252C26` |
| Secondary surface | `#E5E9DF` | `#303930` |
| Primary action / selected foreground | `#526B4B` | `#A7BC96` |
| Main text | `#30372F` | `#E9E8DF` |
| Supporting text | `#646A60` | `#B8BDB2` |
| Accent / secondary brand | `#A7BC96` | `#718568` |
| Warm surface | `#E8DDCC` | `#3A352D` |
| Text on primary | `#FFFFFF` | `#1C211D` |

Warning surfaces and borders have additional semantic tokens. Components consume tokens instead of fixed light-theme colors.

### Theme behavior

- Default: follow `prefers-color-scheme`.
- Overrides: System / Light / Dark in the review toolbar and Me → Preferences.
- Theme follows system changes while System is selected.
- The appearance choice is retained locally; changing theme preserves input and does not reset conversation state.
- Photos retain their real colors. Text over a photo uses an opaque readable surface.

### Readability

Targets are 4.5:1 for normal text and 3:1 for large text. Validate rendered foreground/background pairs, including secondary text on warm user-message surfaces, in both themes. Warm-bubble supporting text uses main text color because the secondary palette color alone would fall below the normal-text target there.

## 3. Information architecture

Four mobile destinations organize the five responsibilities from the visual reference:

| Root destination | Responsibility |
| --- | --- |
| **Explore · 探索** | Take a photo, start talking, type a word; return to a current Challenge or recent discovery |
| **Words · 词语** | Search personal words/scenes and their connected content |
| **History · 回忆** | Find meaningful exchanges by date, scene or topic, then reread and continue |
| **Me · 我** | Actual personal activity, Soul, Challenges and preferences |

**Talk** opens as a focused full-screen experience from a discovery, a thought or saved context. It is not a competing bottom tab.

### Complete screen map — 20 main screens

1–4. Interests, age, gender, native language and short daily-life introduction.  
5. Explore.  
6. Photo/text Discover.  
7. Discovery result and focus confirmation.  
8. Word understanding.  
9. Talk.  
10. Conversation summary.  
11. Words / Personal English World collection.  
12. Global History.  
13. Connected word: Discovery / Conversation / Knowledge / History.  
14. Full original conversation.  
15. Experience detail and summary editing.  
16. Me / Soul.  
17. Challenge list.  
18. Challenge creation.  
19. Challenge detail.  
20. Preferences, including appearance.

Key states include first use, an empty collection, processing, listening, thinking, pause, unclear input and save/recognition retry. Sheets cover language help, sentence understanding, recognition adjustment and Experience editing.

## 4. Main journeys

### First discovery

Four-step Soul → Explore → Photo or text → Confirm focus → Word → Talk → Experience → Words.

Capture is immediately available. A current Challenge is placed before the recent-story list; it does not become a course dashboard. Missing demographic answers remain unset and do not infer language level or interests.

### Start with something to share

Explore → Start talking → A short thought or situation → Talk → Experience.

This establishes its own scene context. It does not silently reuse an unrelated previous word or force the user to say they were walking in a park.

### Return to a memory

History → Scene/topic card → Complete source conversation → Continue → Additional personal contribution → New Experience.

Alternatively: Words → Connected word → History or Conversation → the same source exchange.

### Challenge

Explore or Me → Challenges → Name, duration, explicit content selection → Continue selected discoveries → End the round → Revisit later.

Duration is a plan; reaching a date does not delete content or imply mastery. Visited-content progress is labelled accordingly. Multiple rounds can remain accessible. These interaction details remain design proposals within the existing Challenge feature.

## 5. Conversation and history

- The upper region contains a restrained virtual-person reference, topic and status.
- The lower region contains synchronized-text presentation and fixed text/voice controls.
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
