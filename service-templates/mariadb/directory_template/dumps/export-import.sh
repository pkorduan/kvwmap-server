#!/bin/bash

if [ -z "$MYSQL_PWD" ]; then
  echo "Fehler: Die Umgebungsvariable MYSQL_PWD ist nicht gesetzt." >&2
  exit 1
fi

if [ -z "$MARIADB_PWD" ]; then
  echo "Fehler: Die Umgebungsvariable MARIADB_PWD ist nicht gesetzt." >&2
  exit 1
fi

# Pfad zur Dump-Datei (ggf. anpassen)
DUMP_FILE=/home/gisadmin/networks/kvwmap_prod/services/mariadb/dumps/mysql-$(date +%F_%H-%M).dump

# mysql dumpen
docker exec -i kvwmap_prod_mysql bash -c "MYSQL_PWD=\"$MYSQL_PWD\" mysqldump -h mysql --single-transaction --user=kvwmap --databases kvwmapdb" > "$DUMP_FILE"

# importieren
# Dump in Container importieren
cat "$DUMP_FILE" | docker exec -i kvwmap_prod_mariadb bash -c "MYSQL_PWD=\"$MARIADB_PWD\" mariadb -u kvwmap"
