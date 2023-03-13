#!/bin/bash
docker exec -it kvwmap_prod_pgsql bash -c "cd /dumps; /dumps/dump.sh"
./import_dumps.sh
