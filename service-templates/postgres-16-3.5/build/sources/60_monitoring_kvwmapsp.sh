#!/bin/bash
set -e

if [ "${INITDB_KVWMAPSP_MONITORING}" = "true" ]; then
    echo "Monitoring mit pgmonitor in Schema kvwmapsp.monitor einrichten..."

    psql -v ON_ERROR_STOP=1 <<-EOSQL

\c kvwmapsp
CREATE SCHEMA monitor;
CREATE EXTENSION pgmonitor SCHEMA monitor;

-- Benutzer erstellen
CREATE USER zabbix WITH PASSWORD 'zabbix';

-- Zugriff auf das Schema
GRANT USAGE ON SCHEMA monitor TO zabbix;

-- Lese-Rechte auf bestehende und zukünftige Tabellen, Views und Materialized Views
GRANT SELECT ON ALL TABLES IN SCHEMA monitor TO zabbix;
ALTER DEFAULT PRIVILEGES IN SCHEMA monitor GRANT SELECT ON TABLES TO zabbix;

-- Ausführungsrechte für bestehende und zukünftige Funktionen
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA monitor TO zabbix;
ALTER DEFAULT PRIVILEGES IN SCHEMA monitor GRANT EXECUTE ON FUNCTIONS TO zabbix;

CREATE FUNCTION monitor.zabbix_pg_ls_waldir()
RETURNS TABLE (name text, size bigint, modification timestamp with time zone)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT * FROM pg_ls_waldir();
$$;
REVOKE ALL ON FUNCTION monitor.zabbix_pg_ls_waldir() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION monitor.zabbix_pg_ls_waldir() TO zabbix;

CREATE VIEW monitor.zabbix_wal_activity AS
    SELECT last_5_min_size_bytes,
      (SELECT COALESCE(sum(size),0) FROM monitor.zabbix_pg_ls_waldir()) AS total_size_bytes
      FROM (SELECT COALESCE(sum(size),0) AS last_5_min_size_bytes FROM monitor.zabbix_pg_ls_waldir() WHERE modification > CURRENT_TIMESTAMP - '5 minutes'::interval) x;

CREATE VIEW monitor.locked_tables AS
SELECT
  l.locktype,
  l.relation::regclass AS tablename,
  l.mode,
  l.pid,
  a.usename,
  a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.locktype = 'relation'
  AND l.relation IS NOT NULL;

CREATE VIEW monitor.cache_hit AS
SELECT
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit)  as heap_hit,
  sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
FROM
  pg_statio_user_tables;

CREATE VIEW monitor.transactions AS
SELECT
  COUNT(*) FILTER (WHERE state = 'active' AND xact_start IS NOT NULL) AS active_transactions,
  COUNT(*) FILTER (WHERE state = 'idle in transaction') AS idle_in_transactions,
  COUNT(*) FILTER (WHERE xact_start IS NOT NULL) AS total_open_transactions
FROM pg_stat_activity;



EOSQL

else
    echo "Monitoring wird nicht eingerichtet. (INITDB_KVWMAPSP_MONITORING=$INITDB_KVWMAPSP_MONITORING)"
fi
