.PHONY: install dev test lint format-check format migrate migration purge docker-up docker-down deploy-backend

install:
	uv sync --all-groups

dev:
	uv run uvicorn main:app --reload --app-dir src

test:
	uv run pytest

lint:
	uv run ruff check .

format-check:
	uv run ruff format --check .

format:
	uv run ruff check --fix .
	uv run ruff format .

migrate:
	uv run alembic upgrade head

migration:
	uv run alembic revision --autogenerate -m "describe change"

purge:
	PYTHONPATH=src uv run python -m purge

docker-up:
	docker compose up --build

docker-down:
	docker compose down

# Sync backend source to the production host and rebuild the API container.
# Defaults: BACKEND_HOST=root@101.201.198.87 BACKEND_DIR=/opt/named/backend
deploy-backend:
	bash scripts/deploy_backend.sh
