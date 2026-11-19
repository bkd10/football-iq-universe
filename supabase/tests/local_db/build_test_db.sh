#!/bin/bash
# Construit une base de TEST locale (jamais la production) : PostgreSQL 16
# + une imitation minimale de Supabase (rôles, auth.users, storage, pg_cron
# factice), puis applique toutes les migrations dans l'ordre.
#
#   sudo bash supabase/tests/local_db/build_test_db.sh
#   python3 supabase/tests/minor_safety_checks.py
#
# Utile quand `supabase start` (Docker) n'est pas disponible.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
DB="${DB:-fiq_test}"
PGVER="${PGVER:-16}"
EXT_DIR="/usr/share/postgresql/$PGVER/extension"

if [ ! -f "$EXT_DIR/pg_cron.control" ]; then
  cp "$HERE/fake_pg_cron/pg_cron.control" "$HERE/fake_pg_cron/pg_cron--1.0.sql" "$EXT_DIR/"
fi

su postgres -c "dropdb --if-exists $DB && createdb $DB"
su postgres -c "psql -q -v ON_ERROR_STOP=1 -d $DB -f '$HERE/supabase_shim.sql'" >/dev/null 2>&1
for f in "$ROOT"/supabase/migrations/*.sql; do
  su postgres -c "psql -q -v ON_ERROR_STOP=1 -d $DB -f '$f'" >/tmp/fiq_last_migration.log 2>&1 \
    || { echo "ÉCHEC : $f"; tail -20 /tmp/fiq_last_migration.log; exit 1; }
done
echo "OK : toutes les migrations appliquées sur la base de test $DB"
