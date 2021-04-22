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
#########################################################

#########################################################
## Variablen                                            #
#########################################################
WWW_DIR="/home/gisadmin/www"
APPS_DIR="${WWW_DIR}/apps"

# Konfiguration des Backups einbinden
CONFIG_DIR="$1"
source "$CONFIG_DIR"/backup.conf
export BACKUP_PATH
export BACKUP_FOLDER
export KEEP_FOR_N_DAYS
export PROD_APP

# globale Konfiguration laden
source /home/gisadmin/kvwmap-server/config/config
export SERVER_NAME

# Fehlerflags
step_tar_error=FALSE
step_mysql_error=FALSE
step_pgsql_error=FALSE
step_rsync_error=FALSE

# DEBUG-Messages to stdout?
debug=FALSE

# Verzeichnisse
BACKUP_DIR=$BACKUP_PATH/$BACKUP_FOLDER
LOGFILE=$BACKUP_DIR/sicherung.log
MONITOR_LOG=$BACKUP_PATH/monitor.log

#########################################################
## Funktionen                                           #
#########################################################

dbg() {

    if [ "$debug" = TRUE ] ; then
        echo "$1"
    fi
}

#Routine sichert ein Verzeichnis als *.tar.gz
sichere_dir_als_targz() {
    dbg "entering sichere_dir_als_targz $1"
    local source=$(echo "$1" | cut -d ";" -f 1)
    local target=${BACKUP_DIR}/$(echo "$1" | cut -d ";" -f 2)
    local parameter=$(echo "$1" | cut -d ";" -f 3)
    echo "    Sichere Verzeichnis $source nach $target" >> "$LOGFILE"
    tar "$parameter" -cf $target $source > /dev/null 2>> "$LOGFILE"

    if [[ $? -eq 0 ]]; then
        echo "    Vrzeichnis $source gesichert" >> "$LOGFILE"
    else
        echo "    Verzeichnis $source konnte nicht gesichert werden" >> "$LOGFILE"
        echo "    tar "$parameter" -cf $target $source" >> "$LOGFILE"
        return 1
    fi
    dbg "leaving sichere_dir_als_targz"
}

dump_pg() {
    dbg "entering dump_pg $1"
    local database=$(echo "$1" | cut -d ";" -f 1)
    local target_name=$(echo "$1" | cut -d ";" -f 2)
    local pgdump_options=$(echo "$1" | cut -d ";" -f 3)

    docker exec pgsql-server bash -c "pg_dump -Fc -U kvwmap -f /var/lib/postgresql/data/$target_name $database" 2>> "$LOGFILE"

    if [[ $? -eq 0 ]]; then
        echo "    PG-Dump erfolgreich für $database" >> "$LOGFILE"
        mv /home/gisadmin/db/postgresql/data/"$target_name" "$BACKUP_DIR" >> "$LOGFILE"
    else
        echo "    FEHLER: PG-Dump nicht erfolgreich!" >> "$LOGFILE"
        echo "    docker exec pgsql-server bash -c \"pg_dump -Fc -U kvwmap -f /var/lib/postgresql/data/$target_name $database\"" >> "$LOGFILE"
        return 1
    fi
    dbg "leaving dump_pg"
}

dump_mysql() {
    dbg "entering dump_mysql $1"
    local MYSQLDB=$(echo "$1" | cut -d ";" -f 1)
    local target_name=$(echo "$1" | cut -d ";" -f 2)

    if [ -f "$APPS_DIR"/"$PROD_APP"/credentials.php ]; then

        local MYSQLHOST=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' mysql-server)
        local MYSQLUSER=$(grep MYSQL_USER "$APPS_DIR"/"$PROD_APP"/credentials.php | cut -d "'" -f 4)
        local MYSQLPW=$(grep MYSQL_PASSWORD "$APPS_DIR"/"$PROD_APP"/credentials.php | cut -d "'" -f 4)

        docker exec mysql-server bash -c "mysqldump -h $MYSQLHOST --single-transaction --user=$MYSQLUSER --databases $MYSQLDB --password=\"$MYSQLPW\" > /var/lib/mysql/$target_name" 2>> "$LOGFILE"

        if [[ $? -eq 0 ]]; then
            echo "    mySQL-Dump von $MYSQLDB erfolgreich" >> "$LOGFILE"
            mv /home/gisadmin/db/mysql/"$target_name" "$BACKUP_DIR" >> "$LOGFILE"
        else
            echo "    FEHLER: mySQL-Dump nicht erfolgreich!" >> "$LOGFILE"
            echo "    mysqldump -h $MYSQLHOST --user=$MYSQLUSER --databases $MYSQLDB --password=*** > /var/lib/mysql/$target_name" >> "$LOGFILE"
            return 1
        fi
    else
        echo "    FEHLER: Datei mit mySQL-Credentials nicht vorhanden! DB $MYSQLDB wird nicht gesichert." >> "$LOGFILE"
        return 1
    fi
    dbg "leaving dump_mysql"
}

