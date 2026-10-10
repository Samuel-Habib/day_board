#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"

exec "$DIR/.venv/bin/uvicorn" app.main:app --host "$HOST" --port "$PORT"
