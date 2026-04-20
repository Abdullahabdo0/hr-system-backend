#!/usr/bin/env bash
set -euo pipefail

# Railway injects PORT at runtime; default is for local container runs.
PORT="${PORT:-8000}"
exec uvicorn main:app --host 0.0.0.0 --port "${PORT}"
