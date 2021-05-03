#!/bin/bash

# globaler Dump eines Postgres-Clusters
# Es wird ein Dump mit den Rollen und Tablespaces erstellt sowie ein Dump (Schema und Daten) für jede Datenbank
# User postgres benötigt lokal leserechte für alle Datenbanken
# wird auf dem Host ausgeführt

DUMP_DIR=/var/www/pg_dump

function dump_database(){

	docker exec pgsql-server bash -c "mkdir -p \"$DUMP_DIR\""

	#Rollen + Tablespace
	echo "Dump Rollen und Tablespace nach ${DUMP_DIR}"
	docker exec pgsql-server bash -c "pg_dumpall -U postgres --globals-only -f ${DUMP_DIR}/roles_tablespaces.dump"

	#alle Datenbanken mit Schemen und Daten
	while read DB
	do
		OPTION_F="${DUMP_DIR}/schema_data.${DB}.dump"
		echo "Dump DB ${DB} nach ${OPTION_F}"
		docker exec pgsql-server bash -c "pg_dump -U postgres --create --exclude-table='shp_export_*' -f ${OPTION_F} \"${DB}\" "
		docker exec pgsql-server bash -c "sed -i -e 's/\(SET default_with_oids = true;\|SET default_with_oids = false;\)//' \"$OPTION_F\" "
	done < <(docker exec pgsql-server bash -c "psql -U postgres -t -c \"select distinct datname from pg_catalog.pg_database where datname not like 'template%';\"")

}
