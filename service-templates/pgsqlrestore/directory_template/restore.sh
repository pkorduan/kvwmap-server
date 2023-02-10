#!/bin/bash
# https://pgbackrest.org/command.html#command-restore
docker run --rm -it \
--name postgres-restore \
-v $(pwd)/data:/var/lib/postgresql/data \
-v $(pwd)/backup:/pgbackrest \
pkorduan/postgis:15-3.3 \
pgbackrest --stanza=local --log-level-console=detail --set= --type=time --target=2015-01-30 14:15:11 EST restore
