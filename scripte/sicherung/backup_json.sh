#!/bin/bash

#### Changelog ##########################################
#   #2020_01_12 GKAE    1. testen ob *.config existieren
#                       2. ln -s $BACKUP_PATH/latest
#                       3. testen ob DB-Dumps erfolgreich waren
#                       4. Schritte durchnummeriert
#                       5. LOGFILE Formatierung
#   #2020_01_14 GKAE    1. tar mit Parametern
#                       2. keine Passwörter in LOGFILE
#   #2020_01_20 GKAE    1. --single-transaction bei mysqldump um Fehler 1449 zu umgehen
#   #2020_01_25 GKAE    1. mySQL-Passwort aus credentials.php auslesen
#                       2. Variablen UPPERCASE
#                       3. rsync als Schritt 6
#                       4. ~/kvwmap-server/config/config eingebunden, für Variablen SERVER_NAME und PROD_ADD
#                       5. Umstellen auf ; separierte *.conf-Dateien
#                       6. Fehlervariablen für jeden Schritt
#                       7. interne Variablen auf local gesetzt
#   #2020_01_27         1. Debugging, Stabilisierung
#   #2020_01_29         1. shellcheck-Empfehlungen angewendet
#                       2. Monitoring noch fehlerhaft
#   #2020_02_01         1. Monitoring funktioniert nun
#   #2021_03_01		1.	Schritt 4. nur ausführen wenn $KEEP_FOR_N_DAYS > 0
#   #2021_03_03		1.	Variable PROD_APP in dump_mysql() verwenden statt des auslesens der Prod-App aus der Datei
#   #2021_03_10		1.	PROD_APP aus backup.conf auslesen
#   #2021_03_24		1.	escaping double-quotes when passing MYSQL_PASSWORD to docker exec
#   #2021_03_26		1.	correction for deleting of old files, number of days has to be prefixed with "+"
#   #2021_06_01		1.	Fork vom alten Script, neues Script liest Config aus JSON
#   #2021_06_02		1	Umstellung auf JSON
#   #2021_06_04		1.	differenzielles Backup mit tar
#   #2021_06_08		1.	mysql_dump ermittelt Host IP über Container-ID und Docker-Netzwerk
#   #2021_06_23		1	vor Backup prüfen ob genügend Platz vorhanden ist
#   #2021_06_28   	1.	".tar_differential_backup_duration" eingeführt
#                               ".tar[].exclude" eingeführt
#   #2021_07_09         1.      rm -f beim löschen von tar.difflog verwenden um Nachfragen zu vermeiden
#   #2021_08_02         1. $LOGFILE wird nicht mehr ins log.json integriert
#   #2021_08_04		1. Prüfung ob JSON-Config-Datei syntaktisch ok ist
#   #2021_08_05		1. Fixed bug im #2021_08_04
#                       2. dump_pg(),dump_mysql(),pg_dumpall_wrapper() kopieren Dumps nun aus Pfad abhängig vom Docker-Netzwerk
#   #2021_08_30         1. sichere_dir_als_targz() Zeitraum und Starttag fpr differenzielle Sicherung für alle Sicherungen gleich
#                       2. neues Flag "TAR_FULLBACKUP" im log.json
#   #2021_09_15         1. neuer Schritt: Sicherungsconfig sichern
#                       2. Systemconfig sichern
#   #2021_09_16         1. Bug in sichere_dir_als_targz() auch wenn keine diff.Sicherung definiert ist, wird bei vorhandenem tar.difflog eine gemacht
#                       2. delete_diff_tarlog() nur ausführen wenn diff.Sicherung konfiguriert
#                       3. ps Optionen -o fsavail,fsuse%  entfernt für Abwärtskompatibilität
#########################################################

#########################################################
## Variablen                                            #
#########################################################
WWW_DIR="/home/gisadmin/www"
APPS_DIR="${WWW_DIR}/apps"

# Konfiguration des Backups einbinden
CONFIG_FILE="$1"

# globale Konfiguration laden
source /home/gisadmin/kvwmap-server/config/config
export SERVER_NAME

# Fehlerflags
step_tar_error=FALSE
step_mysql_error=FALSE
step_pgsql_error=FALSE
step_rsync_error=FALSE
step_pgdumpall_error=FALSE

