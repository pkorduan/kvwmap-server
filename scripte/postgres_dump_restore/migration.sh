#!/bin/bash

# Parameter für Ausführung
PGSQL_MAJOR_VERSION=
POSTGIS_VERSION=
PGSQL_IMAGE_VERSION="${PGSQL_MAJOR_VERSION}-${POSTGIS_VERSION}"


function prepare_host(){

	if [ ! -f /home/gisadmin/etc/postgresql/env_and_volumes_${CONTAINER_VERSION} ]; then
		echo "FEHLER: Datei /home/gisadmin/etc/postgresql/env_and_volumes_${CONTAINER_VERSION} nicht vorhanden. Abbruch."
		exit 1
	fi

	# Verzeichnisse vorhanden ?
	# neues www anlegen
	if [ -d $NEW_DIR_WWW/pg_dump ]; then
		echo "HINWEIS: ${NEW_DIR_WWW} existiert bereits"
	else
		mkdir -p ${NEW_DIR_WWW}/pg_dump
	fi

	#create new data
	if [ -d ${NEW_DIR_DATA} ]; then
		echo "HINWEIS: ${NEW_DIR_DATA} existiert bereits"
	else
		mkdir -p ${NEW_DIR_DATA}
	fi
}

function start_new_container(){
	dcm run pgsql ${container_version}
}

function dump_old_db_copy_dump(){
	DUMP_DIR=${DUMP_DIR_CONTAINER}

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

	cp -r "$DUMP_DIR_HOST_OLD"/* "$DUMP_DIR_HOST_NEW"/
}

function restore_dump(){
	DUMP_DIR_HOST_NEW
	DUMP_DIR=/var/www/pg_dump

	#1. Rollen + Tablespace einlesen
	docker exec pgsql-server13 bash -c "psql -U postgres -f ${DUMP_DIR}/roles_tablespaces.dump 1>> "$DUMP_DIR"/restore.log  2>> "$DUMP_DIR"/restore_error.log" 

	#2. einzelne DB-Dumps einlesen
	docker exec pgsql-server13 bash -c "find ${DUMP_DIR} -type f -name \"schema_data.*.dump\" | xargs -I {} psql -U postgres -f {} 1>> "$DUMP_DIR"/restore.log  2>> "$DUMP_DIR"/restore_error.log"
}

CONTAINER_VERSION=$2

OLD_DIR_WWW=/home/gisadmin/www
NEW_DIR_WWW=${OLD_DIR_WWW}_${CONTAINER_VERSION}

OLD_DIR_DATA=/home/gisadmin/db/postgresl/data
NEW_DIR_DATA=/home/gisadmin/db/postgres_${CONTAINER_VERSION}/data
DUMP_DIR_HOST_OLD=${OLD_DIR_WWW}/pg_dump
DUMP_DIR_HOST_NEW=${NEW_DIR_WWW}/pg_dump
DUMP_DIR_CONTAINER=/var/www/pg_dump

case $1 in
	prepare_host)
		prepare_host
	;;
	dump_db)
		dump_old_db_copy_dump
	;;
	start_new_db)
		start_new_container
	;;
	*)
		echo	"verfügbare Aufrufe:"
		echo	"prepare_host [container_version]"
		echo	"dump_old_db_copy_dump [container_version]"
		echo	"start_new_db [container_version]"
	;;
esac
