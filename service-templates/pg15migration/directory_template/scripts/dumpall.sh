#!/bin/bash
#PGHOST="localhost"
#PGUSER="kvwmap"
#PGDATABASE="kvwmapsp"
#PGPASSWORD=""
pg_dumpall -c -f cluster.dump -U kvwmap -l kvwmapsp