# TARLOG geloescht?
DELETED_TARLOG=FALSE

# DEBUG-Messages to stdout
debug=TRUE

#########################################################
## # JSON pruefen                                       #
#########################################################

dummy=$(cat $CONFIG_FILE | jq '.')
if [ $? -gt 0 ]; then
    ABORT_BACKUP=TRUE
    echo "Config-Datei ungültig!"
    exit 1
else
    ABORT_BACKUP=FALSE
fi

#########################################################
## # Verzeichnisse                                      #
#########################################################

BACKUP_FOLDER=$(cat $CONFIG_FILE | jq -r '(.backup_folder)')
BACKUP_FOLDER=$($BACKUP_FOLDER) #variable expansion for dates etc.
BACKUP_PATH=$(cat $CONFIG_FILE | jq -r '.backup_path')
BACKUP_DIR=$BACKUP_PATH/$BACKUP_FOLDER
LOGFILE=$BACKUP_DIR/sicherung.log #temporary
JSON_LOG=$BACKUP_DIR/log.json


#########################################################
## Funktionen                                           #
#########################################################

dbg() {
    if [ "$debug" = TRUE ] ; then
        echo "$1"
    fi
}

dbg "BACKUP_DIR=${BACKUP_DIR}"
dbg "BACKUP_FOLDER=${BACKUP_FOLDER}"
dbg "BACKUP_PATH=${BACKUP_PATH}"
dbg "CONFIG_FILE=${CONFIG_FILE}"
dbg "LOGFILE=${LOGFILE}"


delete_diff_tarlog(){
  dbg "entering delete_diff_tarlog()"
  local diff_duration=$(cat $CONFIG_FILE | jq -r ".differential_backup_duration // empty")

  if [ -n "$diff_duration" ]; then
    ls -alh "$source/$tarlog" >> "$LOGFILE"
    while read TARLOG
    do
      echo "tar.difflog loeschen" >> "$LOGFILE"
      DELETED_TARLOG=TRUE
      rm -f "$source/$tarlog"
    done < <(find "$1" -type f -name "$tarlog" -mtime "+$diff_duration")
  fi
  dbg "leaving delete_diff_tarlog()"
}

#Routine sichert ein Verzeichnis mit tar
sichere_dir_als_targz() {
    dbg "entering sichere_dir_als_targz $1"

    local source=$(cat $CONFIG_FILE | jq -r ".tar[$1].source")
    local target=$BACKUP_DIR/$(cat $CONFIG_FILE | jq -r ".tar[$1].target_name")
    local tar_exclude=$(cat $CONFIG_FILE | jq -r ".tar[$1].exclude // empty")
    local diff_duration=$(cat $CONFIG_FILE | jq -r ".differential_backup_duration // empty")

    local tarlog=tar.difflog

    dbg "source=$source"
    dbg "target=$target"
    dbg "diff_duration=$diff_duration"
    dbg "tar_exclude=$tar_exclude"
    dbg "diff_duration=$diff_duration"

    delete_diff_tarlog $source

    if [ -n "$tar_exclude" ]; then
        tar_exclude="--exclude="$tar_exclude
    fi

    #tar.difflog vorhanden und diff.Sicherung konfiguriert?
    if [ -f "$source/$tarlog" ] && [ -n "$diff_duration" ];  then
        mtime=$(stat -c "%y" "$source/$tarlog")
        cp "$source/$tarlog" "$source/$tarlog"_tmp
        dbg "Tarlog gefunden, mtime=$mtime"

        tar $tar_exclude -cf $target -g $source/$tarlog $source > /dev/null 2>> "$LOGFILE"

        if [[ $? -eq 0 ]]; then
            echo "Verzeichnis $source nach $target gesichert" >> "$LOGFILE"
        else
            echo "Verzeichnis $source konnte nicht gesichert werden" >> "$LOGFILE"
            return 1
        fi

        if [ -f "$source/$tarlog"_tmp ]; then
            mv "$source/$tarlog"_tmp "$source/$tarlog"
            touch -d "$mtime" "$source/$tarlog"
        fi

    else
        mtime=
        echo "kein tar.difflog gefunden, mache Vollsicherung" >> "$LOGFILE"
        dbg "Kein Tarlog, Vollsicherung"

        echo "Sichere Verzeichnis $source nach $target" >> "$LOGFILE"
        tar $tar_exclude -cf $target $source > /dev/null 2>> "$LOGFILE"

    fi

    if [[ $? -eq 0 ]]; then
        echo "Verzeichnis $source nach $target gesichert" >> "$LOGFILE"
    else
        echo "Verzeichnis $source konnte nicht gesichert werden" >> "$LOGFILE"
        return 1
    fi
    dbg "leaving sichere_dir_als_targz"
}

