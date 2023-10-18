#!/bin/bash

www=/var/www/html
letsencrypt=/etc/letsencrypt
log=/var/log/letsencrypt
network=/home/gisadmin/networks/proxy/services/proxy
email=peter.korduan@gdi-service.de

docker run -it --rm --name certbot \
           -v "$network/www/html:$www" \
           -v "$network/letsencrypt/:$letsencrypt" \
           -v "$network/log:$log" \
           certbot/certbot certonly --webroot -w $www -d $1 --email $email --non-interactive --agree-tos
dcm proxy reload
