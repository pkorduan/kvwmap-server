#!/bin/bash

PGMSERVICE="pgsql15"
PGMNETWORK="kvwmap_prod"

CONTAINER="$PGMNETWORK"_"$PGMSERVICE"

if [ $(basename $(pwd)) != "$PGMSERVICE" ]; then
    echo "Script wird in nicht im Ordner des Service ($PGMSERVICE) aufgerufen. Abbruch."
    exit 1
fi

if [ ! -f ./config/.pgpass ]; then
    echo ".pgpass nicht im Ordner ./config gefunden. Abbruch."
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

echo "Cluster wird initialisiert"
dcm up "$PGMSERVICE" "$PGMNETWORK"
echo "warte 30s bis das Cluster initialisiert ist..."
sleep 30
dcm down "$PGMSERVICE" "$PGMNETWORK"

echo "ersetze Config durch Restore-Config"
mv ./config/conf.d ./config/conf.d.prod
mv ./config/conf.d.restore ./config/conf.d

dcm up "$PGMSERVICE" "$PGMNETWORK"
sleep 5

docker exec -it "$CONTAINER" bash -c /scripts/restore.sh

echo "ersetze Restore-Config durch Produktions-Config"
dcm down "$PGMSERVICE" "$PGMNETWORK"
mv ./config/conf.d ./config/conf.d.restore
mv ./config/conf.d.prod ./config/conf.d
dcm up "$PGMSERVICE" "$PGMNETWORK"
