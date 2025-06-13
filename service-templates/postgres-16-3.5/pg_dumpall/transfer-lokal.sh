#!/bin/bash

set -euo pipefail

CONTAINER_ALT="kvwmap_prod_pgsql"
CONTAINER_NEU="kvwmap_prod_pgsql16"
STAGE=${1:-all}  # standardmäßig 'all', falls kein Parameter übergeben

# Zielordner für Logs pro Stage
LOG_DIR="./${STAGE}"
mkdir -p "$LOG_DIR"

# Dateien leeren
rm -f "$LOG_DIR"/dump_stderr.log "$LOG_DIR"/restore_stdout.log "$LOG_DIR"/restore_stderr.log

# Auswahl pg_dumpall-Flags je nach Stage
case "$STAGE" in
  roles)
    DUMP_FLAGS="--roles-only"
    ;;
  schema)
    DUMP_FLAGS="--schema-only"
    ;;
  data)
    DUMP_FLAGS="--data-only --disable-triggers"
    ;;
  all)
    DUMP_FLAGS=""
    ;;
  *)
    echo "Ungültiger Stage: $STAGE. Erlaubt: roles, schema, data, all"
    exit 1
    ;;
esac

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starte Migration: $STAGE"

# Dump & Restore mit Log-Redirection
docker exec "$CONTAINER_ALT" pg_dumpall $DUMP_FLAGS -d postgresql://postgres@localhost 2>"$LOG_DIR/dump_stderr.log" | \
docker exec -i "$CONTAINER_NEU" psql postgres postgres >"$LOG_DIR/restore_stdout.log" 2>"$LOG_DIR/restore_stderr.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Fertig."
