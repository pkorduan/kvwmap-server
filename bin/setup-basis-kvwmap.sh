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
export POSTGRES_PASSWORD=$(openssl rand -base64 24)
export PGADMIN_DEFAULT_PASSWORD=$(openssl rand -base64 24)
export PGADMIN_DEFAULT_EMAIL
export KVWMAP_PASSWORD=$(openssl rand -base64 24)

(
cat << EOF
<?php
define('WEB_BROWSER', 'Browser öffnen mit der Adresse: http://${DOMAIN}/install.php');
define('POSTGRES_PASSWORD', '${POSTGRES_PASSWORD}');
define('PGADMIN_PASSWORD', '${PGADMIN_DEFAULT_PASSWORD}');
define('KVWMAP_PASSWORD', '${KVWMAP_PASSWORD}');
?>
EOF
) > "$USER_DIR"/passwords.php

#############################
# kvwmap-Instanz einrichten und starten
#############################
dcm proxy create
dcm proxy up
dcm create service kvwmap-server kvwmap_prod
dcm up network kvwmap_prod

cd $USER_DIR/networks/kvwmap_prod/services/web
ln -s $USER_DIR/networks/kvwmap_prod/services/web/www/ $USER_DIR
chown -h gisadmin:gisadmin $USER_DIR/www

echo "
        Die Installation ist erfolgreich abgeschlossen.
Nächste Schritte zum installieren von kvwmap:"
echo "Browser öffnen mit der Adresse: http://${DOMAIN}/install.php"

cat << EOF
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

Alle Zugangsdaten finden Sie in $USER_DIR/passwords.php

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
EOF
