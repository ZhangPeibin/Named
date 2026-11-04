## Agent skills

### Issue tracker

Issues and PRDs live in GitHub Issues and are operated with `gh` for `ZhangPeibin/Named`. See `docs/agents/issue-tracker.md`.

### Domain docs

Use a single-context layout with root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

### Feature docs

Pre-PRD discussions live at `docs/feature/<release>/<feature-slug>/discussion.md`. See `docs/agents/feature-docs.md`.

## Repository engineering

The project and repository name is **Named**. This repository contains product documentation, visual design assets, a standalone HTML/CSS/JavaScript prototype, and a Python/FastAPI backend scaffold under `src/named_api/`.

To review the prototype, open `docs/prototypes/named.html` directly in a browser. Keep the HTML, CSS, JavaScript files, and `assets/` directory together. No install or build step is required.

The prototype simulates AI responses, image recognition, speech, persistence, and experience extraction. Its data is temporary; only the appearance preference persists locally. Treat it as a design demo, not a production implementation or source of backend behavior.

Run backend commands from the repository root. Use `uv sync --all-groups` to install dependencies; `make dev`, `make test`, `make lint`, and `make format-check` for local development and checks. Start the local MySQL service with `docker compose up -d mysql`, configure `.env` from `.env.example`, and run `make migrate` to apply Alembic migrations. Docker is required for the local database; application checks do not require MySQL unless testing database readiness or migrations.

`src/named_api/main.py` owns the FastAPI application and health endpoints. `config.py` owns environment-backed settings; `database.py` owns the SQLAlchemy async engine and session factory. `migrations/` owns schema migrations. Keep future business modules under `src/named_api/`; no production domain or Agent modules are defined yet.

Product scope is defined in `docs/prd-v1.0.md`. Visual and interaction direction is in `docs/ui-ux-design.md`; prototype behavior and limitations are in `docs/prototypes/named-guide.md`.
