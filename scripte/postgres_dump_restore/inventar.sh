#!/bin/bash

case "$1" in
	list_objects)
		echo "Schemen ermitteln"
		psql -U postgres -t -c "select distinct datname from pg_catalog.pg_database where datname not like 'template%';" | xargs -I {} $0 list_objects_by_schema {}
		;;
	list_objects_by_schema)
		echo "Objekte in Schema $2 auflisten"
		psql -U postgres -d "$2" -f schema_objects.sql -o "schema_objects.$2.txt"
		;;
	*)
		echo	"Tool for dumping a list of user-defined tables, views, procedures
			./inventar.sh list_objects"
		;;
esac

exit 0
