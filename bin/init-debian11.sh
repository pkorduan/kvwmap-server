#!/bin/bash

# bash <(curl -s https://dev.gdi-service.de/public/init-debian11.sh)

set -e

echo "Das Script fügt das Docker-APT-Repo den Quellen hinzu, installiert Packete"
echo "und richtet den User,Gruppe gisadmin ein."
read -p "Fortfahren ? [j|n] " answer

if [ "$answer" != "j" ]; then
    echo "Abbruch durch Nutzer."
    exit 1
fi

# packete installieren

apt-get update
apt-get install -y \
    apt-utils \
    lshw \
    git \
    jq \
    sendmail \
    tree \
    unzip \
    wget \
    nano \
    htop \
    openssl \
    gosu \
    curl \
    fish
#    glances \

curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x ./get-docker.sh
./get-docker.sh

wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.13.3/yq_linux_amd64
chmod a+x /usr/local/bin/yq

#############################
# Gruppe + OS_USER anlegen (gisadmin)
#############################

OS_USER=gisadmin
USER_DIR=/home/${OS_USER}
CURRENT_DIR=$(pwd)

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
       echo "Use pre-defined GISADMIN_PASSWORD: ${GISADMIN_PASSWORD:0:5}..."
    fi
    useradd -u 17000 -g 1700 -d ${USER_DIR} -m -s /bin/bash -p $(echo ${GISADMIN_PASSWORD} | openssl passwd -1 -stdin) ${OS_USER}
fi
cd ${USER_DIR}

#############################
# Umgebung einrichten
#############################

cp /etc/skel/.bashrc $USER_DIR/.bashrc
echo "
export PATH=\$PATH:${USER_DIR}/kvwmap-server/bin" >> $USER_DIR/.bashrc
sed -i \
-e "s|#alias ll=|alias ll=|g" \
-e "s|alias rm=|#alias rm=|g" \
$USER_DIR/.bashrc
echo "alias l='ls -alh --color=yes'" >> $USER_DIR/.bashrc
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
# Hostnamen setzen
#############################
read -p "Enter the domain name for this server: " HOSTNAME
hostname $HOSTNAME
