#!/bin/bash
set -e

if [ "${INITDB_PGBACKREST:-true}" = "true" ]; then
    echo "Einrichten und Testen von pgbackrest..."
    pgbackrest --stanza=local --log-level-console=info stanza-create
    pgbackrest --stanza=local --log-level-console=info check
else
    echo "pgBackrest-Einrichtung übersprungen (INITDB_PGBACKREST=$INITDB_PGBACKREST)"
fi
