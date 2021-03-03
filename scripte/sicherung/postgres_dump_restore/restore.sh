#!/bin/bash
DUMP_DIR=/var/www/pg_dump

#1. Rollen + Tablespace einlesen
docker exec pgsql-server13 bash -c "psql -U postgres -f ${DUMP_DIR}/roles_tablespaces.dump"

#2. einzelne DB-Dumps einlesen
docker exec pgsql-server13 bash -c "find ${DUMP_DIR} -type f -name \"schema_data.*.dump\" | xargs pg_restore -U postgres --format=custom -d postgres "
