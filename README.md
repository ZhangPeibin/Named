# Named

### AI that turns everyday moments into English conversations.

Explore what you see, talk about what matters to you, and build your own world of English memories.

**Discover → Talk → Understand → Save → Review → Reuse**

## Core experience

Named turns everyday moments into English conversations. A learner can start with a photo, a word, or something they want to say, then carry that discovery through four connected steps:

1. **Discover** — Start with a real object, place, or moment. AI helps identify what is in focus and introduces the relevant English.
2. **Understand** — Explore meaning, pronunciation, usage, and related expressions, with simple English and native-language support.
3. **Talk** — Have a natural AI conversation about the discovery and what matters to the learner. Get help expressing an idea without turning every exchange into a scripted lesson.
4. **Remember** — Keep the original conversation and connect words, scenes, expressions, and learner-shared experiences, so they can be revisited and continued later.

Over time, these connections are designed to build **your own world of English memories**: English grounded in the things you notice, the stories you share, and the conversations you return to.

## Explore the design

- [Open the interactive mobile prototype](docs/prototypes/named.html) directly in a browser. No installation or build step is required.
- [View the three-screen design board](final/00-overview.png) for Explore, Talk, and Word.
- [Browse the complete prototype guide](docs/prototypes/named-guide.md) for flows, screens, and demo limitations.

Keep the prototype's HTML, CSS, JavaScript files, and `assets/` directory together when viewing or sharing it.

## Product documents

- [PRD V1.0](docs/prd-v1.0.md): product definition, first-version scope, and acceptance criteria.
- [UI/UX direction](docs/ui-ux-design.md): mobile navigation, screen map, interaction direction, and visual system.
- [Competitive landscape](docs/competitive-landscape.md): researched product comparisons and differentiation hypotheses.
- [Visual design files](final/README.md): PNG previews and editable SVG artwork.
- [PRD V0.1](docs/prd-v0.1.md): historical early requirements, superseded by V1.0.

## Project status

This repository contains product documentation, visual design assets, a high-fidelity interactive design prototype, a Python/FastAPI backend under `backend/`, and a Flutter app scaffold under `app/`. The backend covers the P0 core loop; the Flutter app currently provides the template shell and is being adapted to Named. AI responses, image recognition, speech, persistence, and experience extraction in the prototype are simulated; prototype data is temporary apart from the locally saved appearance preference.

## Backend development

The backend lives in [`backend/`](backend/) and uses Python, FastAPI, SQLAlchemy async, Alembic, and MySQL. See [backend/README.md](backend/README.md) for setup, Docker, configuration, and the API overview.

Install [uv](https://docs.astral.sh/uv/) and Docker, then run from the backend directory:

```sh
cd backend
cp .env.example .env
uv sync --all-groups
docker compose up -d mysql
make migrate
make dev
```

The API is available at `http://127.0.0.1:8000`; interactive API docs are at `http://127.0.0.1:8000/docs`. Liveness is available at `/health/live`; readiness checks the database at `/health/ready`.

To run MySQL and the API together in Docker:

```sh
cd backend
cp .env.example .env
make docker-up
```

The API container applies Alembic migrations on startup and serves on port 8000.

Run backend checks from `backend/` with `make test`, `make lint`, and `make format-check`. Database migrations are managed with Alembic. The backend currently covers email-code authentication, Soul, Discover/Word, TTS audio, Talk conversation persistence, account deletion, and the P0 API hardening layer.

## Mobile app development

The Flutter app lives in [`app/`](app/) and was scaffolded from
[`ZhangPeibin/flutter-template`](https://github.com/ZhangPeibin/flutter-template).
It targets Android and iOS; Android is the current development target.

The template pins Flutter 3.41.9 in `app/.fvmrc`. Install
[FVM](https://fvm.app/), Android Studio, and JDK 17, then:

```sh
cd app
fvm install
fvm flutter pub get
fvm dart run slang
```

Run on an Android emulator:

```sh
export PATH="$PWD/.fvm/flutter_sdk/bin:$PATH"
make run-dev
```

The dev flavor reads `app/config/dev.json`. For the Android emulator, the
backend is reachable at `http://10.0.2.2:8000`; start the backend from
[`backend/`](backend/) first. On a physical device, use your machine's LAN
address instead.

The app currently contains the template shell and its Dev Sign In placeholder.
Named email-code authentication, Soul onboarding, Discover/Word, and Talk are
the next app milestones.

For app architecture, feature generation, and quality gates, read
[`app/AGENTS.md`](app/AGENTS.md), `app/docs/engineering-standards.md`, and
`app/docs/agent/agent-playbook.md`. Run `make check` from `app/` with FVM's
Flutter on `PATH`.