dump_pg() {
    dbg "entering dump_pg $1"
    local database=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].db_name")
    local container_id=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].container_id")
    local db_user=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].db_user")
    local target_name=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].target_name")
    local docker_network=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].docker_network")

#    local pg_dump_inserts=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].pg_dump_inserts")
#    local pg_dump_column_inserts=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].pg_dump_column_inserts")
#    local pg_dump_in_exclude_schemas=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].pg_dump_in_exclude_schemas")
#    local pg_dump_schemas=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].pb_dump_schemas")
#    local pg_dump_in_exclude_tables=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].pg_dump_in_exclude_tables")
#    local pg_dump_tables=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].pg_dump_tables")
#    local pg_dump_parameter=$(cat $CONFIG_FILE | jq -r ".pg_dump[$1].pg_dump_parameter")

    dbg "database=$database"
    dbg "container_id=$container_id"
    dbg "db_user=$db_user"
    dbg "target_name=$target_name"
    dbg "docker_network=$docker_network"

    docker exec $container_id bash -c "pg_dump -Fc -U $db_user -f /var/lib/postgresql/data/$target_name $database" 2>> "$LOGFILE"

    if [[ -z $docker_network ]]; then
        dbg "ohne Docker-Netzwerk"
        pg_dump_data_dir=/home/gisadmin/db/postgresql/data/
    else
        dbg "mit Docker-Netzwerk"
        pg_dump_data_dir=/home/gisadmin/networks/"$docker_network"/pgsql/data
    fi

    if [[ $? -eq 0 ]]; then
        echo "PG-Dump erfolgreich für $database" >> "$LOGFILE"
        mv "$pg_dump_data_dir"/"$target_name" "$BACKUP_DIR" >> "$LOGFILE"
    else
        echo "FEHLER: PG-Dump nicht erfolgreich!" >> "$LOGFILE"
        echo "docker exec pgsql-server bash -c pg_dump -Fc -U kvwmap -f /var/lib/postgresql/data/$target_name $database" >> "$LOGFILE"
        return 1
    fi
    dbg "leaving dump_pg"
}

dump_mysql() {
    dbg "entering dump_mysql $1"
    local db_name=$(cat $CONFIG_FILE | jq -r ".mysql_dump[$1].db_name")
    local target_name=$(cat $CONFIG_FILE | jq -r ".mysql_dump[$1].target_name")
    container_id=$(cat $CONFIG_FILE | jq -r ".mysql_dump[$1].container_id")
#    local mysql_dump_parameter=$(cat $CONFIG_FILE | jq ".mysql_dump[$1].mysql_dump_parameter")
    docker_network=$(cat $CONFIG_FILE | jq -r ".mysql_dump[$1].docker_network // empty")

    dbg "db_name=$db_name"
    dbg "target_name=$target_name"
    dbg "container_id=$container_id"
    dbg "docker_network=$docker_network"

    if [[ -z $docker_network ]]; then
        dbg "ohne Docker-Netzwerk"
        mysql_host=$(docker inspect --format "{{.NetworkSettings.IPAddress}}" $container_id)
        mysql_data_dir=/home/gisadmin/db/mysql/
    else
        dbg "mit Docker-Netzwerk"
        mysql_host=$(docker inspect --format "{{json .}}" $container_id | jq -r ".NetworkSettings.Networks.${docker_network}.IPAddress")
        mysql_data_dir=/home/gisadmin/networks/"$docker_network"/mysql/data
    fi

    if [ -f "$APPS_DIR"/"$PROD_APP"/credentials.php ]; then

        local MYSQLUSER=$(grep MYSQL_USER "$APPS_DIR"/"$PROD_APP"/credentials.php | cut -d "'" -f 4)
        local MYSQLPW=$(grep MYSQL_PASSWORD "$APPS_DIR"/"$PROD_APP"/credentials.php | cut -d "'" -f 4)

        dbg "mysql_host=$mysql_host"
        dbg "MYSQLUSER=$MYSQLUSER"
        dbg "MYSQLPW=$MYSQLPW"

        docker exec "$container_id" bash -c "mysqldump -h $mysql_host --single-transaction --user=$MYSQLUSER --databases $db_name --password=\"$MYSQLPW\" > /var/lib/mysql/$target_name" 2>> "$LOGFILE"

        if [[ $? -eq 0 ]]; then
            echo "mySQL-Dump von $MYSQLDB erfolgreich" >> "$LOGFILE"
            mv "$mysql_data_dir"/"$target_name" "$BACKUP_DIR" >> "$LOGFILE"
        else
            echo "FEHLER: mySQL-Dump nicht erfolgreich!" >> "$LOGFILE"
            return 1
        fi
    else
        echo "FEHLER: Datei mit mySQL-Credentials nicht vorhanden! DB $MYSQLDB wird nicht gesichert." >> "$LOGFILE"
        return 1
    fi
    dbg "leaving dump_mysql"
}

