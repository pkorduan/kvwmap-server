#!/bin/bash

# installiert den proxy nach /home/gisadmin/networks/proxy/services/proxy


if [ $(whoami) != "root" ]; then
    echo "Das Script muss als User root ausgeführt werden! Abbruch."
    exit
fi

NETWORK_PATH=/home/gisadmin/networks/proxy
SERVICE_PATH=$NETWORK_PATH/services/proxy

# Verzeichnisse anlegen
mkdir -p $SERVICE_PATH
cp -pvr ./directory_template/* $SERVICE_PATH
chown -R gisadmin.gisadmin $NETWORK_PATH
chown -R www-data.gisadmin $SERVICE_PATH
chmod -R g+w $SERVICE_PATH

#Netzwerk anlegen
read -p "Gib ein Subnetz für das Proxynetzwerk an, z.B. 172.0.10.0/24: " SUBNET
docker network create --subnet $SUBNET proxy

echo "NETWORK_SUBNET=${SUBNET}" >> $NETWORK_PATH/env
