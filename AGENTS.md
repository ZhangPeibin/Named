## Agent skills

### Issue tracker

Issues and PRDs live in GitHub Issues and are operated with `gh` for `ZhangPeibin/Named`. See `docs/agents/issue-tracker.md`.

### Domain docs

Use a single-context layout with root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

### Feature docs

Pre-PRD discussions live at `docs/feature/<release>/<feature-slug>/discussion.md`. See `docs/agents/feature-docs.md`.

## Repository engineering

The project and repository name is **Named**. This directory currently contains product documentation, visual design assets, and a standalone HTML/CSS/JavaScript prototype. It does not contain a production client or service.

To review the prototype, open `docs/prototypes/named.html` directly in a browser. Keep the HTML, CSS, JavaScript files, and `assets/` directory together. No install or build step is required.

The prototype simulates AI responses, image recognition, speech, persistence, and experience extraction. Its data is temporary; only the appearance preference persists locally. Treat it as a design demo, not a production implementation or source of backend behavior.

Product scope is defined in `docs/prd-v1.0.md`. Visual and interaction direction is in `docs/ui-ux-design.md`; prototype behavior and limitations are in `docs/prototypes/named-guide.md`. No repository build, test, lint, or generation commands are defined.
