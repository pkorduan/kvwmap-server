#!/bin/bash
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
    lsb-release \
    pass

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
  echo "Stopp alle Container"
  dcm stop all
  echo "Entferne Netzwerke"
  docker network prune
  echo "Deinstalliere Docker und docker-compose"
  systemctl stop docker.socket
  apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
  apt-get autoremove -y --purge docker-engine docker docker.io docker-ce
  rm -rf /var/lib/docker
  rm -rf /var/lib/containerd
  rm $(which docker-compose)
  userdel -r gisadmin
  cp /etc/skel/.bashrc /root/.bashrc
  source /root/.bashrc
  if [ -f /etc/zabbix ]; then
    /etc/init.d/zabbix-agent2 stop
    apt remove zabbix-agent2
    rm -rf /etc/zabbix
  fi

  if [ -f /var/logs/serverlog.json ]; then
    rm /var/logs/serverlog.json
  fi
}

case "$1" in
  uninstall)
    case $2 in
      docker)
        systemctl stop docker.socket
        apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
      ;;
      user)
        systemctl stop docker.socket
        docker stop $(docker ps -q)
        docker rm $(docker ps -q)
        mv $USER_DIR/docker /var/lib/docker
        userdel -r gisadmin
        systemctl start docker
      ;;
      bashrc)
        cp /etc/skel/.bashrc /root/.bashrc
        source /root/.bashrc
      ;;
      all)
        uninstall_all
        sed -i \
            -e "s|PermitRootLogin no|#PermitRootLogin prohibit-password|g" \
            -e "s|^Port.*|#Port 22|g" \
            /etc/ssh/sshd_config
        /etc/init.d/ssh reload
        
      ;;
      *)
        echo "unistall missing argument docker, user, bashrc or all"
      ;;
    esac
  ;;
  *)
    read -p "kvwmap-server wirklich installieren? (j/n) " answer
    case ${answer:0:1} in
      j|J|y|Y )
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

        #############################
        # Install Docker
        #############################
        install_docker
        install_docker-compose

        # Initialize kvwmap-server
        # Version 
        OS_USER=gisadmin
        USER_DIR=/home/${OS_USER}
        CURRENT_DIR=$(pwd)

        # Pre-define Variables
        export GISADMIN_PASSWORD=$(openssl rand -base64 24)
        export SSH_PORT="22"
        export COMPOSE_VERSION="2.4.1"
        export SUBNET_KVWMAP_PROD="10"
        export MYSQL_ROOT_PASSWORD=$(openssl rand -base64 24)
        export MYSQL_USER="kvwmap"
        export MYSQL_PASSWORD=$(openssl rand -base64 24)
        export POSTGRES_PASSWORD=$(openssl rand -base64 24)
        read -p "Enter the domain name for this server: " CUSTOM_HOSTNAME
        export HOSTNAME=$CUSTOM_HOSTNAME

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
          dcm uninstall all
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
        echo "PATH: ${PATH}"
        source ~/.vimrc
        echo ".vimrc geladen."

        #############################
        # kvwmap-Instanz einrichten und starten
        #############################
        dcm proxy create
        dcm proxy up
        dcm create service kvwmap-server kvwmap_prod
        dcm up network kvwmap_prod

        # Create a mysql user for kvwmap
        docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_PASSWORD}');" mysql
        # Grant permissions to kvwmap user
        docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" mysql
        docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%';" mysql
        # Allow mysql access for user root only from network
        docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "RENAME USER 'root' TO 'root'@'172.0.${SUBNET_KVWMAP_PROD}.%';" mysql
        docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;" mysql

        read -p "Create Certificate for HTTPS? (j/n) " answer
        case ${answer:0:1} in
          j|J|y|Y )
            # Create SSL-Certificate for HTTPS Connections
            docker run -it --rm --name certbot -v "${USER_DIR}/networks/proxy/services/proxy/www/html:/var/www/html" -v "${USER_DIR}/networks/proxy/services/proxy/letsencrypt:/etc/letsencrypt" -v "${USER_DIR}/networks/proxy/services/proxy/log:/var/log/letsencrypt" certbot/certbot certonly -d ${HOSTNAME} --webroot -w /var/www/html --email "peter.korduan@gdi-service.de"
            # Enable https
            sed -i -e "s|platzhalterkvwmapserverdomainname|${HOSTNAME}|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default-ssl.conf
            sed -i -e "s|#add_header Strict-Transport-Security|add_header Strict-Transport-Security|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default.conf
            sed -i -e "s|#return 301 https|return 301 https|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-available/default.conf
            cd ${USER_DIR}/networks/proxy/services/proxy/nginx/sites-enabled
            ln -s ../sites-available/default-ssl.conf
            dcm proxy reload
          ;;
          * )
            echo "OK, Das Zertifikat kann später mit dem certbot Container erstellt werden."
          ;;
        esac

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
        Die Installation ist erfolgreich abgeschlossen.
        "
        echo "Der Zugang für root kann mit folgendem Befehl gesperrt werden:
        sed -i -e \"s|#PermitRootLogin prohibit-password|PermitRootLogin no|g\" /etc/ssh/sshd_config"
        echo "
        Nächste Schritte zum installieren von kvwmap:"
        echo "Browser öffnen mit der Adresse: http://${HOSTNAME}/install.php"

        echo "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
GISADMIN_PASSWORD=\"${GISADMIN_PASSWORD}\"
HOSTNAME=\"${HOSTNAME}\"
SSH_PORT=\"${SSH_PORT}\"
COMPOSE_VERSION=\"${COMPOSE_VERSION}\"
SUBNET_KVWMAP_PROD=\"${SUBNET_KVWMAP_PROD}\"
MYSQL_ROOT_PASSWORD=\"${MYSQL_ROOT_PASSWORD}\"
MYSQL_PASSWORD=\"${MYSQL_PASSWORD}\" for MYSQL_USER=\"${MYSQL_USER}\"
POSTGRES_PASSWORD=\"${POSTGRES_PASSWORD}\"
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = ="
      ;;
      * )
        echo "OK, nix passiert!"
      ;;
    esac
  ;;
esac
