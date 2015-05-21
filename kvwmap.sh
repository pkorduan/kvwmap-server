#!/bin/sh

# Settings
#settings
OS_USER="gisadmin"
IP=192.124.245.52
USER_DIR=/home/$OS_USER

fail_unless_root() {
  if [ "$(id -u)" != '0' ]; then
    log_failure_msg "This script must be run as root"
    exit 1
  fi
}

case "$1" in
  install)
    fail_unless_root

    # bash für root anpassen
    grep -q -F 'alias ll=' /etc/profile || echo "alias ll='ls -l'" >> /etc/profile
    grep -q -F 'alias rm=' /etc/profile || echo "alias rm='rm -i'" >> /etc/profile    
    
    source /etc/profile

    # Update debian repo
    apt-get update && install curl \
    	wget \
      git

    if [ `docker --version || grep 'Docker version'` ]; then
      # install docker
      curl -sSL https://get.docker.com/ | sh
    fi

    # create user for web gis anwendung
    id -u $OS_USER &>/dev/null || adduser $OS_USER

    # uncomment bash Einstellungen for web gis user
    sed -i "s/# alias ll='ls/alias ll='ls/g" $USER_DIR/.bashrc
    sed -i "s/alias rm='rm -i'/# alias rm='rm -i'/g" $USER_DIR/.bashrc

    # create directories
    mkdir -p $USER_DIR/apps
    mkdir -p $USER_DIR/etc
    mkdir -p $USER_DIR/www
    mkdir -p $USER_DIR/data
    
    # clone kvwmap repository into apps
    cd $USER_DIR/apps
    git clone https://github.com/srahn/kvwmap.git

    chown -R $OS_USER.$OS_USER $USER_DIR

    # download neccessary images for mysql and postgis
    docker pull mysql:5.5
    docker pull midillon/postgis:9.4

    # build the kvwmap-server images from the Dockerfilie in the git repository kvwmap-server
    docker build -t pkorduan/kvwmap-server $USER_DIR/kvwmap-server/
    
  start)
   fail_unless_root
    ;;

  stop)
    fail_unless_root
    ;;

  restart)
    fail_unless_root
    ;;

  status)
    ;;

  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac


