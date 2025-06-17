# Postgres 16 + PostGIS 3.5

## Quickstart
1. Variablen in der .env setzen.
  * ```NETWORK_NAME``` Name des Docker-Netzwerkes (Default=kvwmap_prod)
  * ```SERVICE_NAME``` Name des Services (Default=pgsql16)
  * ```POSTGRES_PASSWORD``` Passwort des Postgres-User "postgres", muss gesetzt werden
  * ```POSTGRES_KVWMAP_PASSWORD``` Passwort für Postgres-User "kvwmap", muss bei neuem Cluster gesetzt werden
2. ```INITDB_*``` Variablen steuern die Ausführung der Entrypoint-Scripte. 
    1. neue kvwmap-Instanz 
```
INITDB_PGBACKREST: "true"
INITDB_KVWMAPSP_DB: "true"
```
    2. Upgrade der DB, kvwmapsp-Datenbank wird übernommen, muss nicht erstellt werden. pgbackrest sollte für bessere Performance
 erst nach dem Import aktiviert werden.
```
INITDB_PGBACKREST: "false"
INITDB_KVWMAPSP_DB: "false"
```

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
* die Postgres-Konfiguration (.pgpass, postgres.conf, pg_hba.conf) liegt unter ```./config```
* das Cluster wird im Entrypoint mit ```postgres -c config_file=/var/lib/postgresql/config/postgresql.conf``` gestartet
* alle Verzeichnisse in die der Container schreibt, müssen ```chown 999:999 data pgbackrest logs``` gehören

## Docker-Konfiguration
Die wichtigsten Variablen werden in der ```.env``` gesetzt.

## Entrypoint-Scripte
im Entrypoint ```/docker-entrypoint-initdb.d/``` liegen Scripte um kvwmap, die Extension, Backup und Monitoring einzurichten. Über das Environemnt lassen sie sich steuern.

|Funktion             |Script                             |Environment                        |Default-Wert|     
|---                    |---                                |---                                |---                 |
|pg_cron              |sources/20_pg_cron.sh            |```INITDB_PGCRON: "true"```      |```true```|
|Backup               |sources/30_init_pgbackrest.sh    |```INITDB_PGBACKREST: "true"```  |```true```|
|pg_track_settings      |sources/40_pg_track_settings.sh    |```INITDB_PGTRACKSETTINGS: "true"```|```true```|
|kvwmapsp Datenbank     |sources/50_kvwmap_create.sh        |```INITDB_KVWMAPSP_DB: "true INITDB_KVWMAP_PASSWORD: "kvwmapPw""```    |```false```|

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
