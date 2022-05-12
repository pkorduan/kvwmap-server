#!/bin/bash
# Initialize kvwmap-server
# Version 
OS_USER=gisadmin
USER_DIR=/home/${OS_USER}
echo "USER_DIR: ${USER_DIR} gesetzt."
CURRENT_DIR=$(pwd)

# Pre-define Variables
GISADMIN_PASSWORD=$(openssl rand -base64 24)
HOSTNAME="localhost"
SSH_PORT="50346"
COMPOSE_VERSION="2.4.1"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 24)
MYSQL_PASSWORD=$(openssl rand -base64 24)
POSTGRES_PASSWORD=$(openssl rand -base64 24)

# run this scirpt:
# wget -O inithost.sh https://raw.githubusercontent.com/pkorduan/kvwmap-server/master/inithost && chmod a+x inithost.sh && ./inithost.sh

install_docker() {
  echo "Install docker auf dem Hostrechner ..."
  # Update debian repo
  apt-get update && apt-get install -y \
    apt-utils \
    ca-certificates \
    curl \
    gnupg2 \
    lsb-release

  # install docker demon and client on host system if not exists already
  case `docker --version` in
    *Docker*)
      echo 'Docker schon installiert!'
      ;;
    *)
      echo 'Installiere docker ....'
      curl -sSL https://get.docker.com/ | sh
      mkdir -p $USER_DIR/docker/lib
      systemctl stop docker.socket
      mv /var/lib/docker $USER_DIR/docker/lib
      ln -s $USER_DIR/docker/lib/docker /var/lib/docker
      systemctl start docker
    ;;
  esac

  # enable memory and swap accounting. This prevent from
  # WARNING: Your kernel does not support cgroup swap limit. and
  # WARNING: Your kernel does not support swap limit capabilities. Limitation discarded.
  # This setting affects only after rebooting the system
  sed -i \
    -e "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"|g" \
    /etc/default/grub
  su - root update-grub
}

