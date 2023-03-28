#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/pkorduan/kvwmap-server/develop/bin/init-kvwmap.sh)

if [ $(id -u) != "0" ]; then
    echo "Script muss als User uid=0(root) ausgeführt werden! Abbruch."
    exit 1
fi

# kvwmap-server repo anlegen

OS_USER=gisadmin
USER_DIR=/home/"$OS_USER"
cd "$USER_DIR"

if [ -d ./kvwmap-server ] ; then
    echo 'kvwmap-server existiert bereits. Abbruch.'
    exit 1
fi

sudo -u $OS_USER git clone https://github.com/pkorduan/kvwmap-server.git
chown -R gisadmin.gisadmin kvwmap-server/* kvwmap-server/.*
chmod -R g+w kvwmap-server/* kvwmap-server/.*
cd kvwmap-server
sudo -u "$OS_USER" git checkout develop

# services anlegen

export SUBNET_KVWMAP_PROD=10

dcm proxy create
dcm proxy up

read -p "Create Certificate for HTTPS? (j/n) " answer
case ${answer:0:1} in
    j|J|y|Y )
        read -p "Domain des Servers: " DOMAIN
        # Create SSL-Certificate for HTTPS Connections
        docker run -it --rm --name certbot -v "${USER_DIR}/networks/proxy/services/proxy/www/html:/var/www/html" -v "${USER_DIR}/networks/proxy/services/proxy/letsencrypt:/etc/letsencrypt" -v "${USER_DIR}/networks/proxy/services/proxy/log:/var/log/letsencrypt" certbot/certbot certonly -d ${DOMAIN} --webroot -w /var/www/html --email "peter.korduan@gdi-service.de"
        # Enable https
        sed -i -e "s|platzhalterkvwmapserverdomainname|${DOMAIN}|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default-ssl.conf
        sed -i -e "s|#add_header Strict-Transport-Security|add_header Strict-Transport-Security|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default.conf
        sed -i -e "s|#return 301 https|return 301 https|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default.conf
        cd ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-enabled
        ln -s ../sites-available/default-ssl.conf
        dcm proxy reload
        ;;
    * )
        echo "OK, Das Zertifikat kann später mit dem certbot Container erstellt werden."
       ;;
esac

dcm create service kvwmap-server kvwmap_prod
dcm up network kvwmap_prod

#mariadb user kvwmap
sleep 10
source "$USER_DIR"/networks/kvwmap_prod/env

#Create a mysql user for kvwmap
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_PASSWORD}');" mysql
# Grant permissions to kvwmap user
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" mysql
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%';" mysql
# Allow mysql access for user root only from network
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "RENAME USER 'root' TO 'root'@'172.0.${SUBNET_KVWMAP_PROD}.%';" mysql
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;" mysql
