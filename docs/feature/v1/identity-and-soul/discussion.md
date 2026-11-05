# Identity and Soul - Requirements Discussion

**Status:** ready-for-prd
**Release:** v1
**Feature:** identity-and-soul

## Problem

Define how a person becomes a Named user, how they sign in or register, and how their personal learning identity (Soul) is established.

## Users and Outcomes

- A person can establish one personal Named identity and return to their own learning history.
- A learner can provide enough optional or required background for Named to personalize early conversations without a burdensome onboarding process.

## Current Experience

The current prototype presents a four-step Soul introduction: interests, age, gender, then native language and a short daily-life introduction. Steps can be skipped, revisited, and edited later. Prototype data is temporary and does not implement registration, authentication, account recovery, or cross-device persistence.

The PRD requires lightweight Soul onboarding and supports children and adults. Account identity and authentication are not implemented in the prototype.

## Scope

### In Scope

- Registration, sign-in, sign-out, and returning-user identity for the first release.
- Initial Soul creation and later viewing or editing.
- One learner profile and its conversations, discoveries, and experiences.
- Passwordless email/code registration and sign-in, shared by new and returning users.

### Out of Scope

- Specific authentication vendor, token format, and server-side session implementation unless they materially affect user-visible requirements.
- Detailed Agent memory and context assembly behavior; discuss during Agent design.
- Production implementation during this requirements discussion.

## Required Behaviour

- Authentication should let a user return to their own saved learning history across sessions and devices.
- Soul should give Named useful learner-provided background while keeping onboarding lightweight.
- A learner's content must remain associated with that learner's account.
- Native language is the only required initial Soul field. Optional age and gender may be skipped; interests and learning preferences can be learned later through use.
- Age and gender, if collected, are user-provided background and must not be used to infer proficiency, interests, or experiences.

## Edge and Failure Cases

- A user abandons registration or onboarding and returns later.
- A user forgets credentials or loses access to their sign-in method.
- A learner skips Soul questions or wants to correct background information later.
- Account deletion, learner-data deletion, and recovery expectations need to be defined.

## Constraints and Dependencies

- First release clients are Flutter apps for iOS and Android; Android TV is a later adaptation target.
- Backend scaffold is Python/FastAPI with MySQL and self-hosted deployment.
- Product scope and existing Soul requirements are in `docs/prd-v1.0.md`, particularly sections 5.10 and 10.
- Authentication affects data ownership and authorization, so the learner identity model must be clear before production schema and endpoints are designed.

## Decisions

- This feature is assigned to release `v1`.
- The discussion covers the user-facing identity and Soul experience; Agent context assembly is deferred to Agent implementation design.
- First-use flow: the learner chooses a native language, may optionally provide age or gender, then immediately completes email/code registration or sign-in. The initial Soul is bound to the account after code verification. Soul must not infer personal facts from photos or AI-generated content.
- V1 uses one account for one learner profile. It does not distinguish child and adult account types, support parent-managed subprofiles, or provide learner switching. A person who uses Named has one Soul and one personal learning history.
- V1 offers passwordless email registration and sign-in: the user enters an email address and a one-time code sent to that address. Apple and Google sign-in are deferred to a later release.
- Registration and sign-in share one email/code entry point. After code verification, the system creates an account for a new email or restores the existing account for a returning email; users do not choose between separate Sign up and Log in paths.
- If the app is closed before email verification, initial Soul information remains temporarily on that device so the user can resume verification. Before verification, this unbound information is not uploaded to an account.
- Interests and learning preferences are not required during first use. They can be learned from later user-provided conversation content and must remain visible, editable, and removable by the user.
- `soul.md` is a generated Agent-context representation, not the canonical production record. The backend stores structured Soul facts and their sources, then generates a bounded, versioned `soul.md` for the Orchestrator when needed. User updates regenerate the representation without replacing the underlying facts or conversation history.
- Each account's Soul is stored as structured data in MySQL and associated with that account. Explicit profile fields (such as native language and optional age/gender) and individually managed interests/preferences retain their source and update history as appropriate. `soul.md` is generated from this data; it is not the source of truth.
- Before email verification, the pending Soul stays on the device and can be resumed on that device. It is cleared when binding succeeds or when the user explicitly starts over; no cross-device recovery is offered before sign-in.
- Email one-time-code access is the sole v1 account recovery method. Users who lose access to their email cannot recover the account through another method in v1.
- Users can request account deletion in the product. Deletion removes the account's Soul and personal learning content; detailed operational timing is technical design.
- The system may automatically add interests and learning preferences explicitly shared by the user in conversation to structured Soul data. Each item keeps its source and can be viewed, edited, or removed by the user. Inferences and AI-generated examples are not added as user facts.
- Age and gender may be voluntarily provided and later edited, but are optional and may be skipped. They are not prerequisites for registration or use, and AI must not infer proficiency, interests, or experiences from them.
- Native language is the only required Soul field in the initial onboarding. Interests and learning preferences can be learned later through use; age and gender remain optional.
- Users can change their native language at any time in settings. Explanation language follows the user's explicit selection and is not switched based only on conversational inference.

