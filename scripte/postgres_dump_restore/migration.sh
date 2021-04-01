#!/bin/bash

# Parameter für Migration
PGSQL_MAJOR_VERSION=13.1
POSTGIS_VERSION=3.1
PGSQL_IMAGE_VERSION="${PGSQL_MAJOR_VERSION}-${POSTGIS_VERSION}"
KVWMAP_SERVER_CONFIG=/home/gisadmin/kvwmap-server/config/config

#Parameter für Integration

if [[ -z $PGSQL_MAJOR_VERSION ]] || [[ -z $POSTGIS_VERSION ]]; then
	echo "FEHLER: Version nicht angegeben!"
	exit 1
fi

function init_paths_vars(){

	if [ ! -f $KVWMAP_SERVER_CONFIG ] ; then
		echo "FEHLER: kvwmap-server Config-File $KVWMAP_SERVER_CONFIG nicht vorhanden!"
		exit 1
	else
		source $KVWMAP_SERVER_CONFIG
	fi

	OLD_DIR_WWW=${WWW_ROOT}
	NEW_DIR_WWW=${WWW_ROOT}_${PGSQL_MAJOR_VERSION}
	OLD_DIR_DATA=${DB_ROOT}/postgresql/data
	NEW_DIR_DATA=${DB_ROOT}/postgresql_${PGSQL_MAJOR_VERSION}/data
	DUMP_DIR_HOST_OLD=${OLD_DIR_WWW}/pg_dump
	DUMP_DIR_HOST_NEW=${NEW_DIR_WWW}/pg_dump
	DUMP_DIR_CONTAINER=/var/www/pg_dump

}

function echo_path_vars(){
	echo "=== nutze folgende Pfade ==="
	echo "OLD_DIR_WWW=$OLD_DIR_WWW"
	echo "NEW_DIR_WWW=$NEW_DIR_WWW"
	echo "OLD_DIR_DATA=$OLD_DIR_DATA"
	echo "NEW_DIR_DATA=$NEW_DIR_DATA"
	echo "DUMP_DIR_HOST_OLD=$DUMP_DIR_HOST_OLD"
	echo "DUMP_DIR_HOST_NEW=$DUMP_DIR_HOST_NEW"
	echo "DUMP_DIR_CONTAINER=$DUMP_DIR_CONTAINER"
	echo "=== ==================== ==="
}

function prepare_host(){

	if [ ! -f /home/gisadmin/etc/postgresql/env_and_volumes_${PGSQL_MAJOR_VERSION} ]; then
		echo "FEHLER: Datei /home/gisadmin/etc/postgresql/env_and_volumes_${PGSQL_MAJOR_VERSION} nicht vorhanden. Abbruch."
		exit 1
	fi

	#alte WWW, DATA, DUMP-Verzeichnisse
	if [ ! -d $OLD_DIR_WWW ]; then
		echo "Verzeichnis $OLD_DIR_WWW existiert nicht!"
		exit 1
	fi

	if [ ! -d $OLD_DIR_DATA ]; then
		echo "Verzeichnis $OLD_DIR_DATA existiert nicht!"
		exit 1
	fi

	if [ ! -d $DUMP_DIR_HOST_OLD ]; then
		echo "Verzeichnis anlegen: $DUMP_DIR_HOST_OLD"
		mkdir $DUMP_DIR_HOST_OLD
	fi


	 # neue WWW, DATA, DUMP-Verzeichnisse
	if [ -d $NEW_DIR_WWW ]; then
		echo "HINWEIS: ${NEW_DIR_WWW} existiert bereits"
	else
		mkdir -p ${NEW_DIR_WWW}/logs/pgsql

		echo "Verzeichnis anlegen: $NEW_DIR_WWW"
		echo "Setze Rechte auf $NEW_DIR_WWW"
		chown 999.gisadmin $NEW_DIR_WWW/logs/pgsql
		chmod 774 $NEW_DIR_WWW/logs/pgsql
	fi

	#create new data
	if [ -d ${NEW_DIR_DATA} ]; then
		echo "HINWEIS: ${NEW_DIR_DATA} existiert bereits"
	else
		echo "Verzeichnis anlegen: $NEW_DIR_DATA"
		echo "Verzeichnis anlegen: $DUMP_DIR_HOST_NEW"
		mkdir -p $NEW_DIR_DATA
		chown gisadmin.gisadmin $NEW_DIR_DATA
		mkdir -p $DUMP_DIR_HOST_NEW
		chown gisadmin.gisadmin $DUMP_DIR_HOST_NEW
	fi
}

function start_new_container(){
	dcm run pgsql ${PGSQL_MAJOR_VERSION}
}

function dump_old_db_copy_dump(){
	DUMP_DIR=${DUMP_DIR_CONTAINER}

	docker exec pgsql-server bash -c "mkdir -p \"$DUMP_DIR\""

	#Rollen + Tablespace
	echo "Dump Rollen und Tablespace nach ${DUMP_DIR}"
	docker exec pgsql-server bash -c "pg_dumpall -U postgres --globals-only -f ${DUMP_DIR}/roles_tablespaces.dump"

	i=0

	#alle Datenbanken mit Schemen und Daten
	while read DB
	do
		if [ $i -lt 3 ]; then
			OPTION_F="${DUMP_DIR}/schema_data.${DB}.dump"
			echo "Dump DB ${DB} nach ${OPTION_F}"
			docker exec pgsql-server bash -c "pg_dump -U postgres --create --exclude-table='shp_export_*' -f ${OPTION_F} \"${DB}\" "
			docker exec pgsql-server bash -c "sed -i -e 's/\(SET default_with_oids = true;\|SET default_with_oids = false;\)//' \"$OPTION_F\" "

			i=$((i+1))
		fi
	done < <(docker exec pgsql-server bash -c "psql -U postgres -t -c \"select distinct datname from pg_catalog.pg_database where datname not like 'template%';\"")

	cp -r "$DUMP_DIR_HOST_OLD"/* "$DUMP_DIR_HOST_NEW"/
	#docker cp  "$DUMP_DIR_HOST_OLD"/* "$DUMP_DIR_CONTAINER"/
	
	echo "Inhalt von $DUMP_DIR_HOST_NEW"
	ls -alh $DUMP_DIR_HOST_NEW
}

function restore_dump(){
	DUMP_DIR=/var/www/pg_dump

	#1. Rollen + Tablespace einlesen
	docker exec pgsql-server13 bash -c "psql -U postgres -f ${DUMP_DIR}/roles_tablespaces.dump 1>> "$DUMP_DIR"/restore.log  2>> "$DUMP_DIR"/restore_error.log" 

	#2. einzelne DB-Dumps einlesen
	docker exec pgsql-server13 bash -c "find ${DUMP_DIR} -type f -name \"schema_data.*.dump\" | xargs -I {} psql -U postgres -f {} 1>> "$DUMP_DIR"/restore.log  2>> "$DUMP_DIR"/restore_error.log"
}

function connect_all_containers_to_KVWMAP_PROD(){
	
}

init_paths_vars

case $1 in
	paths)
		echo_path_vars
	;;
	mkdirs)
		prepare_host
	;;
	dump)
		dump_old_db_copy_dump
	;;
	start-new-db)
		start_new_container
	;;
	restore)
		restore_dump
	;;
	*)
		echo	"verfügbare Aufrufe:"
		echo	"paths"
		echo	"mkdirs"
		echo	"dump"
		echo	"start-new-db"
	;;
esac
