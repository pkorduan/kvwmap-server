#!/bin/sh
#echo "compresslog.sh"
#echo "old log: ${1} new log ${2}"

if [ "${1}" != "${2}" ]; then
	echo "compressing logfile ${2}"
	tar -czf "${2}.tar.gz" "${2}"
	rm "${2}"
fi
