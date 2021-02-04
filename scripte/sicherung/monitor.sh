#!/bin/bash

config_dir="/home/gisadmin/etc/sicherung"
debug=false

dbg(){
    if [ "$debug" = TRUE ]; then
        echo "$1"
    fi
}

get_sicherungen_csv(){
    echo_csv=""
    linenumber=0

    while read dir
    do
        ((linenumber++))
        sicherung_name=${dir##*/}
        if [ $linenumber -eq 1 ]; then
            echo_csv="$sicherung_name"
        else
            echo_csv="$echo_csv;$sicherung_name"
        fi
    done < <(find $config_dir -maxdepth 1 -mindepth 1 -type d)
    echo "$echo_csv"
}

load_sicherung_context(){
    sicherung_id=$1
    source "$config_dir/$sicherung_id/backup.conf"
    config_with_dirs=false
    config_with_mysql=false
    config_with_pgsql=false
    config_with_rsync=false
    if [ -f "$config_dir/$sicherung_id/dirs.conf" ]; then
        config_with_dirs=true
    fi
    if [ -f "$config_dir/$sicherung_id/mysql_dbs.conf" ]; then
        config_with_mysql=true
    fi
    if [ -f "$config_dir/$sicherung_id/pg_dbs.conf" ]; then
        config_with_pgsql=true
    fi
    if [ -f "$config_dir/$sicherung_id/rsync.conf" ]; then
        config_with_rsync=true
    fi
    monitorlog=$(tail --lines=1 $BACKUP_PATH/monitor.log)
    last_execution_path=$(echo "$monitorlog" | cut -d ";" -f 2)
    last_execution_unix_timestamp=$(echo "$monitorlog" | cut -d ";" -f 3)
    last_execution_size=$(echo "$monitorlog" | cut -d ";" -f 8)
    last_execution_error_tar=$(echo "$monitorlog" | cut -d ";" -f 4)
    last_execution_error_mysql=$(echo "$monitorlog" | cut -d ";" -f 5)
    last_execution_error_pgsql=$(echo "$monitorlog" | cut -d ";" -f 6)
    last_execution_error_rsync=$(echo "$monitorlog" | cut -d ";" -f 7)
    if [[  "$last_execution_error_tar" || "$last_execution_error_mysql" || \
           "$last_execution_pgsql" || "$last_execution_error_rsync" ]]; then
        last_execution_error=true
    else
        last_execution_error=false
    fi
}

clear_sicherung_context(){
    BACKUP_PATH=
    BACKUP_FOLDER=
    KEEK_FOR_N_DAYS=
    INTERVAL=
    config_with_dirs=
    config_with_mysql=
    config_with_pgsql=
    config_with_rsync=
    last_execution_unix_timestamp=
    last_execution_size=
    last_exection_error_tar=
    last_execution_error_mysql=
    last_execution_error_pgsql=
    last_execution_error_rsync=
    last_execution_error=
    last_execution_path=
}

get_key_by_sicherung_id(){
    dbg "Entering get_key_by_sicherung_id"
    sicherung_id="$1"
    key="$2"
    dbg "sicherung_id=$sicherung_id"
    dbg "key=$key"

    load_sicherung_context "$sicherung_id"
    echo ${!key}
    clear_sicherung_context
    dbg "Leaving get_key_by_sicherung_id"
}

help(){
    echo "ls_sicherungen - print all set up backups as csv-list"
    echo "get_sicherung_property [ID_Sicherung] [Property] - returns value of requested property"
}

case "$1" in
    ls_sicherungen)
        get_sicherungen_csv
    ;;
    get_sicherung_property)
        get_key_by_sicherung_id "$2" "$3"
    ;;
    *)
        help
esac

