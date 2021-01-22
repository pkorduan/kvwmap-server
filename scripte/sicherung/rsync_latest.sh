#!/bin/bash
LATEST_BACKUP_DIR=/var/Sicherungen/day/$(date +%u)/
HOSTNAME=gdi
rsync -avz --progress -e 'ssh -p 50219' "$LATEST_BACKUP_DIR" gisadmin@168.119.145.21:/data/$HOSTNAME/$(date +%Y_%m_%d)
