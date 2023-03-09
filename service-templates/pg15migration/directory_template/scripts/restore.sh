#!/bin/bash
#DBUSER=${1}
DUMPDIR=/dumps
LOGDIR="$DUMPDIR"/logs

if [ ! -d "$LOGDIR" ]; then
    echo "erstelle $LOGDIR"
    mkdir -p "$LOGDIR"
fi

echo "Rollen + Tablespace einlesen"
psql -U postgres -f "$DUMPDIR"/schema_rollen.sql &> "$LOGDIR"/schema_rollen.stdout  2> "$LOGDIR"/schema_rollen.errout

echo "einzelne DB-Dumps einlesen"
while read -r DUMP_FILEPATH
do
    DUMP_FILE=$(basename "$DUMP_FILEPATH")
    echo "Importiere $DUMP_FILEPATH"
	pg_restore -U kvwmap -d postgres -CO "$DUMP_FILEPATH" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
done < <(find "$DUMPDIR" -type f -name "schema_data.*.dump")
