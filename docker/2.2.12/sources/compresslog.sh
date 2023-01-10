#!/bin/sh

if [ -n "$2" ]; then
    if [ "${1}" != "${2}" ]; then
	    echo "compressing logfile ${2}"
    	tar -czf "${2}.tar.gz" "${2}"
	    rm "${2}"
    fi
else
    echo "no old logfile to compress"
fi
