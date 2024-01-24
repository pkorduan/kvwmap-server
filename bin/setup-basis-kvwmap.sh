#!/bin/bash

set -e

while getopts c: flag
do
    case "${flag}" in
        c) configfile=${OPTARG};;
    esac
done

if [ -f "$configfile" ] && [ -v configfile ]; then
    source "$configfile"
fi

########################
# Variables + Passwords
########################
USER_DIR=/home/${OS_USER}
CURRENT_DIR=$(pwd)

# Vars aus dem configfile
export SUBNET_KVWMAP_PROD
export DOMAIN
export OS_USER

# weitere
export MYSQL_ROOT_PASSWORD=$(openssl rand -base64 24)
export MYSQL_USER="kvwmap"
export MYSQL_PASSWORD=$(openssl rand -base64 24)
export POSTGRES_PASSWORD=$(openssl rand -base64 24)
export PGADMIN_DEFAULT_PASSWORD=$(openssl rand -base64 24)
export PGADMIN_DEFAULT_EMAIL
export KVWMAP_PASSWORD=$(openssl rand -base64 24)

#############################
# kvwmap-Instanz einrichten und starten
#############################
dcm proxy create
dcm proxy up
dcm create service kvwmap-server kvwmap_prod
dcm up network kvwmap_prod

testCertArg=""
if [ "$TEST_CERT" = "j" ]; then
    testCertArg="--test-cert"
fi
# Create SSL-Certificate for HTTPS Connections
docker run --rm --name certbot \
    -v "${USER_DIR}/networks/proxy/services/proxy/www/html:/var/www/html" \
    -v "${USER_DIR}/networks/proxy/services/proxy/letsencrypt:/etc/letsencrypt" \
    -v "${USER_DIR}/networks/proxy/services/proxy/log:/var/log/letsencrypt" certbot/certbot certonly \
    -d ${DOMAIN} \
    --webroot -w /var/www/html --email "peter.korduan@gdi-service.de" --non-interactive --agree-tos ${testCertArg}
# Enable https
sed -i -e "s|#add_header Strict-Transport-Security|add_header Strict-Transport-Security|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/server-available/${DOMAIN}/default.conf
sed -i -e "s|#return 301 https|return 301 https|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/server-available/${DOMAIN}/default.conf
ln -rs ${USER_DIR}/networks/proxy/services/proxy/nginx/server-available/${DOMAIN}/default-ssl.conf ${USER_DIR}/networks/proxy/services/proxy/nginx/server-enabled/${DOMAIN}/default-ssl.conf
chown -R ${OS_USER}:${OS_USER} ${USER_DIR}/networks/proxy/services/proxy/letsencrypt
dcm proxy reload

cd $USER_DIR/networks/kvwmap_prod/services/web
ln -s $USER_DIR/networks/kvwmap_prod/services/web/www/ $USER_DIR
chown -h gisadmin:gisadmin $USER_DIR/www


#############################
# mariadb einrichten
#############################
# Create a mysql user for kvwmap
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'KVWMAP_PROD_%' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_PASSWORD}');" mysql
# Grant permissions to kvwmap user
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'KVWMAP_PROD_%' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" mysql
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'KVWMAP_PROD_%';" mysql
# Allow mysql access for user root only from network
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "RENAME USER 'root' TO 'root'@'KVWMAP_PROD_%';" mysql
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;" mysql

echo "
        Die Installation ist erfolgreich abgeschlossen.
Nächste Schritte zum installieren von kvwmap:"
echo "Browser öffnen mit der Adresse: http://${DOMAIN}/install.php"

cat << EOF
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

Alle Zugangsdaten finden Sie in $USER_DIR/passwords.php

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
EOF

(
cat << EOF
<?
define('MYSQL_ROOT_PASSWORD', '${MYSQL_ROOT_PASSWORD}');
define('MYSQL_PASSWORD', '${MYSQL_PASSWORD}');
define('POSTGRES_PASSWORD', '${POSTGRES_PASSWORD}');
define('PGADMIN_PASSWORD', '${PGADMIN_DEFAULT_PASSWORD}');
define('KVWMAP_PASSWORD', '${KVWMAP_PASSWORD=}');
?>
EOF
) > "$USER_DIR"/passwords.php
