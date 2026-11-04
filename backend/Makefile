.PHONY: install dev test lint format-check format migrate migration

install:
	uv sync --all-groups

dev:
	uv run uvicorn named_api.main:app --reload

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