install_docker-compose() {
  echo "Installiere docker-compose. Verfügbare Tags siehe: https://github.com/docker/compose/tags"
  if [ -z "${COMPOSE_VERSION}" ] ; then
    read -p "Welche Version von docker-compose soll installiert werden (2.4.1)? " COMPOSE_VERSION
    if [ -z $COMPOSE_VERSION ] ; then
      COMPOSE_VERSION="2.4.1"
    fi
  else
    echo "Use pre-defined COMPOSE_VERSION: ${COMPOSE_VERSION}"
  fi
  curl -L "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

uninstall_all() {
  systemctl stop docker.socket
  apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin
  rm -rf /var/lib/docker
  rm -rf /var/lib/containerd
  userdel -r gisadmin
  cp /etc/skel/.bashrc /root/.bashrc
  source /root/.bashrc
}

#############################
# Install tools
#############################

apt-get update && apt-get install -y \
  apt-utils \
  lshw \
  git \
  glances \
  jq \
  sendemail \
  tree \
  unzip \
  wget

wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.13.3/yq_linux_amd64
chmod a+x /usr/local/bin/yq

#############################
# Gruppe + OS_USER anlegen (gisadmin)
#############################

if [ $(getent group ${OS_USER}) ] ; then
  echo "Group ${OS_USER} already exists."
else
  echo "Create group ${OS_USER} with id 1700."
  groupadd -g 1700 ${OS_USER}
fi

if [ $(getent passwd ${OS_USER}) ] ; then
  echo "User ${OS_USER} already exists."
else
  echo "Create user ${OS_USER} with id:17000 and add to group ${OS_USER} gid:1700."
  if [ -z "${GISADMIN_PASSWORD}" ] ; then
    read -s -p "Enter password for OS user ${OS_USER}: " GISADMIN_PASSWORD
  else
    echo "Use pre-defined GISADMIN_PASSWORD: ${GISADMIN_PASSWORD:1:5}..."
  fi
  useradd -u 17000 -g 1700 -d ${USER_DIR} -m -s /bin/bash -p $(echo ${GISADMIN_PASSWORD} | openssl passwd -1 -stdin) ${OS_USER}
fi

/usr/sbin/usermod -a -G docker $OS_USER

cd ${USER_DIR}

#############################
# kvmap-server entfernen, wenn vorhanden
#############################

if [ -d ./kvwmap-server ] ; then
  echo 'Stop kvwmap-server and uninstall all.'
  $USER_DIR/kvwmap-server/bin/dcm.sh uninstall all
fi

if [ -d ./kvwmap-server ] ; then
  echo "Abort by user."
  exit
fi

echo 'Clone kvwmap-server repository to ./kvwmap-server.'
git clone https://github.com/pkorduan/kvwmap-server.git
chown -R gisadmin.gisadmin kvwmap-server/* kvwmap-server/.*
chmod -R g+w kvwmap-server/* kvwmap-server/.*
cd kvwmap-server
git checkout develop

#############################
# Hostnamen setzen
#############################

if [ -z "${HOSTNAME}" ] ; then
  read -p "Enter the domain name for this server: " HOSTNAME
else
  echo "Use pre-defined HOSTNAME: ${HOSTNAME}"
fi
hostname $HOSTNAME

#############################
# SSH_PORT ändern
#############################

if [ -z "${SSH_PORT}" ] ; then
  read -p "Enter port for ssh login: " SSH_PORT
else
  echo "Use pre-defined SSH_PORT: ${SSH_PORT}"
fi
sed -i \
    -e "s|#PermitRootLogin prohibit-password|PermitRootLogin no|g" \
    -e "s|#Port 22|Port ${SSH_PORT}|g" \
    /etc/ssh/sshd_config
/etc/init.d/ssh reload

#############################
# Umgebung einrichten
#############################

cp /etc/skel/.bashrc $USER_DIR/.bashrc
echo "
export PATH=\$PATH:${USER_DIR}/kvwmap-server" >> $USER_DIR/.bashrc
sed -i \
    -e "s|#alias ll=|alias ll=|g" \
    -e "s|alias rm=|#alias rm=|g" \
    $USER_DIR/.bashrc
echo "alias l='ls -alh --color=yes'" >> $USER_DIR/.bashrc
echo "alias dcm='/home/gisadmin/kvwmap-server/bin/dcm.sh'" >> $USER_DIR/.bashrc
echo "export PS1=\"\[\e[0m\]\[\e[01;31m\]\u\[\e[0m\]\[\e[00;37m\]@\[\e[0m\]\[\e[01;34m\]\h\[\e[0m\]\[\e[00;37m\]:\[\e[0m\]\[\e[01;37m\]\w\[\e[0m\]\[\e[00;37m\] \\$ \[\e[0m\]\"" >> $USER_DIR/.bashrc
echo "set nocompatible" >> $USER_DIR/.vimrc
echo ".bashrc angepasst."

cp $USER_DIR/.bashrc ~/.bashrc
echo ".bashrc für Root gesetzt."
cp $USER_DIR/.vimrc ~/.vimrc
echo ".vimrc für Root gesetzt."

source ~/.bashrc
echo ".bashrc geladen."
source ~/.vimrc
echo ".vimrc geladen."

#############################
# Docker
#############################

install_docker
install_docker-compose

#############################
# kvwmap-Instanz einrichten und starten
#############################
$USER_DIR/kvwmap-server/bin/dcm.sh proxy create
$USER_DIR/kvwmap-server/bin/dcm.sh proxy up
$USER_DIR/kvwmap-server/bin/dcm.sh create service kvwmap-server kvwmap_prod
$USER_DIR/kvwmap-server/bin/dcm.sh up network kvwmap_prod

# Create a mysql user for kvwmap
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.0.${SUBNET}.%' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_PASSWORD}')"
# Grant permissions to kvwmap user
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'kvwmap'@'172.0.${SUBNET}.%' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0"
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'kvwmap'@'172.0.${SUBNET}.%'"
# Allow mysql access for user root only from network
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "RENAME USER 'root' TO 'root'@'172.0.${SUBNET}.%'"
docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES" mysql

# Create SSL-Certificate for HTTPS Connections
docker run -it --rm --name certbot -v "${USER_DIR}/networks/proxy/services/proxy/www/html:/var/www/html" -v "${USER_DIR}/networks/proxy/services/proxy/letsencrypt:/etc/letsencrypt" -v "${USER_DIR}/networks/proxy/services/proxy/log:/var/log/letsencrypt" certbot/certbot certonly --webroot -w /var/www/html --email "peter.korduan@gdi-service.de"
# Enable https
sed -i -e "s|platzhalterkvwmapserverdomainname|${HOSTNAME}|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default-ssl.conf
sed -i -e "s|#return 301 https|return 301 https|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default.conf
cd ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-enabled
ln -s ../sites-available/default-ssl.conf
$USER_DIR/kvwmap-server/bin/dcm.sh proxy reload

cd $USER_DIR/networks/kvwmap_prod/services/web

#read -p "Initscript löschen? (j/n) " answer
#case ${answer:0:1} in
#  j|J|y|Y )
#    rm inithost.sh
#  ;;
#  * )
#    echo "OK, nix passiert!"
#  ;;
#esac

echo "
Die Installation ist erfolgreich abgeschlossen."
echo "Achtung Der Zugang als root ist jetzt von außen gesperrt!"
echo "Sie können sich nur noch als gisadmin per ssh mit diesem Server verbinden."
echo "
Nächste Schritte zum installieren von kvwmap:"
echo "Browser öffnen mit der Adresse: http://${HOSTNAME}/install.php"

echo "
GISADMIN_PASSWORD=$GISADMIN_PASSWORD
HOSTNAME=$HOSTNAME
SSH_PORT=$SSH_PORT
COMPOSE_VERSION=$COMPOSE_VERSION
"