#!/bin/bash
docker run --rm -it \
--name postgres-restore \
-v $(pwd)/data:/var/lib/postgresql/data \
-v $(pwd)/backup:/pgbackrest \
pkorduan/postgis:15-3.3 \
pgbackrest --stanza=local --log-level-console=detail restore
