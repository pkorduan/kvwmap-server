#!/bin/bash

MYSQL_PWD=""
export MYSQL_PWD

echo "$(date '+%Y-%m-%d %H:%M:%S') - starte inplace dump+restore"
docker exec -i kvwmap_prod_mysql bash -c "MYSQL_PWD=\"$MYSQL_PWD\" mysqldump -h mysql --single-transaction --user=kvwmap --databases kvwmapdb" \
 | docker exec -i kvwmap_prod_mariadb bash -c "MYSQL_PWD=\"$MYSQL_PWD\" mariadb -u kvwmap"

#für ssh
#ssh -i /home/gisadmin/.ssh/id_ed25519 -p 50326 gisadmin@energieatlas-mv.de 'docker exec -i web bash -c \
#"MYSQL_PWD=\"\" mysqldump -h mysql --single-transaction --user=kvwmap --databases kvwmapdb smart_doerpdb"' \
#| docker exec -i kvwmap_prod_mariadb bash -c "MYSQL_PWD=\"$MYSQL_PWD\" mariadb -u kvwmap"

echo "$(date '+%Y-%m-%d %H:%M:%S') - fertig"
