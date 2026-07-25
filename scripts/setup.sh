#!/usr/bin/env bash
#
# One-command setup for the Cikgu database on macOS / Linux.
#
#   ./scripts/setup.sh            start the database and install the schema
#   ./scripts/setup.sh --skip-schema   start the database only
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

SKIP_SCHEMA=0
[[ "${1:-}" == "--skip-schema" ]] && SKIP_SCHEMA=1

step() { printf '\033[36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m    %s\033[0m\n' "$1"; }
fail() { printf '\033[31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

step 'Checking Docker'
command -v docker >/dev/null 2>&1 || fail 'Docker is not installed. Install Docker Desktop and re-run.'
docker info >/dev/null 2>&1 || fail "Docker is installed but not running. Start Docker Desktop and re-run."
ok 'Docker is running.'

step 'Checking .env'
if [[ ! -f .env ]]; then
  cp .env.example .env
  ok 'Created .env from .env.example.'
else
  ok '.env already exists.'
fi

# shellcheck disable=SC1091
set -a; source ./.env; set +a
ORACLE_PWD="${ORACLE_PWD:?ORACLE_PWD is not set in .env}"
CONTAINER_NAME="${ORACLE_CONTAINER_NAME:-cikgu-oracle}"
HOST_PORT="${ORACLE_HOST_PORT:-1521}"

owner="$(docker ps --filter "publish=${HOST_PORT}" --format '{{.Names}}' | head -1)"
if [[ -n "${owner}" && "${owner}" != "${CONTAINER_NAME}" ]]; then
  fail "Port ${HOST_PORT} is already used by container '${owner}'. Stop it (docker stop ${owner}) or set ORACLE_HOST_PORT in .env."
fi

step 'Starting Oracle 23ai Free (first run downloads ~2 GB, be patient)'
docker compose up -d

step 'Waiting for the database to become healthy (first start takes 3-10 minutes)'
deadline=$(( $(date +%s) + 900 ))
status=''
while (( $(date +%s) < deadline )); do
  status="$(docker inspect --format '{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo '')"
  [[ "${status}" == 'healthy' ]] && break
  [[ "${status}" == 'unhealthy' ]] && fail "Container reported unhealthy. Check: docker logs ${CONTAINER_NAME}"
  printf '\033[90m    still starting...\033[0m\n'
  sleep 15
done
[[ "${status}" == 'healthy' ]] || fail "Timed out waiting for the database. Check: docker logs ${CONTAINER_NAME}"
ok 'Database is healthy.'

if (( SKIP_SCHEMA )); then
  ok 'Skipping schema install (--skip-schema).'
else
  step 'Installing the CIKGU schema'
  # -L matters: without it sqlplus exits 0 even when the logon is refused,
  # which would let a failed install report success.
  docker compose exec -T oracle \
    sqlplus -S -L "system/${ORACLE_PWD}@//localhost:1521/FREEPDB1" @cikgu_install.sql \
    || fail "Schema install failed. If this says ORA-01017, the ORACLE_PWD in .env does not match the password the container was created with. Run 'docker compose down -v' to wipe it and start over."

  step 'Verifying the install'
  rows="$(docker compose exec -T oracle \
    sqlplus -S -L "cikgu/Cikgu_123@//localhost:1521/FREEPDB1" <<'SQL' | tr -d '[:space:]'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT count(*) FROM app_user;
EXIT
SQL
  )" || fail "Could not connect as the CIKGU user. The schema install did not complete."
  [[ "${rows}" =~ ^[0-9]+$ && "${rows}" -gt 0 ]] \
    || fail "CIKGU schema is present but empty (app_user returned '${rows}'). Re-run this script."
  ok "CIKGU schema installed and populated (${rows} users seeded)."
fi

cat <<EOF

Database is ready. Next, run the web app:

    cd src/cikgu-app-django
    python3 -m venv .venv && source .venv/bin/activate
    pip install -r requirements.txt
    python manage.py runserver

Then open http://localhost:8000 and log in as halim.abdullah@cikgu.my / password123
EOF
