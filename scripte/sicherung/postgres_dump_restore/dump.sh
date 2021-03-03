#!/bin/bash

# globaler Dump eines Postgres-Clusters
# Es wird ein Dump mit den Rollen und Tablespaces erstellt sowie ein Dump (Schema und Daten) für jede Datenbank
# User postgres benötigt lokal leserechte für alle Datenbanken

DUMP_DIR=/var/www/pg_dump

function dump_database(){
	option_f="${DUMP_DIR}/schema_data.${0}.dump"
	echo "Dump DB "${0}" nach ${option_f}"
	docker exec pgsql-server bash -c "pg_dump -U postgres --format=custom --exclude-table='shp_export_*' -f ${option_f}  \"$0\" "
}
export -f dump_database
export DUMP_DIR

#Rollen + Tablespace
echo "Dump Rollen und Tablespace nach ${DUMP_DIR}"
docker exec pgsql-server bash -c "pg_dumpall -U postgres --globals-only --clean -f ${DUMP_DIR}/roles_tablespaces.dump"

#alle Datenbanken mit Schemen und Daten
docker exec pgsql-server bash -c "psql -U postgres -t -c \"select distinct datname from pg_catalog.pg_database where datname not like 'template%';\"" | xargs -P 3 -L 1 bash -c 'dump_database "$@"'
