#!/bin/bash
# Initialize kvwmap-server
OS_USER=gisadmin
USER_DIR=/home/${OS_USER}

# run this scirpt:
# wget -O inithost.sh https://gdi-service.de/public/kvwmap_resources/inithost && chmod a+x inithost.sh && ./inithost.sh

# Install utils and git
apt-get update && apt-get install -y \
  apt-utils \
  git

groupadd -g 1700 ${OS_USER}
read -p "Enter password for OS user ${OS_USER}: " GISADMIN_PASSWORD
useradd -u 17000 -g 1700 -d ${USER_DIR} -m -s /bin/bash -p $(echo ${GISADMIN_PASSWORD} | openssl passwd -1 -stdin) ${OS_USER}

cd ${USER_DIR}

git clone https://github.com/pkorduan/kvwmap-server.git

kvwmap-server/dcm install kvwmap

source ~/.bash_rc

sed -i -e "s|#PermitRootLogin prohibit-password|PermitRootLogin no|g" /etc/ssh/sshd_config

/etc/init.d/ssh reload

dcm run pgsql
dcm rm pgsql
cp kvwmap-server/db/pg_hba.conf db/postgresql/data/
chown 999.docker db/postgresql/pg_hba.conf
cp kvwmap-server/db/allowip db/postgresql/data/
chmod a+x db/postgresql/allowip
sed -i -e "s|read -s |#read -s|g" etc/postgresql/env_and_volumes
dcm run all
sed -i -e "s|read -s |#read -s|g" etc/mysql/env_and_volumes
sed -i -e "s|read -s |#read -s|g" etc/web/env_and_volumes
read -p "Add IP to allow external access with pgAdmin Client: " PGADMIN_IP
echo "host    all             kvwmap          ${PGADMIN_IP}/32               md5 # externe IP for external pgAdmin access" >> db/postgresql/pg_hba.conf
docker exec pgsql-server runuser -l postgres -c '/usr/lib/postgresql/9.6/bin/pg_ctl -D /var/lib/postgresql/data reload'