rsync_wrapper() {
    dbg "entering rsync_wrapper $1"
    local RS_SOURCE=$(cat $CONFIG_FILE | jq -r ".rsync[$1].source")
    local RS_TARGET=$(cat $CONFIG_FILE | jq -r ".rsync[$1].destination")
    local RS_PARAMETER=$(cat $CONFIG_FILE | jq -r ".rsync[$1].parameter")
    local EXEC_RSYNC="rsync -avz $RS_PARAMETER $RS_SOURCE $RS_TARGET"

    dbg "RS_SOURCE=$RS_SOURCE"
    dbg "RS_TARGET=$RS_TARGET"
    dbg "RS_PARAMETER=$RS_PARAMETER"
    dbg "EXEC_RSYNC=$EXEC_RSYNC"

    eval "$EXEC_RSYNC" >> "$LOGFILE"

    if [[ $? -eq 0 ]]; then
        echo "rsync von $RS_SOURCE nach $RS_TARGET erfolgreich " >> "$LOGFILE"
    else
        echo "Fehler bei $EXEC_RSYNC" >> "$LOGFILE"
        return 1
    fi
    dbg "leaving rsync_wrapper"
}

pg_dumpall_wrapper(){
    dbg "entering pg_dumpall_wrapper $1"
    local container_id=$(cat $CONFIG_FILE | jq -r ".pg_dumpall[$1].container_id")
    local db_user=$(cat $CONFIG_FILE | jq -r ".pg_dumpall[$1].db_user")
    local db_name=$(cat $CONFIG_FILE | jq -r ".pg_dumpall[$1].db_name")
    local target_name=$(cat $CONFIG_FILE | jq -r ".pg_dumpall[$1].target_name")
    local pg_dumpall_parameter=$(cat $CONFIG_FILE | jq -r ".pg_dumpall[$1].pg_dumpall_parameter")
    local docker_network=$(cat $CONFIG_FILE | jq -r ".pg_dumpall[$1].docker_network")

    dbg "container_id=$container_id"
    dbg "db_user=$db_user"
    dbg "db_name=$db_name"
    dbg "target_name=$target_name"
    dbg "pg_dumpall_parameter=$pg_dumpall_parameter"

    docker exec $container_id bash -c "pg_dumpall -U $db_user -l $db_name ${pg_dumpall_parameter} -f /var/lib/postgresql/data/$target_name"

    if [[ -z $docker_network ]]; then
        dbg "ohne Docker-Netzwerk"
        pg_dump_data_dir=/home/gisadmin/db/postgresql/data/
    else
        dbg "mit Docker-Netzwerk"
        pg_dump_data_dir=/home/gisadmin/networks/"$docker_network"/pgsql/data
    fi

    if [[ $? -eq 0 ]]; then
        echo "pg_dumpall erfolgreich" >> "$LOGFILE"
        mv /home/gisadmin/db/postgresql/data/"$target_name" "$BACKUP_DIR" >> "$LOGFILE"
    else
        echo "FEHLER: pg_dumpall nicht erfolgreich!" >> "$LOGFILE"
        return 1
    fi

    dbg "leaving pg_dumpall_wrapper"
}

