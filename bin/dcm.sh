#!/bin/bash
# Version 3.0.0

function usage() {
  echo ""
  echo "Das Script führt Anweisungen für die Verwaltung des kvwmap-Servers aus. Es muss als Nutzer root ausgeführt werden wenn der Nutzer nicht zur Gruppe docker gehört.";
  echo "Dazu gehören Befehle zum Starten und Stoppen der Container aber auch solche zum Anzeigen von Stati und Laden von Konfigurationen und sonstige häufiger für die Administration benötigten Komandos."
  echo "Kontakt: peter.korduan@gdi-service.de"
  echo ""
  echo "Netzwerke und Dienste erstellen und entfernen:"
  echo "dcm create network [network]"
  echo "dcm create service [service] [network]"
  echo "dcm remove network [network]"
  echo "dcm remove service [service] [network]"
  echo ""
  echo "Dienst als Container starten:"
  echo "dcm up [service] [network]"
  echo "dcm up network [network]"
  echo ""
  echo "Container stoppen und entfernen:"
  echo "dcm down [service] [network]"
  echo "dcm down network [network]"
  echo ""
  echo "Container neu erstellen und starten:"
  echo "dcm rerun [all|service] [network]"
  echo ""
  echo "Container starten, stoppen:"
  echo "dcm start [all|service] [network]"
  echo "dcm restart [all|service] [network]"
  echo "dcm stop [all|service] [network]"
  echo ""
  echo "Container entfernen:"
  echo "dcm rm all [network] default kvwmap_prod"
  echo "dcm rm [service] [network]"
  echo ""
  echo "Für networks wird das compose-networks.yml aktualisiert. Für service wird aus dem Template ein neues docker-compose.yml erstellt."
  echo "dcm compose networks"
  echo "dcm compose service [service] [network]"
  echo ""
  echo "Proxy-Server einrichten, starten, stoppen und Konfiguration laden:"
  echo "dcm proxy create"
  echo "dcm proxy up"
  echo "dcm proxy down"
  echo "dcm proxy reload"
  echo ""
  echo "dcm ls networks"
  echo "dcm build"
  echo "dcm clean"
  echo "dcm config [service] [network]"
  echo "dcm console [service] [network]"
  echo "dcm inspect network [network]"
  echo "dcm inspect service [service] [network]"
  echo "dcm logs [service] [network]"
  echo "dcm uninstall Deinstalliert alles"
}

function debug() {
  if $DEBUG ; then
    echo $1
  fi
}

function build_kvwmap_server() {
  TAG=$1
  if [ -z "$TAG" ] ; then
    TAG=$KVWMAP_IMAGE_VERSION
  fi
  cd $USER_DIR/kvwmap-server/docker
  docker build -t pkorduan/kvwmap-server:${TAG} .
}

function build_gdal_image() {
  TAG=$1
  if [ -z "$TAG" ] ; then
    TAG="latest"
  fi
  echo "Build the image pkorduan/gdal-sshd:$TAG"
  cd $USER_DIR/gdal-sshd
  docker build -t pkorduan/gdal-sshd:$TAG .
}

# Bricht ab, wenn nutzer nicht root ist
function fail_unless_root() {
  dcm_user=$(id -nu)
  dcm_user_group=$(id -nG)
  # Wenn ausführender Nutzer nicht root ist
  if [ "${dcm_user}" != "root" ]; then
    echo "Aktion kann nur als User root ausgeführt werden."
    exit 1
  fi
}

function list_services() {
  while read SERVICE
  do
    echo $(basename $SERVICE)
  done < <(find ${TEMPLATEPATH} -maxdepth 1 -mindepth 1 -type d)
}

function list_networks() {
  find ${USER_DIR}/networks/ -mindepth 1 -maxdepth 1 -type d -exec sh -c 'test -f {}/env && echo $(basename {})' \;
}

##################################################
## Service erstellen, Container verwalten
##################################################

