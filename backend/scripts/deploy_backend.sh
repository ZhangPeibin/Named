#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

HOST="${BACKEND_HOST:-root@101.201.198.87}"
REMOTE_DIR="${BACKEND_DIR:-/opt/named/backend}"
REMOTE_OWNER="${BACKEND_OWNER:-501:staff}"
DRY_RUN="${DRY_RUN:-0}"

RSYNC_ARGS=(-az --exclude "__pycache__" --exclude "*.pyc")

if [[ "$DRY_RUN" == "1" ]]; then
  echo "[dry-run] ssh $HOST test -d $REMOTE_DIR"
  echo "[dry-run] rsync src/ -> $HOST:$REMOTE_DIR/src/"
  echo "[dry-run] rsync migrations/ -> $HOST:$REMOTE_DIR/migrations/"
  echo "[dry-run] rsync alembic.ini pyproject.toml uv.lock -> $HOST:$REMOTE_DIR/"
  echo "[dry-run] ssh $HOST chown -R $REMOTE_OWNER $REMOTE_DIR/src $REMOTE_DIR/migrations"
  echo "[dry-run] ssh $HOST 'cd $REMOTE_DIR && docker compose -f compose.prod.yaml up -d --build api'"
  echo "[dry-run] ssh $HOST curl --retry 30 --retry-all-errors http://127.0.0.1:8000/health/live"
  exit 0
fi

echo "Deploying backend to $HOST:$REMOTE_DIR..."
ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" "test -d '$REMOTE_DIR'"

rsync "${RSYNC_ARGS[@]}" src "$HOST:$REMOTE_DIR/"
rsync "${RSYNC_ARGS[@]}" migrations "$HOST:$REMOTE_DIR/"
rsync -az alembic.ini pyproject.toml uv.lock "$HOST:$REMOTE_DIR/"

ssh -o BatchMode=yes "$HOST" \
  "chown -R '$REMOTE_OWNER' '$REMOTE_DIR/src' '$REMOTE_DIR/migrations' '$REMOTE_DIR/alembic.ini' '$REMOTE_DIR/pyproject.toml' '$REMOTE_DIR/uv.lock'"

ssh -o BatchMode=yes "$HOST" \
  "cd '$REMOTE_DIR' && docker compose -f compose.prod.yaml up -d --build api"

ssh -o BatchMode=yes "$HOST" \
  "curl -fsS --retry 30 --retry-delay 1 --retry-all-errors --max-time 3 http://127.0.0.1:8000/health/live >/dev/null"

echo "Backend deployed and healthy on $HOST."
