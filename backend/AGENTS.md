# Backend Engineering

Run Python backend commands from `backend/`. Install dependencies with `uv sync --all-groups`. Use `make dev`, `make test`, `make lint`, and `make format-check` for development and checks. Start local MySQL with `docker compose up -d mysql`, copy `.env.example` to `.env`, and use `make migrate` to apply Alembic migrations. To run MySQL and the API together, use `docker compose up --build`; the API container applies migrations and serves on port 8000. Docker is required for local MySQL and the API container; tests and static checks do not require a database.

## Structure

- `src/` contains importable backend modules directly; do not add an enclosing application package layer.
- Keep application startup in `src/main.py`, environment settings in `src/config.py`, and SQLAlchemy engine/session setup in `src/database.py`.
- Add business modules under `src/` when their responsibilities and boundaries are defined. Avoid placeholder modules for undecided features.
- `migrations/` owns Alembic schema changes; do not create or modify schema outside migrations.
- `tests/` contains backend behavior tests.

`src/auth/` owns email-code authentication and opaque sessions; `src/soul/` owns Soul profile and items; `src/discovery/` owns AI-backed Discover and Word content; `src/talk/` owns conversations and message persistence; `src/tts/` owns speech synthesis and audio caching; `src/media.py` owns media storage; `src/images.py` owns image processing; `src/lifecycle.py` owns account-deletion purge; `src/ratelimit.py` owns request rate limits; `src/models.py` owns the shared SQLAlchemy metadata. Add future business modules under `src/` as their boundaries are defined. Keep Agent and provider-specific code behind adapters until a feature requires it.
