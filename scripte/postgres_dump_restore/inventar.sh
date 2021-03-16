#!/bin/bash

case "$1" in
	list_objects)
		psql -U postgres -t -c "select distinct datname from pg_catalog.pg_database where datname not like 'template%';" | xargs -I {} $0 list_objects_by_schema {}
		;;
	list_objects_by_schema)
		psql -U postgres -f schema_objects.sql > "schema_objects_$1.txt"
		;;
esac

exit 0
