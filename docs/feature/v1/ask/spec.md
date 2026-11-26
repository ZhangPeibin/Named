# Ask 9/10 Product + Engineering Spec

| Item | Value |
| --- | --- |
| Status | Phase 1 implemented |
| Release | v1.1 |
| Feature | Ask |
| Owner | TBD |

> **2026-11-25 修订：** "Milo" 现在指用户命名的 companion；本文保留当时的 v1.1 决定，命名与存在感见 `docs/feature/v2/companion-presence/discussion.md` 和 ADR 0006。
| Parent issue | [#49](https://github.com/ZhangPeibin/Named/issues/49) |
| Baseline | Ask v1 is implemented: standalone Ask page, one-shot question, saved exchange |
| Target | 9/10 |

## 1. Goal

Make Ask the natural response to “I don’t understand this” anywhere in Named.

A 9/10 Ask experience means:

> The learner can ask from the exact word, sentence, or moment they are stuck on, get a clear answer in simple English with native-language support, ask a natural follow-up, and find the whole thread again later.

This is not a general-purpose chatbot. It is a contextual English tutor with a short memory.

## 2. Why the current version is not 9/10

Current Ask is a useful foundation but only scores around 6/10:

- Ask is an isolated page with no connection to the content that caused the question.
- The composer `?` entry is hard to discover.
- A learner cannot ask a follow-up in the same context.
- The answer is one block of text; it does not consistently show an example, native explanation, or uncertainty.
- History exists but has little product meaning.
- Empty state gives no example questions.
- There is no fast path from Word details, Sentence details, Talk, or Daily reading into Ask.

## 3. Users and jobs

Primary learner:

- Encounters English in real life, Talk, or Daily reading.
- Often knows the rough meaning but not why the sentence works that way.
- Wants a direct answer, not a full lesson.
- Reads in English but may need the explanation in their native language.
- May return to the same question later.

Jobs to be done:

1. “What does this mean here?”
2. “Why is this grammar used?”
3. “What is the difference between these two expressions?”
4. “Can you make this sentence more natural?”
5. “I understood the answer, but I have one more question.”

## 4. Product principles

1. **Context before input.** Ask should carry the word, sentence, reading, or conversation that caused the question.
2. **Answer, don’t lecture.** Lead with the direct answer. Examples and nuance come after.
3. **Short memory.** Follow-ups stay in the same thread and retain context.
4. **One step to ask.** The learner should not have to reconstruct a sentence to ask about a selection.
5. **Quiet, readable design.** Ask is a thinking surface, not a dashboard.
6. **Uncertainty is allowed.** If the answer is not reliable, say so instead of inventing confidence.
7. **Saved by default.** A useful explanation should not disappear when the page closes.

## 5. Core journey

```text
Learner sees a word / sentence / reading / Talk message
        ↓
Ask about this
        ↓
Question is prefilled with context and a suggested wording
        ↓
Learner edits or sends immediately
        ↓
Direct answer + example + native explanation
        ↓
Follow-up in the same thread
        ↓
Thread is saved and reopenable
```

## 6. Entry points

### 6.1 Global Ask entry

Keep the Timeline composer entry, but make it discoverable:

- A labeled `Ask` action next to the composer send button.
- Use a question-answer glyph and visible label, not only a bare `?`.
- One tap opens Ask with the composer focused.
- Composer hints occasionally include: `Try asking a question`.

### 6.2 Contextual Ask

This is required for 9/10.

Add `Ask about this` to:

- Word details sheet
- Sentence details sheet
- Talk long-press actions
- Daily reading word/sentence actions
- Optional: selection in a Talk message

The action opens Ask with:

- `context_type`: `word`, `sentence`, `reading`, `talk`, or `none`
- `context_ref`: word ID, experience/message ID, reading date, etc.
- `context_quote`: selected English text
- `suggested_question`: a useful default such as:
  - “What does this mean in this sentence?”
  - “Why is this grammar used here?”
  - “Make this sentence more natural.”

The learner can send the suggested question immediately or replace it.

### 6.3 Ask home

`/ask` shows:

- A prominent “Ask anything” composer
- 3–6 recent question threads
- If opened from context, starts a new thread with the context card visible

## 7. Conversation behavior

A thread contains one or more question/answer turns.

Rules:

- First ask creates a thread.
- Follow-up stays in the same thread.
- Thread history includes the last N turns, capped at 10 messages for the agent.
- Follow-ups include the thread context and prior turns.
- Starting from a different context starts a new thread unless the user explicitly continues an existing one.
- If a context is stale or deleted, the thread still opens and shows the stored quote; a new answer may proceed without the live reference.
- A follow-up composer is always available at the bottom of a thread.

## 8. Answer contract

Every assistant answer returns:

```json
{
  "answer": "Direct answer in simple English.",
  "example": "Optional short example or contrast.",
  "native_explanation": "Clear explanation in the learner's native language.",
  "confidence": "high",
  "follow_up_suggestions": [
    "Why not use will here?",
    "Show me another example."
  ]
}
```

Display:

```text
ANSWER
Because “would” describes an imagined result here.

EXAMPLE
If I had more time, I would read more.

中文解释
这里 would 表示假设，不是过去将来。

[ Ask a follow-up ]
```

Rules:

- `answer` is required and leads.
- `example` is optional but encouraged for grammar/usage questions.
- `native_explanation` is required unless the learner's native language is English.
- `confidence` is `high`, `medium`, or `low`.
- Low confidence should be visible but not alarming.
- `follow_up_suggestions` are optional, maximum 2.
- No Markdown.
- Answers should stay under 220 words unless the question truly needs more.

## 9. UI specification

### Ask home

- App bar: `Ask`
- Empty state:
  - Warm illustration mark
  - “What are you curious about?”
  - 3 suggestion chips
- Recent threads:
  - Context type icon
  - Short title / first question
  - Last updated
  - Optional snippet of latest answer
- Composer fixed above safe area
- Light/dark reader-compatible palette
- No permanent bottom navigation

### Context card

When Ask starts from a word/sentence:

```text
FROM THIS SENTENCE
“If I had more time, I would read more.”
```

The card is collapsible and removable. Removing it starts an uncontextualized thread.

### Thread screen

- Back to Ask home
- Thread title
- Context card
- User questions on the right, warm bubble
- Answers as surface cards
- Native explanation under a muted divider
- Follow-up composer at bottom
- Auto-scroll to newest answer
- Loading state: skeleton or thinking indicator
- Error state: inline retry, preserve the question text

### Visual direction

- Quiet editorial layout, consistent with Timeline
- Warm accents, not bright chat-app bubbles everywhere
- Custom Ask mark or small Milo mark for identity
- No generic robot avatar
- Use `ContentAccents` / theme tokens; do not hardcode a second palette
- Full light/dark support

## 10. History

Ask home lists recent threads, newest first.

Requirements:

- Threads survive app restart.
- Tapping a thread reopens all turns and context.
- Empty history shows suggestions, not an empty list.
- Optional v1.1: delete a thread.
- Optional v1.1: continue a thread from history.
- Do not place every Ask exchange in Timeline by default.
  - Ask is a utility/history surface, not a personal discovery.
  - A future “Save to Timeline” action can be added separately.

## 11. Data model

Replace the one-shot exchange shape with threads and messages.

### `question_threads`

- `id`
- `account_id`
- `title`
- `context_type` nullable
- `context_ref` nullable
- `context_quote` nullable
- `created_at`
- `updated_at`
- `deleted_at` nullable

### `question_messages`

- `id`
- `thread_id`
- `role` (`user` / `assistant`)
- `text`
- `example` nullable
- `native_explanation` nullable
- `confidence` nullable
- `created_at`

### Migration

- Add `question_threads` and `question_messages`.
- Backfill existing `question_exchanges` into one thread + two messages.
- Keep old table read-only for one release, then remove in a later migration.

## 12. API

```text
POST   /api/v1/questions
GET    /api/v1/questions
GET    /api/v1/questions/{thread_id}
POST   /api/v1/questions/{thread_id}/messages
DELETE /api/v1/questions/{thread_id}
```

### Create thread

```json
{
  "text": "Why is would used here?",
  "context": {
    "type": "sentence",
    "ref": "experience-id",
    "quote": "If I had more time, I would read more."
  }
}
```

### Follow-up

```json
{
  "text": "Could I use will instead?"
}
```

Response includes the updated thread or the new assistant message.

### Rules

- Authenticated only.
- Rate limit Ask separately from Talk.
- Context values are validated for length and existence when possible.
- Agent history is capped at the last 10 messages.
- Idempotency is not required for text questions.
- Return stable problem+json errors.

## 13. Agent design

Use the shared `AgentRuntime`.

Tool: `QuestionAgent`

Inputs:

- latest question
- native language
- context type/quote
- previous thread turns, trimmed

Prompt requirements:

- Answer the actual question first.
- Use simple English.
- Add one useful example when helpful.
- Explain in the learner's native language.
- State uncertainty explicitly.
- Do not invent sources.
- Do not turn the answer into a generic lesson.
- Do not use Markdown.
- Return the structured answer contract.

Prompt version: `question-v2`.

## 14. Quality and safety

- For grammar/usage questions, prefer conservative answers.
- If the model is unsure, `confidence` must be `low` and the answer should say what is uncertain.
- Reject empty and overlong questions.
- Do not claim web research or sources in v1.1.
- Do not store secrets or raw private conversations in logs.
- Rate-limit abuse.
- If the question tries to change the assistant’s role into an unrestricted general chatbot, keep the answer useful but scoped to English learning.

## 15. Analytics

Track product events without content by default:

- `ask_opened` with source: `composer`, `word`, `sentence`, `reading`, `talk`
- `ask_sent`
- `ask_answered`
- `ask_follow_up_sent`
- `ask_thread_reopened`
- `ask_error`
- `ask_suggestion_selected`

Do not log raw question or answer text in analytics.

Success signals:

- Ask opened from context rather than only from composer
- Follow-up rate
- Thread reopen rate
- Answer error rate
- Median time to first useful answer

## 16. Acceptance criteria

### Entry

- A learner can enter Ask from the Timeline composer in one tap.
- A learner can enter Ask from a word detail, sentence detail, Talk message, and Daily reading in one tap.
- Context is visibly carried into the Ask screen.
- Composer hint can teach the Ask entry without blocking discovery.

### Conversation

- First ask creates a saved thread.
- Follow-up stays in the same thread and uses prior context.
- Reopening a thread shows all turns in order.
- The learner can start a new uncontextualized thread.

### Answer

- Answer shows direct answer, optional example, native explanation, and confidence state.
- Low-confidence answers are explicitly cautious.
- No Markdown is shown.
- Long answers are progressive or have a clear loading state.

### States

- Empty, loading, thinking, error, retry, and offline states are covered.
- Failed questions preserve the learner's text.
- Light/dark mode are both readable.
- Layout works on small phones.

### Engineering

- Backend tests cover thread creation, follow-up, context, list, delete, auth, and rate limits.
- App tests cover entry, ask, answer, follow-up, error, and history.
- `make check` passes.
- Migration/backfill is tested.

## 17. Delivery phases

### Phase 1 — 9/10 core

1. Contextual entry from Word, Sentence, Talk, Daily
2. Thread + message data model and migration
3. Create thread / load thread / follow-up APIs
4. Structured answer contract
5. Ask home and thread UI
6. History list and reopen
7. Error/retry/focus and light/dark

### Phase 2 — polish

1. Suggested questions per context
2. Streaming or sub-second perceived progress
3. Delete thread
4. “Save to Timeline” optional action
5. Follow-up suggestion chips
6. Analytics and quality review

## 18. Out of scope

- Web search and citations
- Voice questions
- Image questions
- Autonomous multi-agent research
- Knowledge-graph linking
- Automatic Soul updates
- Social sharing

## 19. Open decisions

- Should context ask be available from every long-press menu, or only Word/Sentence details?
- Should there be one follow-up thread per context, or allow multiple threads from the same context?
- Should Ask history also be visible in Me, or only at `/ask`?
- Should Ask answers ever be translated fully, or only have a native explanation section?

## 20. Definition of done

A 9/10 Ask is done when a learner can be reading a sentence, tap once, ask about that exact sentence, get a direct answer with an example and native-language explanation, ask a natural follow-up, close the app, reopen the thread later, and still understand why they asked.
