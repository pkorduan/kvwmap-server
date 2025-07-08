#!/bin/bash

if [ "${INITDB_PGTRACKSETTINGS:-true}" = "true" ]; then
  echo "pg_tracksettings Extension installieren und in pg_cron einrichten..."
  psql -v ON_ERROR_STOP=1 <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_track_settings;
    SELECT cron.schedule('0 0 * * 6', 'select pg_track_settings_snapshot()');
EOSQL
else
  echo "pg_tracksettings Einrichtung wird übersprungen (INITDB_PGTRACKSETTINGS=$INITDB_PGTRACKSETTINGS)"
fi
