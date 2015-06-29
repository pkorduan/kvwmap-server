#!/bin/bash

# bash für root anpassen
sed -i \
    -e "s|# alias ls=|alias ls=|g" \
    -e "s|# alias ll=|alias ll=|g" \
    -e "s|# alias rm=|alias rm=|g" \
    ~/.bashrc

# Update debian repo
apt-get update && apt-get install -y
  apt-utils \
  curl \
  git \
  wget

case `docker --version` in
  *Docker*)
    echo 'Docker allready installed!' 
    ;;
  *)
    # install docker
    echo 'Install docker.'
    curl -sSL https://get.docker.com/ | sh
  ;;
esac

# create user for web gis anwendung if not exists
$OS_USER_EXISTS || adduser $OS_USER

# uncomment bash Einstellungen for web gis user
echo "export PATH=\$PATH:${USER_DIR}/kvwmap-server" > ~/.bashrc
sed -i \
  -e "s|#alias ll=|alias ll=|g" \
  -e "s|alias rm=|#alias rm=|g" \
    $USER_DIR/.bashrc

# create directories
mkdir -p $USER_DIR/data \
         $USER_DIR/db/mysql \
         $USER_DIR/db/postgresql/data \
         $USER_DIR/etc/apache2/sites-available \
         $USER_DIR/etc/apache2/sites-enabled \
         $USER_DIR/etc/mysql \
         $USER_DIR/etc/postgresql \
         $USER_DIR/etc/php5 \
         $USER_DIR/www/apps \
         $USER_DIR/www/html \
         $USER_DIR/www/logs \
         $USER_DIR/www/tmp \
         $USER_DIR/www/cache \
         $USER_DIR/www/wms \
         $USER_DIR/www/var/data/mapfiles \
         $USER_DIR/www/var/data/synchro \
         $USER_DIR/www/var/data/upload \
         $USER_DIR/www/var/data/druckrahmen \
         $USER_DIR/www/var/data/bilder \
         $USER_DIR/www/var/data/alb \
         $USER_DIR/www/var/data/referencemaps \
         $USER_DIR/www/var/data/nachweise \
         $USER_DIR/www/var/data/recherchierte_antraege \
         $USER_DIR/www/var/data/festpunkte/archiv

cp $USER_DIR/kvwmap-server/www/html/index.php $USER_DIR/www/html/index.php
cp -R $USER_DIR/kvwmap-server/etc/ $USER_DIR/
cp -R $USER_DIR/kvwmap-server/www/var/data/mapfiles/ $USER_DIR/www/var/data/
cp -R $USER_DIR/kvwmap-server/www/var/data/referencemaps/ $USER_DIR/www/var/data/
cp -R $USER_DIR/kvwmap-server/www/apps/PDFClass $USER_DIR/www/apps/

if [ ! -d "$USER_DIR/www/apps/kvwmap" ]; then
  # clone kvwmap repository into apps
  git clone https://github.com/srahn/kvwmap.git $USER_DIR/www/apps/kvwmap
fi

mkdir -p $USER_DIR/www/apps/kvwmap/layouts/custom \
         $USER_DIR/www/apps/kvwmap/layouts/snippets/custom \
         $USER_DIR/www/apps/kvwmap/symbols/custom

chown -R $OS_USER.$OS_USER $USER_DIR

# download neccessary images for mysql and postgis
docker pull mysql:5.5
echo "[mysqld]" > $USER_DIR/etc/mysql/docker.cnf
echo "user = mysql" >> $USER_DIR/etc/mysql/docker.cnf
echo "datadir = /var/lib/mysql" >> $USER_DIR/etc/mysql/docker.cnf

docker pull mdillon/postgis:9.4

# build the kvwmap-server images from the Dockerfilie in the git repository kvwmap-server
cd $USER_DIR/kvwmap-server/docker
docker build -t pkorduan/kvwmap-server:latest .