## Open Questions

No remaining product-level questions block the v1 PRD. Verification-code expiry/rate limits, deletion execution timing, exact MySQL schema, and `soul.md` generation/caching are implementation details for technical design.

## Evidence

- `docs/prd-v1.0.md`: lightweight Soul onboarding; age and gender must not drive unsupported inferences; account and data handling are design-stage questions.
- `docs/prototypes/named-guide.md`: the prototype demonstrates four Soul steps with skip, back, and later-edit affordances; identity and synchronization are not implemented.

## Session Log

- 2026-11-04: Started the v1 discussion at the user's request to decide how a person becomes a Named user, including registration/sign-in and Soul. Confirmed release `v1`; deferred implementation and Agent context design.
- 2026-11-04: Agreed that the learner provides the required native language (and may optionally provide age/gender) before immediately completing email/code registration or sign-in. The initial Soul binds to the account after verification; interruption before verification still needs a defined recovery behavior.
- 2026-11-04: Simplified the v1 identity model to one account and one learner profile, with no child/adult distinction, parent-managed subprofiles, or learner switching.
- 2026-11-04: Chose passwordless email registration/sign-in using a one-time code. Email links/passwords are not the v1 sign-in flow; Apple and Google sign-in are deferred. Code expiration and resend limits are implementation details to define later.
- 2026-11-04: Age and gender are optional, user-provided Soul details; users can skip or edit them. They do not gate sign-up and must not be used by AI to infer proficiency, interests, or life experiences.
- 2026-11-04: Native language is the only required field in initial Soul onboarding. Interests and learning preferences can be gathered later through use rather than required up front.
- 2026-11-04: Users may change native language at any time in settings; explanation language follows explicit user choice, not automatic inference from conversation.
- 2026-11-04: New-user registration and returning-user sign-in share one email/code flow. After code verification, the system creates a new account or restores the existing account based on the email.
- 2026-11-04: If the user exits before email verification, keep the initial Soul locally and temporarily so verification can resume on that device. Do not upload or bind it before verification succeeds.
- 2026-11-04: Interests and learning preferences are optional at onboarding and may be learned later from user-provided content; users must be able to view, edit, and remove them.
- 2026-11-04: Agreed on a generated `soul.md` representation for Agent context. Structured, source-linked Soul data remains canonical; the backend generates a bounded/versioned Markdown context for the Orchestrator and never treats model-generated text as an authoritative user fact.
- 2026-11-04: Confirmed MySQL as the canonical store for each account's structured Soul data. Profile fields and individually managed interests/preferences belong to the account and retain provenance; `soul.md` is generated for Agent context, not authoritative storage.
- 2026-11-04: Simplified remaining v1 identity/Soul decisions for implementation: pending Soul stays on the originating device until successful binding or explicit restart; email code is the only account recovery path; account deletion removes Soul and personal learning content; explicitly user-shared interests/preferences may be extracted automatically with provenance and user controls. Deferred expiry/rate-limit values, deletion timing, schema, and Markdown generation details to implementation design.
- 2026-11-04: User confirmed the analysis is ready for the PRD; status set to `ready-for-prd`. Remaining items (code expiry/rate limits, deletion timing, schema, `soul.md` generation/caching) carried into technical design.
- 2026-11-04: Published the formal PRD to GitHub Issues as ZhangPeibin/Named#1 with the agreed API-boundary test seam; open design questions remain for technical design.
