#!/bin/bash

search_dir=/data

#if [ -n $search_dir ]; then
#  search_dir=/data
#  echo "search_dir auf Default /data gesetzt"
#fi

while read SERVER_DIR
do
  echo "==================================================================================="
  echo "Bereinige Wochensicherungen für $SERVER_DIR"
  while read Y
  do
    Y=$(basename $Y)
    Y=$(echo $Y | cut -d '_' -f 1)
    if [ "$current_year" != "$Y" ]; then
      current_year=$Y
      echo "lösche Sicherungen für Jahr $current_year"

      while read M
      do
        M=$(basename $M)
        M=$(echo $M | cut -d '_' -f 2)

        if [ "$current_month" != "$M" ]; then
          current_month=$M
          echo "lösche Sicherungen im Monat $current_month"

          find $SERVER_DIR/wochensicherungen -maxdepth 1 -regex ".*${current_year}_${current_month}_[0-3][0-9]*" -type d | sort | head -n -1 | xargs -i rm {} -dr
#          find $SERVER_DIR/wochensicherungen -maxdepth 1 -regex ".*${current_year}_${current_month}_[0-3][0-9]*" -type d | sort | head -n -1

        fi
      done < <(find $SERVER_DIR/wochensicherungen -maxdepth 1 -regex ".*${current_year}_[0-1][0-9]_[0-3][0-9]*" -type d | sort)
      current_month=
    fi
  done < <(find $SERVER_DIR/wochensicherungen -maxdepth 1 -regex '.*/20[0-9][0-9]_[0-1][0-9]_[0-3][0-9]*' -type d | sort)
  current_year=
done < <(find $search_dir -maxdepth 1 -mindepth 1 | sort)

##############################################
# resetting variables for bash session       #
##############################################
current_year=
current_month=
search_dir=
SERVER_DIR=