rsync_wrapper() {
    dbg "entering rsync_wrapper $1"
    local RS_SOURCE=$(echo "$1" | cut -d ";" -f 1)
    local RS_TARGET=$(echo "$1" | cut -d ";" -f 2)
    local RS_PARAMETER=$(echo "$1" | cut -d ";" -f 3)
    local EXEC_RSYNC="rsync -avz $RS_PARAMETER $RS_SOURCE $RS_TARGET"

    eval "$EXEC_RSYNC" 2>> "$LOGFILE"
    if [[ $? -eq 0 ]]; then
        echo "    rsync von $RS_SOURCE nach $RS_TARGET erfolgreich " >> "$LOGFILE"
    else
        echo "    Fehler bei $EXEC_RSYNC" >> "$LOGFILE"
        return 1
    fi
    dbg "leaving rsync_wrapper"
}

#########################################################
## Start                                                #
#########################################################
mkdir -p "$BACKUP_DIR"
echo "----------- Starte Backup $(date +"%d.%m.%Y %H:%M:%S") ----------" >> "$LOGFILE"
echo "    verwendete Konfiguration: ${CONFIG_DIR}" >> "$LOGFILE"
echo "    Sicherungsverzeichnis: ${BACKUP_DIR}" >> "$LOGFILE"
timestamp_backup_start=$(date +"%s")

#########################################################
## #1 Vereichnisse sichern                              #
#########################################################

if [ -f "$CONFIG_DIR/dirs.conf" ]; then
    echo "1/6   Verzeichnisse werden gesichert" >> "$LOGFILE"
    while read dir
    do
        sichere_dir_als_targz "$dir"
        if [[ ! $? -eq 0 ]]; then
            step_tar_error=TRUE
            dbg "step_tar_error=$step_tar_error"
        fi
    done<"$CONFIG_DIR"/dirs.conf
else
    echo "1/6   keine zu sicherenden Verzeichnisse" >> "$LOGFILE"
fi

#########################################################
## #2 PG-DBs sichern                                    #
#########################################################
if [ -f "$CONFIG_DIR/pg_dbs.conf" ]; then
    echo "2/6   postgreSQL-Datenbanken werden gesichert" >> "$LOGFILE"
    while read db
    do
        dump_pg "$db"
        if [[ ! $? -eq 0 ]]; then
            step_pgsql_error=TRUE
            dbg "step_pgsql_error=$step_pgsql_error"
        fi
    done<"$CONFIG_DIR"/pg_dbs.conf
else
    echo "2/6   keine zu sichernden PG-Datenbanken" >> "$LOGFILE"
fi

#########################################################
## #3 mySQL-DBs sichern                                 #
#########################################################
if [ -f "$CONFIG_DIR/mysql_dbs.conf" ]; then
    echo "3/6   mySQL-Datenbanken werden gesichert" >> "$LOGFILE"
    while read db
    do
        dump_mysql "$db"
        if [[ ! $? -eq 0 ]]; then
            step_mysql_error=TRUE
            dbg "step_mysql_error=$step_mysql_error"
        fi
    done<"$CONFIG_DIR"/mysql_dbs.conf
else
    echo "3/6   keine zu sicherenden mySQL-Datenbanken" >> "$LOGFILE"
fi

#########################################################
## #4 alte löschen                                      #
#########################################################
if [ $KEEP_FOR_N_DAYS -gt 0 ]; then
	echo "4/6   Backups älter als $KEEP_FOR_N_DAYS Tage werden gelöscht" >> "$LOGFILE"
	find "$BACKUP_PATH"/* -type d -mtime "+$KEEP_FOR_N_DAYS" -exec rm -fdr {} \;
else
	echo "4/6   alte Backups werden nicht gelöscht, Parameter KEEP_FOR_N_DAYS=0"
fi

#########################################################
## #5 Symlink setzen                                    #
#########################################################
echo "5/6   aktualisiere Sym-Link $BACKUP_PATH/latest auf aktuelles Sicherungsverzeichnis" >> "$LOGFILE"
rm "$BACKUP_PATH"/latest >> "$LOGFILE"
ln -s "$BACKUP_DIR" "$BACKUP_PATH"/latest >> "$LOGFILE"

#########################################################
## #6 rsync                                             #
#########################################################
if [ -f "$CONFIG_DIR/rsync.conf" ]; then
    echo "6/6   Dateien/Ordner mit rsync übertragen" >> "$LOGFILE"
    while read conf
    do
        rsync_wrapper "$conf"
        if [[ ! $? -eq 0 ]]; then
            step_rsync_error=TRUE
            dbg "step_rsync_error=$step_rsync_error"
        fi
    done<"$CONFIG_DIR"/rsync.conf
else
    echo "6/6   keine rsync-Konfiguration vorhanden" >> "$LOGFILE"
fi

#########################################################
## #7 Monitoring-Log schreiben                          #
#########################################################
size_of_backup=$(du -s "$BACKUP_DIR" | cut -f 1 -d$'\t') #am Tabulator trennen
echo "$CONFIG_DIR;$BACKUP_DIR;$timestamp_backup_start;$step_tar_error;$step_mysql_error;$step_pgsql_error;$step_rsync_error;$size_of_backup" >> "$MONITOR_LOG"

echo "----------- Backup um $(date +"%d.%m.%Y %H:%M:%S") beendet ----------" >> "$LOGFILE"

exit 0
