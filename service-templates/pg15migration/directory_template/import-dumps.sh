#!/bin/bash

PGMSERVICE="pg15migration"
PGMNETWORK="pgmigration"

CONTAINER="$PGMNETWORK"_"$PGMSERVICE"

if [ $(basename $(pwd)) != "$PGMSERVICE" ]; then
    echo "Script wird in nicht im Ordner des Service ($PGMSERVICE) aufgerufen. Abbruch."
    exit 1
fi

echo "Script stopp Container $CONTAINER, leert ./data, startet Container und importiert Dumps"
read -p "Forfahren? [j/n]: " yesno
if [ "$yesno" != "j" ]; then
    echo "Abbruch."
    exit 1
fi

dcm down "$PGMSERVICE" "$PGMNETWORK"
rm -rf ./data/*
dcm up "$PGMSERVICE" "$PGMNETWORK"

while ! docker exec "$CONTAINER" test -S /var/run/postgresql/.s.PGSQL.5432;
do
    echo "warte 15s auf Starten des Servers..."
    sleep 15
done
docker exec "$CONTAINER" bash -c /scripts/restore.sh
