#!/bin/bash
set -e

# Prüfe, ob die INITDB_PGCRON Variable gesetzt ist
if [ "${INITDB_PGCRON:-true}" = "true" ]; then
  echo "Aktiviere pg_cron-Erweiterung und plane regelmäßige Löschung alter Events..."

  # Führe SQL-Befehle aus
  psql -v ON_ERROR_STOP=1 <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    SELECT cron.schedule('30 3 * * 6', \$\$DELETE FROM events WHERE event_time < now() - interval '1 year'\$\$);
EOSQL

else
  echo "pg_cron-Initialisierung übersprungen (INITDB_PGCRON=$INITDB_PGCRON)"
fi
