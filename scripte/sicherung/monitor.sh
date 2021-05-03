#!/bin/bash

config_dir="/home/gisadmin/www/sicherungen"
debug=false

dbg(){
	if [ "$debug" = TRUE ]; then
		echo "$1"
	fi
}

###############################################
# print out csv-list with names of all backups
###############################################
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


###############################################
# reads config of one backup into variables
###############################################
load_sicherung_context(){
	sicherung_id=$1
	logrow=$2

	#read config files
	source "${config_dir}/${sicherung_id}/backup.conf"
	config_with_dirs=false
	config_with_mysql=false
	config_with_pgsql=false
	config_with_rsync=false
	if [ -f "${config_dir}/${sicherung_id}/dirs.conf" ]; then
		config_with_dirs=true
	fi
	if [ -f "${config_dir}/${sicherung_id}/mysql_dbs.conf" ]; then
		config_with_mysql=true
	fi
	if [ -f "${config_dir}/${sicherung_id}/pg_dbs.conf" ]; then
		config_with_pgsql=true
	fi
	if [ -f "${config_dir}/${sicherung_id}/rsync.conf" ]; then
		config_with_rsync=true
	fi

	#read n-th log
	logfile=$BACKUP_PATH/monitor.log
	wc=$(wc -l < $logfile)
	head_n=$(($wc - $logrow + 1))
	monitorlog=$(head -n $head_n $logfile | tail -n 1)

	#extract fields
	execution_path=$(echo "$monitorlog" | cut -d ";" -f 2)
	execution_unix_timestamp=$(echo "$monitorlog" | cut -d ";" -f 3)
	execution_size=$(echo "$monitorlog" | cut -d ";" -f 8)
	execution_error_tar=$(echo "$monitorlog" | cut -d ";" -f 4)
	execution_error_mysql=$(echo "$monitorlog" | cut -d ";" -f 5)
	execution_error_pgsql=$(echo "$monitorlog" | cut -d ";" -f 6)
	execution_error_rsync=$(echo "$monitorlog" | cut -d ";" -f 7)

	if [[  "$execution_error_tar" = TRUE || "$execution_error_mysql" = TRUE || "$execution_pgsql" = TRUE || "$execution_error_rsync" = TRUE ]]; then
		execution_error=TRUE
	else
		execution_error=FALSE
	fi
}

###############################################
# set context-variables to null
###############################################
clear_sicherung_context(){
	BACKUP_PATH=
	BACKUP_FOLDER=
	KEEK_FOR_N_DAYS=
	config_with_dirs=
	config_with_mysql=
	config_with_pgsql=
	config_with_rsync=
	execution_unix_timestamp=
	execution_size=
	exection_error_tar=
	execution_error_mysql=
	execution_error_pgsql=
	execution_error_rsync=
	execution_error=
	execution_path=
}


###############################################
# echo specific parameter/variable from backup
###############################################
get_key_by_sicherung_id(){
	dbg "Entering get_key_by_sicherung_id"
	logrow="$1"
	sicherung_id="$2"
	key="$3"
	dbg "sicherung_id=$sicherung_id"
	dbg "key=$key"

	load_sicherung_context "$sicherung_id" "$logrow"
	echo ${!key}
	clear_sicherung_context
	dbg "Leaving get_key_by_sicherung_id"
}

###############################################
# cheks if all prequisites are fulfilled
###############################################
check_backup_setup(){
	testfile=/etc/cron.hourly/copy_backup_crontab
	error=false
	if [ ! -f $testfile ]; then
		message="stündlicher Cronjob fehlt ($testfile) "
		error=true
	fi

	testfile=/etc/cron.d/kvwmap_backup_crontab*
	if [ ! -f $testfile ]; then
		message=$message"Cronjob für Sicherungen fehlt ($testfile)"
		error=true
	fi

	if [ "$error" = true ]; then
		echo $message
	else
		echo "OK"
	fi

}

###############################################
#print out sicherung.log for sicherung_id
###############################################
get_latest_log(){
	sicherung_id=$1

	source "${config_dir}/${sicherung_id}/backup.conf"
	#export BACKUP_PATH
	cat $BACKUP_PATH/latest/sicherung.log

	clear_sicherung_context
}

help(){
	echo "ls_sicherungen - print all set up backups as csv-list"
	echo "get_last_sicherung_property [ID_Sicherung] [Property] - returns value of requested property"
	echo "check_backup_setup - check if all prerequisites are fulfilled"
}

case "$1" in
	ls_sicherungen)
		get_sicherungen_csv
		;;
	get_last_sicherung_property)
		get_key_by_sicherung_id 1 "$2" "$3"
		;;
	check_backup_setup)
		check_backup_setup
		;;
	get_latest_log)
		get_latest_log "$2"
	;;
	*)
		help
esac

exit 0
