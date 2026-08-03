#!/usr/bin/env bash
#
# FloodFax AI — single-command launcher.
#
# Builds the frontend to static files and serves the WHOLE app (web UI + API +
# PDF reports) from ONE FastAPI process on ONE port. No separate Node server.
#
#   http://localhost:8000        the web app
#   http://localhost:8000/docs   the API docs
#
# First run sets everything up: Python venv + backend deps, node_modules, the
# frontend build, and a backend/.env from the template. Runs with zero API keys.
#
# Usage:  ./run.sh                 build (if needed) and serve
#         ./run.sh --rebuild       force a fresh frontend build first
#         PORT=9000 ./run.sh       serve on a different port
#
# Stop:   Ctrl-C

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/backend"
FRONTEND="$ROOT/frontend"
PORT="${PORT:-8000}"
REBUILD="${1:-}"

info() { printf "\033[1;36m>\033[0m %s\n" "$1"; }
ok()   { printf "\033[1;32m✓\033[0m %s\n" "$1"; }

command -v python3 >/dev/null || { echo "python3 (3.11+) is required"; exit 1; }
command -v node    >/dev/null || { echo "node (20+) is required"; exit 1; }

# --- Frontend: build to static files -----------------------------------------
cd "$FRONTEND"
if [ ! -d "node_modules" ]; then
  info "Installing frontend dependencies"
  npm install
fi
if [ "$REBUILD" = "--rebuild" ] || [ ! -f "out/index.html" ]; then
  info "Building the web app (static export)"
  npm run build
  ok "Web app built -> frontend/out"
else
  ok "Web app already built (use ./run.sh --rebuild to refresh)"
fi

# --- Backend: venv + deps + env ----------------------------------------------
cd "$BACKEND"
if [ ! -d ".venv" ]; then
  info "Creating Python virtualenv"
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
info "Installing backend dependencies"
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
[ -f ".env" ] || { cp .env.example .env && info "Wrote backend/.env from template"; }
ok "Backend ready"

# --- Serve everything from one process ---------------------------------------
ok "Starting FloodFax on http://localhost:$PORT  (API docs: /docs)"
echo "   Press Ctrl-C to stop."
exec .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
