#!/bin/bash
# https://pgbackrest.org/command.html#command-restore
docker run --rm -it \
--name pg_resetwall \
-v $(pwd)/data:/var/lib/postgresql/data \
pkorduan/postgis:15-3.3 \
pg_resetwal -f /var/lib/postgresql/data
