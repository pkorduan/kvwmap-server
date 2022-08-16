#this script is used to create ssl
WEBROOT=/var/www/html
EMAIL=peter.korduan@gdi-service.de
DIR=/home/gisadmin/networks/proxy/services/proxy
MIS_DOMAIN="$(cat ${DIR}/nginx/sites-available/default.conf | grep server_name | cut -d ';' -f 1 | awk '{print $2}')"

docker run --rm --interactive --name certbot \
  -v "${DIR}/www/html:/var/www/html" \
  -v "${DIR}/letsencrypt:/etc/letsencrypt" \
  -v "${DIR}/log:/var/log/letsencrypt" \
certbot/certbot certonly -d mis.${MIS_DOMAIN} --webroot -w ${WEBROOT} --email "${EMAIL}"

sed -i -e "s|#||g" ${DIR}/nginx/sites-available/mis.${MIS_DOMAIN}.conf

dcm reload proxy
