# Feature Docs

Pre-PRD requirements discussions live at:

`docs/feature/<release>/<feature-slug>/discussion.md`

Formal PRDs and implementation tickets live in GitHub Issues, as described in `docs/agents/issue-tracker.md`.

## Consumer rules

- Create or resume the discussion document at the configured path.
- The user chooses the release; do not infer it from a package version.
- Derive `<feature-slug>` from the feature name as short kebab-case and state the resulting path before writing.
- Preserve prior decisions and session history when resuming a discussion.
- Record structured analysis and decisions, not a verbatim conversation transcript.
- Mark the discussion `ready-for-prd` only after the user explicitly confirms the handoff.
- Do not create a formal PRD in the feature workspace; publish it to the configured issue tracker.
