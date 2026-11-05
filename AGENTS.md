## Agent skills

### Issue tracker

Issues and PRDs live in GitHub Issues and are operated with `gh` for `ZhangPeibin/Named`. See `docs/agents/issue-tracker.md`.

### Domain docs

Use a single-context layout with root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

### Feature docs

Pre-PRD discussions live at `docs/feature/<release>/<feature-slug>/discussion.md`. See `docs/agents/feature-docs.md`.

### Worktrees

Implementation tasks use isolated worktrees under `.worktrees/<task-slug>`. See `docs/agents/worktrees.md`.

## Repository engineering

The project and repository name is **Named**. This repository contains product documentation, visual design assets, a standalone HTML/CSS/JavaScript prototype, a Python/FastAPI backend under `backend/`, and a Flutter app under `app/`.

To review the prototype, open `docs/prototypes/named.html` directly in a browser. Keep the HTML, CSS, JavaScript files, and `assets/` directory together. No install or build step is required.

The prototype simulates AI responses, image recognition, speech, persistence, and experience extraction. Its data is temporary; only the appearance preference persists locally. Treat it as a design demo, not a production implementation or source of backend behavior.

### Backend

Run backend commands from `backend/`.

- Install dependencies with `uv sync --all-groups`.
- Use `make dev`, `make test`, `make lint`, and `make format-check` for development and checks.
- Start local MySQL with `docker compose up -d mysql`; configure `.env` from `.env.example`; apply migrations with `make migrate`.
- Run MySQL and the API together with `make docker-up` or `docker compose up --build`; the API container applies migrations and serves on port 8000. Stop with `make docker-down`.
- Hard-delete accounts scheduled for deletion with `make purge`.
- Create schema changes with `make migration`; migrations live in `backend/migrations/` and schema changes must not be made outside Alembic.
- Docker is required for the local database and API container; tests and static checks do not require MySQL unless testing database readiness or migrations.

The backend uses a `src/` layout with top-level modules rather than an application package. `backend/src/main.py` owns the FastAPI application and health endpoints; `config.py` owns environment-backed settings; `database.py` owns the SQLAlchemy async engine and session factory; `models.py` owns shared SQLAlchemy metadata; `auth/` owns email-code authentication and sessions; `soul/` owns Soul profile and items; `discovery/` owns AI-backed Discover and Word content; `talk/` owns conversations and message persistence; `tts/` owns speech synthesis and audio caching; `media.py`, `images.py`, `lifecycle.py`, and `ratelimit.py` own their named cross-cutting concerns. Add future business modules directly under `backend/src/` as their boundaries are defined.

### Mobile app

The Flutter app under `app/` was scaffolded from `flutter-template`. Its own `app/AGENTS.md`, `app/docs/engineering-standards.md`, and `app/docs/agent/agent-playbook.md` are the source of truth for app architecture, feature scaffolding, routes, i18n, and tests. Use FVM with the pinned Flutter version in `app/.fvmrc`; run app commands from `app/`.

- Install/pin Flutter with `fvm install`; install dependencies with `fvm flutter pub get`; regenerate translations with `fvm dart run slang`.
- Run the full non-mutating gate with `make check` (format, generated code, architecture, doctor, analyze, test), with FVM's Flutter on `PATH`.
- Run the Android dev flavor with `make run-dev` on an emulator. The dev flavor reads `app/config/dev.json`.
- Scaffold a new feature with `make new-feature name=<feature>` or `dart run tool/new_feature.dart <feature>`.
- Do not edit generated `*.g.dart` files by hand. The architecture check enforces the feature layer boundaries.
- The Android emulator reaches the backend at `http://10.0.2.2:8000`; start the backend with `make docker-up` in `backend/` first.

Product scope is defined in `docs/prd-v1.0.md`. Visual and interaction direction is in `docs/ui-ux-design.md`; prototype behavior and limitations are in `docs/prototypes/named-guide.md`.
