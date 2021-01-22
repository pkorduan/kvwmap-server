#!/bin/bash

#### Changelog ##########################################
#   #2020_01_12 GKAE    1. testen ob *.config existieren
#                       2. ln -s $backup_path/latest
#                       3. testen ob DB-Dumps erfolgreich waren
#                       4. Schritte durchnummeriert
#                       5. logfile Formatierung
#   #2020_01_14 GKAE    1. tar mit Parametern
#                       2. keine Passwörter in Logfile
#   #2020_01_20 GKAE    1. --single-transaction bei mysqldump um Fehler 1449 zu umgehen
#   #2020_01_22 GKAE    1. mySQL-Passwort aus credentials.php auslesen
#########################################################



#########################################################
## Variablel                                            #
#########################################################
sicherung_id=$1
dbpasswort=Columbidae_Taube1

# Pfad dieses Scriptes bestimmen
real=$(realpath $0)
script_pfad=$(dirname $real)

WWW_DIR="/home/gisadmin/www"
APPS_DIR="${WWW_DIR}/apps"

# Konfiguration des Backups einbinden
config_dir=$script_pfad/$1
source $config_dir/backup.conf
export backup_path
export backup_folder
export keep_for_n_days

backup_dir=$backup_path/$backup_folder
logfile=$backup_dir/sicherung.log
#########################################################
## Funktionen                                           #
#########################################################

schreibe_sicherung() {
    ftp_backup_dir=/mnt/ftp_backup/day/${current_day}
    echo "    Schreibe Sicherung ${current_day_dir} nach ${ftp_backup_dir}" >> $logfile
    mkdir -p $ftp_backup_dir
    cp $current_day_dir/* $ftp_backup_dir >> $logfile
}

load_pg_log() {
    pg_logfile=/var/www/logs/pgsql/pgsql-$(date -d "yesterday" '+%Y-%m-%d').csv
    if [ -f $pg_logfile ]; then
        echo "    Befehl: psql -h $PGSQL_SERVER -U kvwmap -c \"COPY postgres_log FROM '${pg_logfile}' WITH csv\" postgres;"
        result=$(psql -h $PGSQL_SERVER -U kvwmap -c "COPY postgres_log FROM '${pg_logfile}' WITH csv" postgres)
        if [[ "$result" == *"COPY "* ]] ; then
            gzip $pg_logfile
        fi
  fi
}

#Routine sichert eine Verzeichnis als *.tar.gz
sichere_dir_als_targz() {
    source=$1
    target=${backup_dir}/${2}.tar.gz
    parameter=$3
    echo "    Sichere Verzeichnis ${source} nach ${target}" >> $logfile
    tar $3 cvfz "$target" "$source" > /dev/null 2>> $logfile
}

#Routine sichert die übergebene Postgre-DB nach $current_day_dir
dump_pg() {
    database=$1
    target_name=$2.dump
    echo "    Sichere PG-Datenbank $database in Datei $target_name" >> $logfile
    echo "    pg_dump -Fc -U kvwmap -f /var/lib/postgresql/data/$target_name $database" &>> $logfile
    docker exec pgsql-server bash -c "pg_dump -Fc -U kvwmap -f /var/lib/postgresql/data/$target_name $database" &>> $logfile

    if [[ $? -eq 0 ]]; then
        echo "    PG-Dump erfolgreich" >> $logfile
        mv /home/gisadmin/db/postgresql/data/$target_name $backup_dir >> $logfile
    else
        echo "    FEHLER: PG-Dump nicht erfolgreich!" >> $logfile
    fi

}

dump_mysql() {
    MYSQLDB=$1
    target_name=$2.dump
    APPNAME=$3
    MYSQLHOST=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' mysql-server)
    MYSQLUSER=$(grep MYSQL_USER $APPS_DIR/$APPNAME/credentials.php | cut -d "'" -f 2)
    MYSQLPW=$(grep MYSQL_PASSWORD $APPS_DIR/$APPNAME/credentials.php | cut -d "'" -f 2)

    echo "    Sichere mySQL-Datenbank $MYSQLDB in Datei $target_name" >> $logfile
    echo "    mysqldump -h $MYSQLHOST --user=kvwmap --databases $MYSQLDB --password=secret > /var/lib/mysql/$target_name" >> $logfile
    docker exec mysql-server bash -c "mysqldump -h $MYSQLHOST --single-transaction --user=$MYSQLUSER --databases $MYSQLDB --password="$MYSQLPW" > /var/lib/mysql/$target_name" &>> $logfile    
    if [[ $? -eq 0 ]]; then
        echo "    mySQL-Dump erfolgreich" >> $logfile
        mv /home/gisadmin/db/mysql/$target_name $backup_dir >> $logfile
    else
        echo "    FEHLER: mySQL-Dump nicht erfolgreich!" >> $logfile
    fi

}

#########################################################
## Start                                                #
#########################################################
mkdir -p $backup_dir
echo "----------- Starte Backup `date +"%d.%m.%Y %H:%M:%S"` ----------" >> $logfile
echo "    verwendete Konfiguration: ${config_dir}" >> $logfile
echo "    Sicherungsverzeichnis: ${backup_dir}" >> $logfile

#########################################################
## #1 Vereichnisse sichern                              #
#########################################################

if [ -f "$config_dir/dirs.conf" ]; then
    echo "1/5   Verzeichnisse werden gesichert" >> $logfile
    cat $config_dir/dirs.conf | while read dir 
    do
      sichere_dir_als_targz $dir
    done
else
    echo "1/5   keine zu sicherenden Verzeichnisse" >> $logfile
fi

#########################################################
## #2 PG-DBs sichern                                    #
#########################################################
if [ -f "$config_dir/pg_dbs.conf" ]; then
    echo "2/5   postgreSQL-Datenbanken werden gesichert" >> $logfile
    cat $config_dir/pg_dbs.conf | while read db
    do
      dump_pg $db
    done
else
    echo "2/5   keine zu sichernden PG-Datenbanken" >> $logfile
fi

#########################################################
## #3 mySQL-DBs sichern                                 #
#########################################################
if [ -f "$config_dir/mysql_dbs.conf" ]; then
    echo "3/5   mySQL-Datenbanken werden gesichert" >> $logfile
    cat $config_dir/mysql_dbs.conf | while read db
    do
      dump_mysql $db
    done
else
    echo "3/5   keine zu sicherenden mySQL-Datenbanken" >> $logfile
fi

#########################################################
## #4 alte löschen                                      #
#########################################################
echo "4/5   Backups älter als $keep_for_n_days Tage werden gelöscht" >> $logfile
find $backup_path/* -type d -mtime $keep_for_n_days -exec rm -fdr {} \;

#########################################################
## #5 Symlink setzen                                    #
#########################################################
echo "5/5   aktualisiere Sym-Link auf $backup_path/latest" >> $logfile
rm $backup_path/latest >> $logfile
ln -s $backup_dir $backup_path/latest >> $logfile

#########################################################
## #6 rsync                                             #
#########################################################
##TODO##


#schreibe_sicherung

#chmod -R g+w ${current_day_dir}

#load_pg_log

echo "----------- Backup um `date +"%d.%m.%Y %H:%M:%S"` beendet ----------" >> $logfile

exit 0
