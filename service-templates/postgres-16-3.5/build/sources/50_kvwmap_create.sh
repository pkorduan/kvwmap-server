#!/bin/bash
set -e

if [ "${INITDB_KVWMAPSP_DB}" = "true" ]; then
    echo "kvwmapsp Datenbank und kvwmap Rolle einrichten..."
    PG_KVWMAP_PASSWORD="${INITDB_KVWMAP_PASSWORD:-kvwmap}"

    psql -v ON_ERROR_STOP=1 <<-EOSQL

CREATE ROLE kvwmap WITH SUPERUSER LOGIN PASSWORD '${PG_KVWMAP_PASSWORD}';

GRANT SET ON PARAMETER log_min_messages TO "kvwmap";
CREATE DATABASE kvwmapsp WITH OWNER kvwmap;
CREATE EXTENSION IF NOT EXISTS postgis;
ALTER USER kvwmap WITH NOSUPERUSER;

UPDATE
spatial_ref_sys
SET
proj4text = '+proj=longlat +ellps=bessel +datum=potsdam +nadgrids=MVTR2010.gsb+no_defs'
WHERE
srid = 4314;

UPDATE
spatial_ref_sys
SET
proj4text = '+proj=longlat +ellps=krass +nadgrids=MVTRS4283.gsb +no_defs '
WHERE
srid = 4178;

UPDATE
spatial_ref_sys
SET
proj4text = '+proj=tmerc +lat_0=0 +lon_0=12 +k=1.000000 +x_0=4500000 +y_0=0 +ellps=krass +nadgrids=MVTRS4283.gsb +units=m +no_defs'
WHERE
srid = 2398;

UPDATE
spatial_ref_sys
SET
proj4text = '+proj=tmerc +lat_0=0 +lon_0=9 +k=1.000000 +x_0=3500000 +y_0=0 +ellps=bessel +datum=potsdam +nadgrids=MVTR2010.gsb +units=m +no_defs'
WHERE
srid = 31967;

UPDATE
spatial_ref_sys
SET
proj4text = '+proj=tmerc +lat_0=0 +lon_0=12 +k=1.000000 +x_0=4500000 +y_0=0 +ellps=bessel +datum=potsdam +nadgrids=MVTR2010.gsb +units=m +no_defs'
WHERE
srid = 31968;

UPDATE
spatial_ref_sys
SET
proj4text = '+proj=tmerc +lat_0=0 +lon_0=15 +k=1.000000 +x_0=5500000 +y_0=0 +ellps=bessel +datum=potsdam +nadgrids=MVTR2010.gsb +units=m +no_defs'
WHERE
srid = 31969;

EOSQL

else
    echo "Datenbank kvwmapsp, Rolle kvwmap werden nicht eingerichtet. (INITDB_KVWMAPSP_DB=$INITDB_KVWMAPSP_DB)"
fi
