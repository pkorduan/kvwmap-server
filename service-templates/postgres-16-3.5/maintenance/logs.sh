#!/bin/bash
#$1 Log-Verzeichnis
#$2 Alter der ältesten Log-Datei in Tagen

if [ -z "$1" ] || ! [ -d "$1" ]; then
    echo "$1 als Logdatei-Pfad nicht übergeben oder existiert nicht!"
    exit 1
fi
if [ -z "$2" ]; then
    echo "Es wurde kein Alter für Logdateien angegeben. Nutze Default 90 Tage."
    deleteAfter=90
else
    deleteAfter="$2"
fi

ZSTD_CLEVEL=19 find "$1" -type f -name "*.log" -mtime +1 -exec echo {} \; -exec zstd --rm -T3 -19 -z {} \;
find "$1" -type f \( -name "*.log" -o -name "*.zst" \) -mtime +"$deleteAfter" -exec rm {} \;
