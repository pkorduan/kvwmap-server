#!/bin/bash

set -e

apt_pkg_tools=(apt-utils lshw git jq sendmail tree unzip wget nano htop openssl gosu curl fish ca-certificates curl gnupg zstd)
apt_pkg_docker=(docker.io docker-compose apparmor)
apt_pkg_glances=(python3 python3-dev python3-jinja2 python3-psutil python3-setuptools python3-pip lm-sensors)

uninstall_all(){
    echo "uninstall all"
}

#flags
# -a [install|uninstall]
# -c [file]

while getopts a:c: flag
do
    case "${flag}" in
        a) action=${OPTARG};;
        c) configfile=${OPTARG};;
    esac
done

if [ -f "$configfile" ] && [ -v configfile ]; then
    source "$configfile"
fi

if [ "$action" = "install" ]; then
    if [ -z "$INSTALL_JN" ]; then   #aus $configfile
        read -p "kvwmap-server wirklich installieren? (j/n) " INSTALL_JN
    fi
    if [ "$INSTALL_JN" != "j" ]; then
        echo "Abbruch."
        exit 1
    fi

    apt-get update
    # install tools
    apt-get install -y ${apt_pkg_tools[*]}
    # install glances
    apt-get install -y ${apt_pkg_glances[*]}
    # install docker
    apt-get install -y ${apt_pkg_docker[*]}
    # install yq
    wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.13.3/yq_linux_amd64
    chmod a+x /usr/local/bin/yq

    ########################
    # Variables + Passwords
    ########################
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
    export PGADMIN_DEFAULT_PASSWORD=$(openssl rand -base64 24)
    export PGADMIN_DEFAULT_EMAIL #aus $configfile
    if [ -z "$DOMAIN" ]; then #aus configfile
        read -p "Enter the domain name for this server: " DOMAIN
    fi
    export DOMAIN
    export HOSTNAME #aus configfile
    if [ -z "$HOSTNAME" ]; then
        read -p "Enter the hostname for this server: " HOSTNAME
    fi
    export HOSTNAME

    ########################
    # Grupps und User gisadmin anlegen
    ########################
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
    sudo -u $OS_USER git clone https://github.com/pkorduan/kvwmap-server.git
    chown -R gisadmin.gisadmin kvwmap-server/* kvwmap-server/.*
    chmod -R g+w kvwmap-server/* kvwmap-server/.*
    cd kvwmap-server
    sudo -u $OS_USER git checkout develop
    ln -s ${USER_DIR}/kvwmap-server/bin/dcm /usr/bin/dcm

    #############################
    # Hostnamen setzen
    #############################
    hostname $HOSTNAME

    #############################
    # Umgebung einrichten
    #############################
    cp /etc/skel/.bashrc $USER_DIR/.bashrc
    source $USER_DIR/.bashrc
    sed -i \
        -e "s/alias ls='ls --color=auto'/alias ls='ls --color=auto -N'/g" \
        -e "s|#alias ll=|alias ll=|g" \
        -e "s|alias rm=|#alias rm=|g" \
        $USER_DIR/.bashrc
    echo "export QUOTING_STYLE=literal" >> $USER_DIR/.bashrc
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
    # kvwmap-Instanz einrichten und starten
    #############################
    dcm proxy create
    dcm proxy up
    dcm create service kvwmap-server kvwmap_prod
    dcm up network kvwmap_prod

    if [ -z "$CREATE_SSL_CERTIFICATES" ]; then  #aus configfile
        read -p "Create Certificate for HTTPS? (j/n) " CREATE_SSL_CERTIFICATES
    fi
    if [ "$CREATE_SSL_CERTIFICATES" = "j" ]; then
        # Create SSL-Certificate for HTTPS Connections
        docker run --rm --name certbot \
           -v "${USER_DIR}/networks/proxy/services/proxy/www/html:/var/www/html" \
           -v "${USER_DIR}/networks/proxy/services/proxy/letsencrypt:/etc/letsencrypt" \
           -v "${USER_DIR}/networks/proxy/services/proxy/log:/var/log/letsencrypt" certbot/certbot certonly \
           -d ${DOMAIN} \
           --webroot -w /var/www/html --email "peter.korduan@gdi-service.de" --non-interactive --agree-tos
        # Enable https
        sed -i -e "s|#add_header Strict-Transport-Security|add_header Strict-Transport-Security|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/server-available/${DOMAIN}/default.conf
        sed -i -e "s|#return 301 https|return 301 https|g" ${USER_DIR}/networks/proxy/services/proxy/nginx/server-available/${DOMAIN}/default.conf
        ln -rs ${USER_DIR}/networks/proxy/services/proxy/nginx/server-available/${DOMAIN}/default-ssl.conf ${USER_DIR}/networks/proxy/services/proxy/nginx/server-enabled/${DOMAIN}/default-ssl.conf
        chown ${OS_USER}:${OS_USER} ${USER_DIR}/networks/proxy/services/proxy/letsencrypt
        dcm proxy reload
    else
        echo "OK, Das Zertifikat kann später mit dem certbot Container erstellt werden."
    fi

    cd $USER_DIR/networks/kvwmap_prod/services/web
    ln -s $USER_DIR/networks/kvwmap_prod/services/web/www/ $USER_DIR
    chown -h gisadmin:gisadmin $USER_DIR/www


    #############################
    # mariadb einrichten
    #############################
    # Create a mysql user for kvwmap
    docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%' IDENTIFIED VIA mysql_native_password USING PASSWORD('${MYSQL_PASSWORD}');" mysql
    # Grant permissions to kvwmap user
    docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" mysql
    docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'172.0.${SUBNET_KVWMAP_PROD}.%';" mysql
    # Allow mysql access for user root only from network
    docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "RENAME USER 'root' TO 'root'@'172.0.${SUBNET_KVWMAP_PROD}.%';" mysql
    docker exec kvwmap_prod_mariadb mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;" mysql

    echo "
          Die Installation ist erfolgreich abgeschlossen.
        "
    echo "Der Zugang für root kann mit folgendem Befehl gesperrt werden:
    sed -i -e \"s|#PermitRootLogin prohibit-password|PermitRootLogin no|g\" /etc/ssh/sshd_config"
    echo "
    Nächste Schritte zum installieren von kvwmap:"
    echo "Browser öffnen mit der Adresse: http://${DOMAIN}/install.php"

    cat << EOF
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

Alle Zugangsdaten finden Sie in $CURRENT_DIR/kvwmap-passwords.log

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
EOF

(
cat << EOF
GISADMIN_PASSWORD=${GISADMIN_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD} for MYSQL_USER=${MYSQL_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
PGADMIN_PASSWORD=${PGADMIN_DEFAULT_PASSWORD=}
EOF
) > "$CURRENT_DIR"/kvwmap-passwords.log

elif [ "$action" = "uninstall" ]; then
    echo "uninstall..."
fi
