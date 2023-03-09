# pg15migration

## Import von Rollen + Custom-Dumps

* Rollen in ./dumps/roles_tablespaces.sql
* Datenbanken ./dumps/schema_data.$DATABASE.dump
* ./dumps/restore.sh

* Voraussetzungen
** alte .pgpass gemountet, Symlink

1. dcm create service pg15migration kvwmap_migration
1. ./dumps als Symlink zum Dump-Ordner
1. dcm up pg15migration pg_migration
1. Import-Logs für DBs ./dumps/logs/$DATABASE

```
rm -rf ./data/*
dcm rerun pg15migration pg_migration``` zum erneuten Import
