
#!/bin/bash

while read DB
do
	echo $DB
	psql $DB kvwmap -f oid_objects.sql > oids_in.$DB.txt
done < <(psql kvwmapsp kvwmap -tc "select distinct datname from pg_catalog.pg_database")

exit 0
