#!/bin/bash

#Jahre ermitteln
current_year=
current_month=
while read Y
do
  Y=$(basename $Y)
  Y=${Y:0:4}
  if [ "$current_year" != "$Y" ]; then
    current_year=$Y
    echo "lösche Sicherungen für Jahr $current_year"

    while read M
    do
      M=$(basename $M)
      M=${M:5:2}
      if [ "$current_month" != "$M" ]; then
        current_month=$M
        echo "lösche Sicherungen im Monat $current_month"

        while [ $(find . -regex ".*${current_year}_${current_month}_[0-3][0-9]*" -type d | wc -l) -gt 1 ]
        do
          rm_folder=$(find . -regex ".*${current_year}_${current_month}_[0-3][0-9]*" -type d | sort | tail -n 1)
          echo "lösche $rm_folder"
          rm -d $rm_folder
        done
      fi
    done < <(find . -regex ".*$current_year_[0-1][0-9]_[0-3][0-9]*" -type d | sort)


  fi
done < <(find . -regex '.*20[0-9][0-9]_[0-1][0-9]_[0-3][0-9]*' -type d | sort)









##############################################
# resetting variables for bash session       #
##############################################
current_year=
current_month=
