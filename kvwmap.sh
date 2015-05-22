#!/bin/bash

# Settings
#settings
OS_USER="gisadmin"
OS_USER_EXISTS=false
getent passwd $OS_USER >/dev/null 2>&1 && OS_USER_EXISTS=true
USER_DIR=/home/$OS_USER


fail_unless_root() {
  if [ "$(id -u)" != '0' ]; then
    echo "This script must be run as root"
    exit 1
  fi
}

case "$1" in
  install)
    fail_unless_root

    # bash für root anpassen
    grep -q -F 'alias ll=' /etc/profile || echo "alias ll='ls -l'" >> /etc/profile
    grep -q -F 'alias rm=' /etc/profile || echo "alias rm='rm -i'" >> /etc/profile    
    

    # Update debian repo
    apt-get update
    apt-get install -y apt-utils curl wget git

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
    sed -i "s/# alias ll='ls/alias ll='ls/g" $USER_DIR/.bashrc
    sed -i "s/alias rm='rm -i'/# alias rm='rm -i'/g" $USER_DIR/.bashrc

    # create directories
    mkdir -p $USER_DIR/apps
    mkdir -p $USER_DIR/etc/apache2
    mkdir -p $USER_DIR/www
    mkdir -p $USER_DIR/data
    
    if [ ! -d "$USER_DIR/apps/kvwmap" ]; then
      # clone kvwmap repository into apps
      git clone https://github.com/srahn/kvwmap.git $USER_DIR/apps/kvwmap
    fi

    chown -R $OS_USER.$OS_USER $USER_DIR

    # download neccessary images for mysql and postgis
    docker pull mysql:5.5
    docker pull mdillon/postgis:9.4

    # build the kvwmap-server images from the Dockerfilie in the git repository kvwmap-server
    docker build -t pkorduan/kvwmap-server .
  ;;

  uninstall)
    fail_unless_root
    
    # stop and remove all container and images
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    docker rmi -f $(docker images -q)
    while true; do
      read -p "User $OS_USER mit home Verzeichnis löschen? Es gehen alle Daten in /home/$OS_USER verloren! (j/n) " jn
      case $jn in
        [YyJj]* )
          # remove user if exists
          $OS_USER_EXISTS && userdel -f $OS_USER
          echo "User $OS_USER existiert nicht mehr."
          # remove user and its home directory
          if [ -d "$USER_DIR" ]; then
            rm -R -f $USER_DIR
            echo "$USER_DIR gelöscht."
          fi
          return
        ;;
        [Nn]* )
          exit
          ;;
        *)
          echo "Bitte antworten mit Ja oder Nein."
        ;;
      esac
    done
  ;;
  
  rebuild-kvwmap-server)
    fail_unless_root
    docker rmi -f $(docker images -q pkorduan/kvwmap-server:latest)
    docker build -t pkorduan/kvwmap-server:latest .
  ;;

  start)
    fail_unless_root
    # run the mysql container
    read -s -p "Enter Password for MySql user root: " MYSQL_ROOT_PASSWORD
    docker run --name mysql-server -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -d mysql:5.5
    # run the pgsql container
    read -s -p "Enter Password for PostgreSql user root: " PGSQL_ROOT_PASSWORD
    docker run --name pgsql-server -e POSTGRES_PASSWORD=$PGSQL_PASSWORD -d mdillon/postgis:9.4
    
    docker run --name web -p 80:80 –link mysql-server:mysql –link pgsql-server:pgsql -d pkorduan/kvwmap-server:latest \
    -v $USER_DIR/etc/apache2:/etc/apache2
    -v /home/gisadmin/etc/php5:/etc/php5
    -v /home/gisadmin/etc/postgres:/etc/postgres/9.4/main/
    -v /home/gisadmin/www:/var/www
    -v /home/gisadmin/data:/home/gisadmin/data
  ;;

  stop)
    fail_unless_root
    docker stop $(docker ps -a -q)
    echo "Alle Container gestopped."
    docker rm $(docker ps -a -q)
    echo "Alle Container gelöscht."
  ;;

  restart)
    fail_unless_root
  ;;

  status)
  ;;

  *)
    echo "Usage: $0 {install|start|stop|restart|status|uninstall|rebuild-kvwmap-server}"
    exit 1
    ;;
esac