#########################################################
## Start                                                #
#########################################################
mkdir -p "$BACKUP_DIR"
echo "----------- Starte Backup $(date +"%d.%m.%Y %H:%M:%S") ----------" >> "$LOGFILE"
echo "verwendete Konfiguration: ${CONFIG_DIR}" >> "$LOGFILE"
echo "Sicherungsverzeichnis: ${BACKUP_DIR}" >> "$LOGFILE"
timestamp_backup_start=$(date +"%s")

#########################################################
## # Speicherplatz prüfen                               #
#########################################################
if [ "$ABORT_BACKUP" = FALSE ]; then
    if [ -d "$BACKUP_PATH"/latest ]; then
        size_latest_backup=$(du -s "$BACKUP_PATH"/latest/ | cut -d$'\t' -f 1)
        df_size=$(df "$BACKUP_PATH"/latest/ | awk 'NR>1{print $4}')
        echo "Größe letzte Sicherung: $size_latest_backup" >> "$LOGFILE"
        echo "Verfügbarer Speicherplatz: $df_size" >> "$LOGFILE"
        if  [ $df_size -lt $size_latest_backup ]; then
            echo "Nicht genügend Speicherplatz vorhanden. Backup wird abgebrochen!" >> "$LOGFILE"
            ABORT_BACKUP=TRUE
        else
            ABORT_BACKUP=FALSE
        fi
    else
        ABORT_BACKUP=FALSE
    fi
fi

