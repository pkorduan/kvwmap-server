#!/bin/bash

declare -a dump_tables
export dump_tables=( "kvwmapsp" "kvwmapsp_pet_dev" )


function dump_database(){

	#Rollen + Tablespace
	echo "Dump Rollen und Tablespace"
	pg_dumpall -U kvwmap -l kvwmapsp --globals-only -f roles_tablespaces.dump

	#alle Datenbanken mit Schemen und Daten
	while read DB
	do
		for element in "${dump_tables[@]}"; do
			if [[ $element == "$DB" ]]; then
				echo "Dump DB ${DB}"
				pg_dump -U kvwmap --create --exclude-table='shp_export_*' --format=custom -f schema_data.${DB}.dump "${DB}"
				break
			fi
		done
	done < <(psql -U kvwmap -d kvwmapsp -t -c "select distinct datname from pg_catalog.pg_database where datname not like 'template%';")
}

if [ $(basename $(pwd)) == "dumps" ]; then
	dump_database
else
	echo "Script wird nicht in /dumps ausgeführt, Abbruch!"
fi
