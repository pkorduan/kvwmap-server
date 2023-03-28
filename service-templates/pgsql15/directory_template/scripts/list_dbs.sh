#!/bin/bash

psql -U kvwmap -d kvwmapsp -t -c "select distinct datname from pg_catalog.pg_database where datname not like 'template%';"
