# Postgres 16 + PostGIS 3.5

## Quickstart
1. Variablen in der .env setzen.
  * ```NETWORK_NAME``` Name des Docker-Netzwerkes (Default=kvwmap_prod)
  * ```SERVICE_NAME``` Name des Services (Default=pgsql16)
  * ```POSTGRES_PASSWORD``` Passwort des Postgres-User "postgres", muss gesetzt werden
  * ```POSTGRES_KVWMAP_PASSWORD``` Passwort für Postgres-User "kvwmap", muss gesetzt werden
2. ```INITDB_*```-Variablen setzen, siehe unten

## Eigenschaften
* Image wird lokale gebaut
* basiert auf postgis/postgis:16-3.5, welches wiederum dem Standard postgres-Image aufbaut
* enthält folgende Extensions
  * mysql-fdw
  * oracle-fdw
  * pgstat
  * pg-track-settings
  * pg-cron
  * pgmonitor

## Postgres-Konfiguration
* die gesamte Postgres-Konfiguration liegt unter ```./config```
* das Cluster wird im Entrypoint mit ```postgres -c config_file=/var/lib/postgresql/config/postgresql.conf``` gestartet

* Die .pgpass liegt im Dateiverzeichnis unter ```./config/.pgpass``` das environemnt entspricht dem mit
```
PGPASSFILE: "/var/lib/postgresql/config/.pgpass"
```
* alle Verzeichnisse in die der Container schreibt, müssen ```chown 999:999 data pgbackrest logs``` gehören
## Docker-Konfiguration
Die wichtigsten Variablen werden in der ```.env``` gesetzt.

## initdb
Siehe hierzu auch die Dokumentation der Baseimages.

* Initialisierung der postgres Datenbank, DB und User sollten nicht geändert werden. Passwort sollte über .env geändert werden.
```yml
POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
PGSQL_DB: "postgres"
PGSQL_USER: "postgres"
```

## Entrypoint-Scripte
im Entrypoint ```/docker-entrypoint-initdb.d/``` liegen Scripte um kvwmap, die Extension, Backup und Monitoring einzurichten. Über das Environemnt lassen sie sich steuern.

|Funktion             |Script   	                      |Environment   	                  |Abhängigkeit   	|
|---	                |---	                            |---	                            |---	            |
|pg_cron   	          |sources/20_pg_cron.sh   	        |```INITDB_PGCRON: "true"```   	  |keine            |
|Backup   	          |sources/30_init_pgbackrest.sh   	|```INITDB_PGBACKREST: "true"```  |keine   	        |
|pg_track_settings   	|sources/40_pg_track_settings.sh 	|```INITDB_PGTRACKSETTINGS: "true"```|keine        	|
|kvwmapsp Datenbank  	|sources/50_kvwmap_create.sh    	|```INITDB_KVWMAPSP_DB: "true INITDB_KVWMAP_PASSWORD: "kvwmapPw""```	|keine           	|
|Monitoring          	|sources/60_monitoring_kvwmapsp.sh|```INITDB_KVWMAPSP_MONITORING: "true"```   	|kvwmapsp Datenbank|

## Maintenance 
* Logs aufräumen ```
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
00 04 * * * root /home/gisadmin/networks/kvwmap_prod/services/postgres-16-3.5/maintenance/logs.sh /home/gisadmin/networks/kvwmap_prod/services/postgres-16-3.5/logs
``` 

## Monitoring
In Kombination mit https://github.com/dudehro/zabbix_conf kann im docker-compose ein Label gesetzt werden:
```
label:
    monitoring.pgmonitor: true
```
