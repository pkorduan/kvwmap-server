#!/bin/bash

# Parameter für Ausführung
PGSQL_CONTAINER_NAME_OLD=
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
	CONTAINER_NAME_OLD=
	DUMP_DIR_HOST_OLD=${OLD_DIR_WWW}/pg_dump
	DUMP_DIR_HOST_NEW=${NEW_DIR_WWW}/pg_dump
	source dump.sh
	dump_database

	
	cp -r "$DUMP_DIR_HOST_OLD" "$DUMP_DIR_HOST_NEW"
}

$CONTAINER_VERSION=$2
$OLD_DIR_WWW=/home/gisadmin/www
$OLD_DIR_DATA=/home/gisadmin/db/postgresl/data
$NEW_DIR_WWW=/home/gisadmin/docker/var/www_${CONTAINER_VERSION}
$NEW_DIR_DATA=/home/gisadmin/db/postgres/data_${CONTAINER_VERSION}

case $1 in
	prepare_host)
		prepare_host
	;;
	start_new_container)
		start_new_container
	;;
	*)
		echo	"verfügbare Aufrufe:"
		echo	"prepare_host [container_version]"
		echo	"start_new_container [container_version]"
	;;
esac
