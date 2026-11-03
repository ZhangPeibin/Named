# Issue tracker: GitHub

Issues and formal PRDs for this repository live in GitHub Issues. Use the `gh` CLI for issue operations.

## Repository context

The GitHub repository is `ZhangPeibin/Named`. The local `main` branch tracks `origin/main`; `gh` can infer the repository from this checkout.

## Conventions

- Create an issue with `gh issue create --title "..." --body "..."`.
- Read an issue with `gh issue view <number> --comments`.
- List open issues with `gh issue list --state open` and apply appropriate filters as needed.
- Comment with `gh issue comment <number> --body "..."`.
- Add or remove labels with `gh issue edit <number> --add-label "..."` or `--remove-label "..."`.
- Close with `gh issue close <number> --comment "..."`.

Publishing a formal PRD or implementation ticket means creating a GitHub issue. Pre-PRD requirements discussions are stored separately as described in `docs/agents/feature-docs.md`.

## Pull requests as a triage surface

**PRs as a request surface: no.** Pull requests are not included in issue triage by default.