function create_network() {
  NETWORK_NAME=$1
  NETWORK_DIR=${USER_DIR}/networks/${NETWORK_NAME}
  echo "Installiere Voraussetzungen für den Betrieb des Netzwerkes $network_name"
  if [ -d "$NETWORK_DIR" ]; then
    echo "Das Netzwerk ${NETWORK_NAME} existiert bereits! Abbruch."
    return
  fi

  if [ ! -d "${USER_DIR}/networks" ]; then
    echo "Erzeuge das Verzeichnis für networks ${USER_DIR}/networks"
    mkdir ${USER_DIR}/networks
    chown ${OS_USER}.${OS_USER} ${USER_DIR}/networks
    chmod g+w ${USER_DIR}/networks
  fi

  echo "Erzeuge Netzwerk Verzeichnis ${NETWORK_DIR}"
  mkdir -p ${NETWORK_DIR}
  if [ "$NETWORK_NAME" != "proxy" ]; then
    if $DEBUG ; then
      cp -vr ${USER_DIR}/kvwmap-server/kvwmap_template_network/* ${NETWORK_DIR}
    else
      cp -r ${USER_DIR}/kvwmap-server/kvwmap_template_network/* ${NETWORK_DIR}
    fi
    chown ${OS_USER}.${OS_USER} ${NETWORK_DIR}
    chmod g+w ${NETWORK_DIR}
  fi

  if [ "$NETWORK_NAME" == "proxy" ]; then
    echo '# Umgebungsvariablen für proxy Container Einrichtung' > ${NETWORK_DIR}/env
  fi

  case ${NETWORK_NAME} in
    kvwmap_prod)
      SUBNET=$SUBNET_KVWMAP_PROD
    ;;
    kvwmap_dev)
      SUBNET=20
    ;;
    kvwmap_demo)
      SUBNET=30
    ;;
    proxy)
      SUBNET=1
    ;;
    * )
      read -p "Gib ein Subnetznummer für das Netzwerk an, z.B. x für das Subnetz 172.0.x.0/24: " ANSWER
      SUBNET=$ANSWER
      if [ -z "$SUBNET" ]; then
        SUBNET="10"
      fi
    ;;
  esac
  echo "Set Subnet for Network ${NETWORK_NAME}: 172.0.${SUBNET}.0/24";

  ip_range="172.0.${SUBNET}.0/24"
  echo "NETWORK_SUBNET=${ip_range}" >> ${NETWORK_DIR}/env

  chown ${OS_USER}.${OS_USER} ${NETWORK_DIR}/env
  if [ "$NETWORK_NAME" != "proxy" ]; then
    chown -R ${OS_USER}.${OS_USER} ${NETWORK_DIR}/volumes
  fi
  docker network create --subnet "$ip_range" $NETWORK_NAME
  echo "Netwerk erstellt. Mit dcm create service [service] ${NETWORK_NAME} können jetzt die dazugehörigen Dienste installiert werden."

  if [[ $NETWORK_NAME != "proxy" && "$(docker inspect proxy_proxy -f {{.NetworkSettings.Networks.${NETWORK_NAME}}})" == "<no value>" ]] ; then
    add_proxy_to_network $NETWORK_NAME
  fi
}

function add_proxy_to_network() {
  echo "Füge Proxy zum netzwerk $1 hinzu."
  cmd="docker network connect $1 proxy_proxy"
  echo $cmd
  $cmd
}

function remove_network(){
  NETWORK_NAME=$1
  read -p "Es wird das Netzwerk $1 mit allen Services und Daten gelöscht! Fortfahren? [j|n]: " ANSWER
  case ${ANSWER:0:1} in
    j|J|y|Y )
      up_down_network ${NETWORK_NAME} "down"
      rm -rvdf ${USER_DIR}/networks/${NETWORK_NAME}
      docker network rm $NETWORK_NAME
      echo "Netzwerk entfernt."
    ;;
    * )
      echo "OK, nix passiert"
    ;;
  esac
}

function write_compose_file() {
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  echo "Compose-File erstellen"
  echo "für Service $SERVICE_NAME im Netzwerk $NETWORK_NAME"
  source ${USER_DIR}/networks/${NETWORK_NAME}/env

  write_file=true
  if [ -f ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}/docker-compose.yml ]; then
    read -p "Es existiert bereits ein docker-compose.yml für diesen Service. Soll der Service neu aus dem Template erstellt werden? [j/n] :" answer
    case ${answer:0:1} in
      j|J|y|Y )
        write_file=true
      ;;
      * )
        write_file=false
      ;;
    esac
  fi

  if [ "$write_file" = true ]; then
  # ===
  # === >> export der Variablen aus der Netzwerk env-Datei, gewünschte hinzufügen
  # ===
    export NETWORK_NAME
    export SERVICE_NAME
    export NETWORK_SUBNET
    export MYSQL_ROOT_PASSWORD
    export POSTGRES_PASSWORD
    export USER_DIR

    echo " - Substituiere Umgebungsvariablen in compose-template.yml und schreibe sie nach docker-compose.yml"
    envsubst < ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}/compose-template.yml > ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}/docker-compose.yml

    chown gisadmin.gisadmin ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}/docker-compose.yml
    chmod g+w ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}/docker-compose.yml
    rm ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}/compose-template.yml
  else
    echo "Keine Änderung am Service."
  fi
}

function service_exists(){
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  if [ ! -d ${USER_DIR}/networks/${NETWORK_NAME} ]; then
    return 1
  fi
  if [ ! -f ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}/docker-compose.yml ]; then
    return 2
  fi
  return 0
}

function create_service() {
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  NETWORK_DIR=${USER_DIR}/networks/${NETWORK_NAME}
  echo "dcm create_service mit SERVICE_NAME: ${SERVICE_NAME} NETWORK_NAME: ${NETWORK_NAME}"

  export SERVICE_NAME
  export NETWORK_NAME

  if [ ! -d "$NETWORK_DIR" ]; then
    echo "Netzwerk ${NETWORK_NAME} existiert noch nicht. Erzeuge Netzwerk ${NETWORK_NAME}"
    dcm create network $NETWORK_NAME
  fi

  echo "Lade ${TEMPLATEPATH}/${SERVICE_NAME}/dcm"
  if [ ! -f ${TEMPLATEPATH}/${SERVICE_NAME}/dcm ]; then
    echo "Keine dcm-Erweiterung gefunden. Abbruch."
    echo ${TEMPLATEPATH}/${SERVICE_NAME}/dcm
    return 1
  fi
  source ${TEMPLATEPATH}/${SERVICE_NAME}/dcm
  source ${USER_DIR}/networks/${NETWORK_NAME}/env
  install_service

  if [ "${SERVICE_NAME}" != "kvwmap-server" ]; then
    write_compose_file ${SERVICE_NAME} ${NETWORK_NAME}
    echo "Service ${SERVICE_NAME} wurde erstellt. Mit dcm up ${SERVICE_NAME} ${2} kann der Dienst gestartet werden."
  fi
}

function remove_service() {
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  read -p "Es wird der Service ${SERVICE_NAME} und alle Daten gelöscht! Fortfahren? [j|n]: " answer
  case ${answer:0:1} in
    j|J|y|Y )
    ;;
    * )
      return 1
    ;;
  esac

  #Service beenden
  up_down_service ${SERVICE_NAME} ${NETWORK_NAME} down
  #Verzeichnisse löschen
  rm -rdvf ${USER_DIR}/networks/${NETWORK_NAME}/services/${SERVICE_NAME}
}

function compose_call(){
  cmd="docker-compose -f ./docker-compose.yml --env-file ./../../env --project-name ${SERVICE_NAME}_${NETWORK_NAME} "
  echo $cmd
}

function up_down_service() {
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  UP_DOWN=$3
  CURRENT_PWD=$(pwd)

  service_exists ${SERVICE_NAME} ${NETWORK_NAME}
  if [ "$?" -eq 0 ]; then
    NETWORK_PATH=${USER_DIR}/networks/${NETWORK_NAME}
    SERVICE_PATH=${NETWORK_PATH}/services/${SERVICE_NAME}
    cd ${SERVICE_PATH}
    export NETWORK_PATH
    export SERVICE_PATH
    cmd="$(compose_call)"
    case "$UP_DOWN" in
      up)
        echo "Erstelle Service ${NETWORK_NAME}_${SERVICE_NAME}"
        cmd="${cmd} up -d"
      ;;
      down)
        echo "Entferne Service ${NETWORK_NAME}_${SERVICE_NAME}"
        cmd="${cmd} down"
      ;;
      *)
        cmd=""
      ;;
    esac
    echo $cmd
    $cmd
  else
    echo "Service existiert nicht!"
    cd $CURRENT_PWD
    return 1
  fi
  cd $CURRENT_PWD
  return 0
}

function start_service() {
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  echo "Starte Container ${NETWORK_NAME}_${SERVICE_NAME}"
  docker start ${NETWORK_NAME}_${SERVICE_NAME}
}

function stop_service() {
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  echo "Stoppe Container ${NETWORK_NAME}_${SERVICE_NAME}"
  docker stop ${NETWORK_NAME}_${SERVICE_NAME}
}

function start_all_services() {
  docker ps --format {{.Names}} --filter status=exited | xargs -i docker start {}
}

function stop_all_services() {
  docker ps --format {{.Names}} --filter status=running | xargs -i docker stop {}
}

function list_services_by_network(){
  echo "todo"
}

function up_down_network() {
  NETWORK_NAME=$1
  UP_DOWN=$2
  echo "Alle Services im Netzwerk ${NETWORK_NAME} werden in den Status $UP_DOWN gebracht..."

  # alle Services im Netzwerk runterfahren
  # bei letztem Service wird das Netzwerk selbst entfernt
  while read SERVICE_NAME
  do
    up_down_service ${SERVICE_NAME} ${NETWORK_NAME} "$UP_DOWN"
  done < <(find ${USER_DIR}/networks/${NETWORK_NAME}/ -maxdepth 3 -mindepth 3 -type f -name docker-compose.yml | xargs -i dirname {} | xargs -i basename {} )
}

copy_directories() {
  dcm rm all ohne
  rm -R $USER_DIR/networks/$network_name/web/www
  mv $USER_DIR/docker/www $USER_DIR/networks/$network_name/web/www
  ln -s $USER_DIR/networks/$network_name/web/www $USER_DIR/docker/www

  rm -R $USER_DIR/networks/$network_name/web/apache2/sites-available
  cp -Rp $USER_DIR/etc/apache2/sites-available $USER_DIR/networks/$network_name/web/apache2
  cp -Rp $USER_DIR/etc/apache2/sites-enabled   $USER_DIR/networks/$network_name/web/apache2

  mv $USER_DIR/db/mysql/* $USER_DIR/networks/$network_name/mysql/data
  mv $USER_DIR/etc/mysql/my.cnf $USER_DIR/networks/$network_name/mysql/etc/my.cnf
  mv $USER_DIR/etc/mysql/conf.d/* $USER_DIR/networks/$network_name/mysql/etc/conf.d/
  mv $USER_DIR/www/logs/mysql/* $USER_DIR/networks/$network_name/mysql/logs
  chown -R 999.gisadmin $USER_DIR/networks/$network_name/mysql
  ln -s $USER_DIR/networks/$network_name/mysql/etc/my.cnf $USER_DIR/etc/mysql/my.cnf

  rm -d $USER_DIR/db/mysql/
  ln -s $USER_DIR/networks/$network_name/mysql/data $USER_DIR/db/mysql

  rm -R $USER_DIR/networks/$network_name/pgsql
  mv $USER_DIR/db/postgresql/data $USER_DIR/networks/$network_name/pgsql
  mv $USER_DIR/etc/postgresql/.pgpass $USER_DIR/networks/$network_name/pgsql/.pgpass
  mv $USER_DIR/etc/postgresql/.pgpass_gisadmin $USER_DIR/networks/$network_name/pgsql/.pgpass_gisadmin
  mv $USER_DIR/networks/$network_name/web/www/logs/pgsql/* $USER_DIR/networks/$network_name/pgsql/logs
  rm -d $USER_DIR/networks/$network_name/web/www/logs/pgsql

  rm -d $USER_DIR/db/postgresql
  ln -s $USER_DIR/networks/kvwmap_prod/pgsql $USER_DIR/db/postgresql

  rm -R $USER_DIR/proxy/letsencrypt/live
  mv $USER_DIR/etc/apache2/letsencrypt/live $USER_DIR/proxy/letsencrypt
  mv $USER_DIR/etc/apache2/letsencrypt/csr $USER_DIR/proxy/letsencrypt
  mv $USER_DIR/etc/apache2/letsencrypt/keys $USER_DIR/proxy/letsencrypt
  mv $USER_DIR/etc/apache2/letsencrypt/archive $USER_DIR/proxy/letsencrypt

  cp -Rp $USER_DIR/proxy/letsencrypt/live $USER_DIR/etc/apache2/letsencrypt/live
  cp -Rp $USER_DIR/proxy/letsencrypt/keys/ $USER_DIR/etc/apache2/letsencrypt/keys
  cp -Rp $USER_DIR/proxy/letsencrypt/csr/ $USER_DIR/etc/apache2/letsencrypt/csr
  cp -Rp $USER_DIR/proxy/letsencrypt/archive/ $USER_DIR/etc/apache2/letsencrypt/archive
}

##################################################
## Werkzeuge
##################################################

function service_config() {
  echo "Service-Config ausgeben:"
  SERVICE_NAME=$1
  NETWORK_NAME=$2
  NETWORK_PATH=${USER_DIR}/networks/${NETWORK_NAME}
  SERVICE_PATH=${NETWORK_PATH}/services/${SERVICE_NAME}
  cd ${SERVICE_PATH}
  export NETWORK_PATH
  export SERVICE_PATH
  cmd="$(compose_call)"
  cmd="${cmd} config"
  echo $cmd
  $cmd
}

function service_console() {
  param_service=$1
  param_network=$2

  if [ -z "${param_network}" ] ; then
    param_network='kvwmap_prod'
  fi

  if [ "${param_service}" = "proxy" ] ; then
    container_name='proxy_proxy'
  else
    container_name="${param_network}_${param_service}"
  fi
  cmd="docker exec -it ${container_name} bash"; echo $cmd; $cmd
}


function inspect_network() {
  docker network inspect $1
}

function inspect_container() {
  if [ -z $3 ] ; then
    echo "docker inspect ${2}_${1} $3"
    docker inspect $2_$1
        else
    echo "docker inspect ${2}_${1}  --format \"{{json .${3}}}\" | jq"
    docker inspect $2_$1 --format "{{json .${3}}}" | jq
  fi
}

function rm_container() {
  if [ -z $2 ] ; then
    echo "Entferne alle Container im Netzwerk: $1"
    cmd="docker rm $1_web $1_gdal $1_pgsql $1_mariadb $1_phpmyadmin"
  else
    echo "Entferne Container $1 im Netzwerk $2"
    cmd="docker rm $2_$1"
  fi;
  echo $cmd
  $cmd
}

function start_container() {
  if [ -z $2 ] ; then
    echo "Starte alle Container im Netzwerk: $1"
    cmd="docker start $1_web $1_gdal $1_pgsql $1_mariadb $1_phpmyadmin"
  else
    echo "Starte Container $1 im Netzwerk $2"
    cmd="docker start $2_$1"
  fi;
  echo $cmd
  $cmd
}

function ps_container() {
  if [ -z $1 ] ; then
    echo "Liste alle Container"
    docker ps -a
  else
    echo "Liste nur Container im Netzwerk $1"
    docker ps -a --filter network=$1 | sort -k 2
  fi
}

##################################################
## Proxy
##################################################
function remove_proxy_container() {
  echo "Entferne proxy Container"
  cmd="docker-compose -f ${USER_DIR}/networks/proxy/services/proxy/docker-compose.yaml rm nginx"
  echo $cmd
  $cmd
}

function stop_proxy_container() {
  if [[ -n $(docker ps -a -f status=running -f name=proxy_nginx_1 -q) ]] ; then
    echo "Stoppe proxy Container. Bitte warten ..."
    cmd="docker-compose -f ${USER_DIR}/networks/proxy/services/proxy/docker-compose.yaml stop nginx"
    echo $cmd
    $cmd
  fi
}


function reload_pgsql_container() {
  cmd="docker exec --user postgres kvwmap_prod_pgsql_1 /usr/lib/postgresql/13/bin/pg_ctl reload"
  echo "Reload PostgreSQL-Konfiguration im pgsql-Container:"
  echo $cmd
  $cmd
}

function reload_proxy_container() {
  cmd="docker exec proxy_proxy nginx -s reload"
  echo "Reload Konfiguration des proxy Containers:"
  echo $cmd
  $cmd
}

function test_proxy_container() {
  cmd="docker exec proxy_proxy nginx -t"
  echo "Teste proxy Container:"
  echo $cmd
  $cmd
}

function show_all_container_ips() {
  docker inspect -f="Container {{.Name}} IP: {{ .NetworkSettings.Networks.${network_name}.IPAddress }}" $(docker ps -aq)
}

function show_container_ip() {
  docker inspect -f="Container {{.Name}} IP: {{ .NetworkSettings.Networks.${network_name}.IPAddress }}" $1
}

function show_container_status() {
  CONTAINER=$1
  echo "Status des Containers $CONTAINER:"
  RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER 2> /dev/null)

  if [ $? -eq 1 ]; then
    echo "UNKNOWN - Container $CONTAINER does not exist."
    return 3
  fi

  if [ "$RUNNING" == "false" ]; then
    echo "CRITICAL - $CONTAINER is not running."
    return 2
  fi

  STARTED=$(docker inspect --format="{{ .State.StartedAt }}" $CONTAINER)
  NETWORK=$(docker inspect --format="{{ .NetworkSettings.IPAddress }}" $CONTAINER)

  echo "OK - $CONTAINER is running. IP: $NETWORK, StartedAt: $STARTED"
}

function remove_all_container() {
  docker ps -aq | xargs docker rm
}

function remove_all_images() {
  docker images -q | xargs docker rmi
}

function remove_all_networks() {
  docker network ls | grep kvwmap_ | cut -d" " -f1 | xargs docker network rm
  docker network rm proxy
}

function uninstall_kvwmap() {
  echo "Deinstalliere das kvwmap und dazugehörige images."
  fail_unless_root
  read -p "Wollen Sie kvwmap-server wirklich deinstallieren? (j/n)? " answer
  case ${answer:0:1} in
    j|J|y|Y )
      stop_all_services
      remove_all_container
      remove_all_images
      remove_all_netwoks

      if [ ! -z "$USER_DIR" ] ; then
        echo "Lösche Verzeichnisse networks und proxy"
        rm -RI $USER_DIR/networks
        echo "Lösche Verzeichniss kvwmap-server"
        #rm -RI $USER_DIR/kvwmap-server
      fi
      
      echo "Entferne alle erzeugten Netzwerke"
      remove_networks
      echo "So jetzt ist alles weg außer de Images. Zum Löschen der Images folgenden Befehl aufrufen:"
      echo " docker images purge' ausführen."
      echo "Zum neu installieren nach ${USER_DIR} wechseln und folgenden Befehle eingeben:"
      echo " git clone https://github.com/pkorduan/kvwmap-server.git"
      echo " kvwmap-server/dcm create service kvwmap-server"
      echo " dcm up network kvwmap_prod"
      echo "und im Browser:"
      echo " http://meineserverip/kvwmap/install.php"
    ;;
    * )
      echo "OK, nix passiert!"
    ;;
  esac
}

#----------------------------------------------
#load settings
CONFIG_KVWMAP_SERVER=/home/gisadmin/kvwmap-server/config
if [ ! -f ${CONFIG_KVWMAP_SERVER}/config ] ; then
  echo "Create config file from config/config-default"
  cp ${CONFIG_KVWMAP_SERVER}/config-default ${CONFIG_KVWMAP_SERVER}/config
  chown gisadmin.gisadmin ${CONFIG_KVWMAP_SERVER}/config
  chmod g+w ${CONFIG_KVWMAP_SERVER}/config
fi
source ${CONFIG_KVWMAP_SERVER}/config

case "$1" in

  build)
    case $2 in
      gdal)
        build_gdal_image 'latest'
      ;;
      kvwmap)
        echo "Build the image pkorduan/kvwmap-server:${KVWMAP_IMAGE_VERSION}"
        build_kvwmap_server $KVWMAP_IMAGE_VERSION
      ;;
      *)
        echo "Gebe das Image an das gebaut werden soll. gdal oder kvwmap"
      ;;
    esac
  ;;
  clean)
    echo "Lösche alle nicht genutzten Container."
    docker rm $(docker ps -q -f status=exited)
    echo "Lösche alle Images mit Namen <none>."
    docker rmi $(docker images -a | grep "^<none>" | awk '{print $3}')
    echo "Lösche alle nicht benutzten Netzwerke"
    docker network prune -f
  ;;

  config)
    service_config $2 $3
  ;;

  console)
    echo "Öffnet eine Bash-Shell im Container:"
    service_console $2 $3
  ;;

  inspect)
    case $2 in
      network)
        inspect_network $3
      ;;
      service)
        inspect_container $3 $4 $5
      ;;
    esac
  ;;

  logs)
    service_logs $2 $3
  ;;

  ip)
    case $2 in
      all)
        show_all_container_ips
      ;;
      * )
        show_service_ip $2 $3
      ;;
    esac
  ;;

  status)
    case $2 in
      all)
        docker ps -a
      ;;
      *)
        docker ps -a
      ;;
    esac
  ;;

  ps)
    ps_container $2
  ;;

  rebuild)
    case $2 in
      gdal)
        stop_gdal_container
        remove_gdal_container
        docker rmi -f $(docker images -q pkorduan/gdal-sshd)
        build_gdal_image 'latest'
        run_gdal_container
      ;;
      web)
        remove_web_container
        build_kvwmap_server $KVWMAP_IMAGE_VERSION
        run_web_container
      ;;
      *)
        stop_all_services
        remove_all_container
        build_gdal_image
        build_kvwmap_server $KVWMAP_IMAGE_VERSION
        run_all_container
      ;;
    esac
    docker images
    docker ps -a | sort -k 2
  ;;

  reload)
    case $2 in
      all)
        stop_all_services
        remove_all_container
        docker rmi -f $(docker images -q pkorduan/kvwmap-server)
        docker pull pkorduan/kvwmap-server:$KVWMAP_IMAGE_VERSION
        run_all_container
        docker images
        docker ps -a | sort -k 2
      ;;
      pgsql)
        reload_pgsql_container
      ;;
      proxy)
        reload_proxy_container
      ;;
      web)
        stop_web_container
        remove_web_container
        docker rmi -f $(docker images -q pkorduan/kvwmap-server)
        docker pull pkorduan/kvwmap-server:$KVWMAP_IMAGE_VERSION
        run_web_container
        docker images
        docker ps -a | sort -k 2
      ;;
      *)
        echo "Gib nach reload einen der folgenden Parameter ein: all oder web."
      ;;
    esac
  ;;

  install)
    if ! id "${OS_USER}" >/dev/null 2>&1; then
      echo "
      Erzeuge user: ${OS_USER} ..."
      # create user for web gis anwendung if not exists
      $OS_USER_EXISTS || adduser $OS_USER
      /usr/sbin/usermod -u 17000 $OS_USER
      /usr/sbin/groupmod -g 1700 $OS_USER
    fi

    if [ ! -f /usr/bin/docker ]; then
      install_docker
    fi

    if [ ! -f /usr/bin/docker-compose ]; then
      install_docker-compose
    fi

    case $2 in
      all)
        install_kvwmap_images
      ;;
      kvwmap)
        git config --global user.email "peter.korduan@gdi-service.de"
        git config --global user.name "Peter Korduan"
        install_kvwmap_images
      ;;
    esac
  ;;

  uninstall)
    read -p "Sollen wirklich alle Container, Images, Docker, Docker-Compose, Verzeichnisse, der gisadmin Nutzer, die Gruppen, Zabbix-Agent und sonstiges deinstalliert werden? [j|n]: " ANSWER
    case ${ANSWER:0:1} in
      j|J|y|Y )
        if id "${OS_USER}" >/dev/null 2>&1; then
          uninstall_kvwmap
          echo "
          Lösche user: ${OS_USER} ..."
          # create user for web gis anwendung if not exists
          deluser --remove-home $OS_USER
          delgroup gisadmin
        fi

        if [ -f /usr/bin/docker ]; then
          apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
          apt-get autoremove -y --purge docker-engine docker docker.io docker-ce
        fi

        if [ -f /usr/bin/docker-compose ]; then
          rm $(which docker-compose)
        fi

        if [ -f /etc/zabbix ]; then
          /etc/init.d/zabbix-agent2 stop
          apt remove zabbix-agent2
          rm -rf /etc/zabbix
        fi
  
        if [ -f /var/logs/serverlog.json ]; then
          rm /var/logs/serverlog.json
        fi
      ;;
      * )
        echo "OK, nix passiert"
      ;;
    esac
  ;;

###############################################################
## Container erstellen, starten, stoppen, entfernen
###############################################################

  create)
    case $2 in
      network)
        create_network $3
      ;;
      service)
        create_service $3 $4
      ;;
      compose)
        write_compose_file $3 $4
      ;;
    esac
  ;;
  remove)
    case $2 in
      network)
        remove_network $3
      ;;
      service)
        remove_service $3 $4
      ;;
      *)
        usage
      ;;
    esac
  ;;
  up)  #das alte run, instanziiert einen Service als Container
    case $2 in
      network)
        up_down_network $3 "up"
      ;;
      *)
        up_down_service $2 $3 "up"
    ;;
    esac
    docker ps
  ;;
  down)
    case $2 in
      network)
        up_down_network $3 "down"
      ;;
      *)
        up_down_service $2 $3 "down"
      ;;
    esac
  ;;

  start)
    if [ -z "$3" ] ; then
      param_service='kvwmap_prod'
    else
      param_service=$3
    fi
    case $2 in
      all)
        start_container $param_service
      ;;
      *)
        start_container $2 $param_service
      ;;
    esac
    docker ps -a | sort -k 2
  ;;

  stop)
    case $2 in
      all)
        stop_all_services
      ;;
      *)
        stop_service $2 $3
      ;;
    esac
    docker ps -a | sort -k 2
  ;;

  restart)
    case $2 in
      all)
        stop_services
        start_services
      ;;
      *)
        stop_service $2 $3
        start_service $2 $3
      ;;
    esac
  ;;

  rerun)
    if [ -z "$3" ] ; then
      param_service='kvwmap_prod'
    else
      param_service=$3
    fi
    case $2 in
      all)
        up_down_network $param_service "down"
        up_down_network $param_service "up"
      ;;
      *)
        up_down_service $2 $param_service "down"
        up_down_service $2 $param_service "up"
      ;;
    esac
  ;;

  run)
    if [ -z "$3" ] ; then
      param_service='kvwmap_prod'
    else
      param_service=$3
    fi
    case $2 in
      all)
        up_down_network $param_service "up"
      ;;
      *)
        up_down_service $2 $param_service "up"
      ;;
    esac
  ;;

  compose)
    case $2 in
      networks)
        write_network_compose_file
        echo "Erledigt."
      ;;
      service)
        write_compose_file $3 $4
      ;;
      *)
        usage
      ;;
    esac
  ;;
  test)
    case $2 in
    proxy)
      test_proxy_container
    ;;
    *)
      echo "Derzeit können nur folgende Container getestet werden: proxy"
      ;;
    esac
  ;;

  update)
    case $2 in
      cron)
        docker exec web /etc/cron.hourly/kvwmap
        echo "Crontab für Nutzer gisadmin im Web-Container geschrieben."
      ;;
      *)
        usage
      ;;
    esac
  ;;
  proxy)
    case $2 in
      create)
        create_service proxy proxy
      ;;
      up)
        up_down_service proxy proxy "up"
      ;;
      down)
        up_down_service proxy proxy "down"
      ;;
      reload)
        reload_proxy_container
      ;;
    esac
  ;;
  ls)
    case $2 in
      networks)
        list_networks
      ;;
      *)
        usage
      ;;
    esac
  ;;
  rm)
    if [ -z "$3" ] ; then
      param_service='kvwmap_prod'
    else
      param_service=$3
    fi
    case $2 in
      all)
        rm_container $param_service
      ;;
      *)
        rm_container $2 $param_service
      ;;
    esac
  ;;
  *)
    usage
    exit 1
  ;;
esac
