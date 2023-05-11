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
    DB_NAME=$(echo "$DUMP_FILE"|cut -f2 -d.)
    echo "Importiere $DB_NAME"
    psql postgres gisadmin -c "CREATE DATABASE $DB_NAME;" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    psql "$DB_NAME" gisadmin -c "CREATE EXTENSION postgis;" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    psql "$DB_NAME" gisadmin -c "CREATE EXTENSION postgis_raster;" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    psql "$DB_NAME" gisadmin -c "CREATE EXTENSION postgis_sfcgal;" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    psql "$DB_NAME" gisadmin -c "CREATE EXTENSION fuzzystrmatch; CREATE EXTENSION postgis_tiger_geocoder;" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    psql "$DB_NAME" gisadmin -c "CREATE EXTENSION address_standardizer; CREATE EXTENSION address_standardizer_data_us;" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    psql "$DB_NAME" gisadmin -c "CREATE EXTENSION postgis_topology;" &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    psql "$DB_NAME" gisadmin < /usr/share/postgresql/15/contrib/postgis-3.3/legacy.sql &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
    perl /usr/share/postgresql/15/contrib/postgis-3.3/postgis_restore.pl "$DUMP_FILEPATH" 2> "$LOGDIR"/"$DUMP_FILE".errout | psql "$DB_NAME" kvwmap &> "$LOGDIR"/"$DUMP_FILE".stdout 2> "$LOGDIR"/"$DUMP_FILE".errout
done < <(find "$DUMPDIR" -type f -name "schema_data.*.dump")
