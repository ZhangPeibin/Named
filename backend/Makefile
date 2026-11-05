.PHONY: install dev test lint format-check format migrate migration purge docker-up docker-down

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
