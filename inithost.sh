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

sed -i \
    -e "s|#PermitRootLogin prohibit-password|PermitRootLogin no|g" /etc/ssh/sshd_config

/etc/init.d/ssh reload

dcm run all