if [ "$ABORT_BACKUP" = FALSE ]; then
    #########################################################
    ## #1 Vereichnisse sichern                              #
    #########################################################
    TAR_COUNT=$(cat $CONFIG_FILE | jq '.tar | length')
    if (( $TAR_COUNT > 0 )); then
        echo "1/7 Verzeichnisse werden gesichert" >> "$LOGFILE"
        for (( i=0; i < $TAR_COUNT; i++ )); do
            sichere_dir_als_targz $i
            if [[ ! $? -eq 0 ]]; then
                step_tar_error=TRUE
                dbg "step_tar_error=$step_tar_error"
            fi
        done
    else
        echo "1/7 keine zu sicherenden Verzeichnisse" >> "$LOGFILE"
    fi

    #########################################################
    ## #2 PG-DBs sichern                                    #
    #########################################################
    PGDUMP_COUNT=$(cat $CONFIG_FILE | jq '.pg_dump | length')
    if (( $PGDUMP_COUNT > 0 )); then
        echo "2/7 postgreSQL-Datenbanken werden gesichert" >> "$LOGFILE"
        for (( i=0; i < $PGDUMP_COUNT; i++ )); do
            dump_pg $i
            if [[ ! $? -eq 0 ]]; then
                step_pgsql_error=TRUE
                dbg "step_pgsql_error=$step_pgsql_error"
            fi
        done
    else
        echo "2/7 keine zu sichernden PG-Datenbanken" >> "$LOGFILE"
    fi

    #########################################################
    ## #3 pg_dumpall                                        #
    #########################################################
    PGDUMPALL_COUNT=$(cat $CONFIG_FILE | jq -r '.pg_dumpall | length')
    if (( $PGDUMPALL_COUNT > 0 )); then
        echo "3/7 Postgres-Dumpall ausfuehren" >> "$LOGFILE"
        for (( i=0; i<$PGDUMPALL_COUNT; i++ )); do
            pg_dumpall_wrapper $i
            if [[ ! $? -eq 0 ]]; then
                step_pgdumpall_error=TRUE
                dbg "step_rsync_error=$step_rsync_error"
            fi
        done
    else
        echo "3/7 Postgres-Dumpall keine Konfiguration" >> "$LOGFILE"
    fi

    #########################################################
    ## #4 mySQL-DBs sichern                                 #
    #########################################################
    MYSQLDUMP_COUNT=$(cat $CONFIG_FILE | jq '.mysql_dump | length')
    if (( $MYSQLDUMP_COUNT > 0 )); then
        echo "4/7 mySQL-Datenbanken werden gesichert" >> "$LOGFILE"
        for (( i=0; i < $MYSQLDUMP_COUNT; i++ )); do
            dump_mysql $i
            if [[ ! $? -eq 0 ]]; then
                step_mysql_error=TRUE
                dbg "step_mysql_error=$step_mysql_error"
            fi
        done
    else
        echo "4/7 keine zu sicherenden mySQL-Datenbanken" >> "$LOGFILE"
    fi


    #########################################################
    ## #5 rsync                                             #
    #########################################################
    RSYNC_COUNT=$(cat $CONFIG_FILE | jq -r '.rsync | length')
    if [ $RSYNC_COUNT -gt 0 ]; then
        echo "5/7 Dateien/Ordner mit rsync übertragen" >> "$LOGFILE"
        for (( i=0; i<$RSYNC_COUNT; i++)); do
            rsync_wrapper "$i"
            if [[ ! $? -eq 0 ]]; then
                step_rsync_error=TRUE
                dbg "step_rsync_error=$step_rsync_error"
            fi
        done
    else
        echo "5/7 keine rsync-Konfiguration vorhanden" >> "$LOGFILE"
    fi

    #########################################################
    ## #6 alte löschen                                      #
    #########################################################
    KEEP_FOR_N_DAYS=$(cat $CONFIG_FILE | jq -r '.delete_after_n_days')
    if [ $KEEP_FOR_N_DAYS -gt 0 ]; then
        echo "6/7 Backups älter als $KEEP_FOR_N_DAYS Tage werden gelöscht" >> "$LOGFILE"
        find "$BACKUP_PATH"/* -type d -mtime "+$KEEP_FOR_N_DAYS" -exec rm -fdr {} \;
    else
        echo "6/7 alte Backups werden nicht gelöscht, Parameter KEEP_FOR_N_DAYS=0"
    fi

    #########################################################
    ## #7 Sicherungsconfig sichern                          #
    #########################################################
    cp $CONFIG_FILE $BACKUP_DIR

    #########################################################
    ## #8 Systemzustand sichern                             #
    #########################################################
    #laufende Prozesse
    ps -eo pid,user,cmd,%mem,%cpu,etime,euser,egroup,ni > "$BACKUP_DIR"/systemstate.log
    #Speicher
    lsblk -o name,size,ro,type,mountpoint,uuid,owner,group,tran >> "$BACKUP_DIR"/systemstate.log
    #Docker Container
    docker inspect  $(docker ps -aq) >> "$BACKUP_DIR"/systemstate.log
    #user+gruppen
    cat /etc/passwd >>  "$BACKUP_DIR"/systemstate.log
    cat /etc/group >>  "$BACKUP_DIR"/systemstate.log

fi #ABORT_BACKUP ?

#########################################################
## #9 Symlink setzen                                    #
#########################################################
echo "7/7 aktualisiere Sym-Link $BACKUP_PATH/latest auf aktuelles Sicherungsverzeichnis" >> "$LOGFILE"
rm "$BACKUP_PATH"/latest >> "$LOGFILE"
ln -s "$BACKUP_DIR" "$BACKUP_PATH"/latest >> "$LOGFILE"


#########################################################
## #10 Monitoring-Log schreiben                          #
#########################################################

size_of_backup=$(du -s "$BACKUP_DIR" | cut -f 1 -d$'\t') #am Tabulator trennen

echo "----------- Backup um $(date +"%d.%m.%Y %H:%M:%S") beendet ----------" >> "$LOGFILE"

(
cat << EOF
{"CONFIG_FILE":"$CONFIG_FILE",
"BACKUP_DIR":"$BACKUP_DIR",
"BACKUP_START":"$timestamp_backup_start",
"BACKUP_END":"$(date +"%s")",
"TAR_ERROR":"$step_tar_error",
"MYSQL_ERROR":"$step_mysql_error",
"PGDUMP_ERROR":"$step_pgsql_error",
"PGDUMPALL_ERROR":"$step_pgsql_error",
"RSYNC_ERROR":"$step_rsync_error",
"SIZE_OF_BACKUP":"$size_of_backup",
"TAR_FULLBACKUP":"$DELETED_TARLOG"
EOF
)                > "$JSON_LOG"
#cat "$LOGFILE"  >> "$JSON_LOG"
echo "}"      >> "$JSON_LOG"

#rm "$LOGFILE"

exit 0
