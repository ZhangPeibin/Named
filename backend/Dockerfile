ARG PYTHON_IMAGE=ghcr.io/astral-sh/uv:python3.12-bookworm-slim
FROM ${PYTHON_IMAGE}

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH="/app/src"

WORKDIR /app

ARG UV_INDEX_URL=https://pypi.org/simple
ENV UV_INDEX_URL=${UV_INDEX_URL}

COPY pyproject.toml uv.lock ./
ARG PYPI_FILES_MIRROR=
RUN if [ -n "$PYPI_FILES_MIRROR" ]; then \
        sed -i "s#https://files.pythonhosted.org/packages#${PYPI_FILES_MIRROR}#g" uv.lock; \
    fi \
    && uv sync --frozen --no-dev

COPY alembic.ini ./
COPY migrations ./migrations
COPY src ./src

RUN mkdir -p /app/media && chown -R 10001:10001 /app

USER 10001:10001

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=2)"

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--app-dir", "src"]
