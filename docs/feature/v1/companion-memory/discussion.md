# Companion Memory - Requirements Discussion

**Status:** ready-for-agent
**Release:** v1
**Feature:** companion-memory

## Problem

Named currently keeps independent Talk conversations, but Milo does not carry a durable, account-scoped understanding of what the learner has studied, struggled with, or shared. The learner has to re-establish context, and Talk cannot make use of learning history unless it happens to be in the current conversation.

The product direction is one Milo companion per account with durable memory. This first slice is intentionally backend-only: it should improve Talk and Help responses without changing the app UI or conversation structure.

## Users and Outcomes

- A learner can return to any Talk and find Milo using relevant prior learning context naturally.
- Milo can remember explicit personal context, recurring learning errors, studied words/scenes, expressions, and life experiences shared by the learner.
- Memory is account-scoped and traceable to a source conversation message.
- The learner is not shown a memory management screen in this slice.

## Current Experience

- The app still has a Timeline home and independent full-screen Talk conversations.
- `backend/src/talk/service.py` assembles focus context, Soul context, and recent conversation history for each Talk turn.
- Corrections and annotations are persisted, but no durable memory is derived from them.
- The app does not call the conversation end endpoint, so memory extraction cannot depend on conversation end.

## Scope

### In Scope

- Account-scoped memory records derived from Talk turns.
- Memory kinds: identity, learning error, word, expression, experience, topic, preference.
- Candidate extraction from the learner's message as part of the Talk response.
- Deterministic correction memories so clear errors are retained even if the model omits them.
- Deduplication, mention counts, timestamps, source references, and confidence/importance.
- Weighted retrieval using content type, recency, frequency, and current-topic relevance.
- Memory context injection into Talk and Help generation.
- Account isolation and soft deletion.

### Out of Scope

- Any app UI change, memory screen, or conversation/branch redesign.
- Per-user model fine-tuning.
- Automatic curriculum planning or mastery scoring.
- Memory-aware Review selection in this slice.
- User-facing memory editing or deletion UI.

## Required Behaviour

- After a Talk turn, explicit learner facts and learning signals can be stored as memory items.
- AI-generated examples, inferred life facts, and unconfirmed details must not become memory.
- Repeating the same memory increments its mention count instead of creating a duplicate.
- Memory retrieval ranks relevant items and stays within a bounded prompt budget.
- Talk and Help prompts receive only relevant account memories.
- Another account's memories are never visible.
- Deleted or expired memories are excluded from retrieval.
- Memory extraction failure must not make the Talk turn fail.

## Edge and Failure Cases

- The model returns no memories: the turn succeeds; no memory is written.
- The model returns duplicate candidates: they are merged.
- A correction exists but no candidate is returned: a deterministic learning-error memory is still written.
- Memory writes fail: the Talk turn and saved messages remain successful.
- Memory text is too long: it is rejected or bounded before storage.
- Same memory appears in multiple conversations: mention count and last-seen time update.
- An account is deleted: memories cascade with the account.

## Constraints and Dependencies

- Keep the existing app/API response contract unchanged.
- Extraction happens in the same Talk turn, without a second AI call.
- Memory ranking is deterministic and configurable; no learned weights in v1.
- Retrieval uses simple lexical relevance in v1.
- Logs must not contain full learner memory text.

## Decisions

- **App UI remains unchanged.** This slice is backend-only and affects Talk/Help response quality.
- **One account-scoped memory store.** This is not a separate model per learner.
- **All memory kinds are stored**, with type-specific weights and decay half-lives.
- **The Talk response carries memory candidates.** This avoids a second model call and keeps extraction aligned with the turn.
- **Extraction is per turn** because the current app does not signal conversation end.
- **Memory is best effort.** A memory failure must not fail the Talk response.
- **v1 ranking is fixed-rule:** type weight × recency × frequency × lexical relevance.
- **Talk and Help are the only consumers in this slice.**

## Open Questions

- Exact type weights, half-lives, and per-kind caps need tuning against real conversations. This is a configuration/technical follow-up, not a PRD blocker.
- Whether Review should consume memory is deferred.
- User-facing memory inspection and editing is deferred.

## Evidence

- `docs/prd-v1.0.md` sections 4, 5.3, 5.4, 5.9, 5.10, 5.11.
- `docs/feature/v1/talk-and-conversation/discussion.md`.
- `backend/src/talk/service.py`, `backend/src/talk/agent.py`, `backend/src/models.py`.
- Conversation on 2026-11-09: app unchanged; backend Agent memory; weighted by content type, time, and frequency; consumed primarily by Talk.

## Session Log

- 2026-11-09: User approved a backend-only companion memory layer. App UI remains unchanged. Memory covers all learning and personal content with weighted retrieval and is used in Talk/Help.

- 2026-11-09: Implementation tickets published as #34 (extract/persist) and #35 (weighted retrieval/injection). Backend-only implementation started in the `companion-memory` worktree.
