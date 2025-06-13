#!/bin/bash
#DBUSER=${1}
DUMPDIR=/dumps
LOGDIR="$DUMPDIR"/logs

if [ ! -d "$LOGDIR" ]; then
    cmd="mkdir -p $LOGDIR"
    echo $cmd; $cmd
fi

echo "Rollen + Tablespace einlesen"
psql -U postgres -f "$DUMPDIR"/roles_tablespaces.dump &> "$LOGDIR"/roles_tablespaces.stdout  2> "$LOGDIR"/roles_tablespaces.errout

echo "einzelne DB-Dumps einlesen"
while read -r DUMP_FILEPATH
do
    DUMP_FILE=$(basename "$DUMP_FILEPATH")
    echo "Importiere $DUMP_FILEPATH"
	pg_restore -U kvwmap -d postgres -CO "$DUMP_FILEPATH" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
done < <(find "$DUMPDIR" -type f -name "schema_data.*.dump")
