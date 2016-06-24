#!/bin/bash 

host=$1
mem=$2
upper_limit=`echo "$mem * 1024*1024*1000" | bc`
file=$3/${host}_memory.png

rrdtool graph $file \
 -e now \
 -s 'end-15m' \
 -S 15 \
 --title "Memory usage: ${mem}G" \
 --vertical-label "MBytes" \
 --imgformat PNG \
 --slope-mode   \
 --lower-limit 0 \
 --upper-limit ${upper_limit} \
 --rigid \
 -E \
 -i \
 --color SHADEA#FFFFFF \
 --color SHADEB#FFFFFF \
 --color BACK#CCCCCC \
 -w 600 \
 -h 150 \
 --interlaced \
 --font DEFAULT:8:/usr/local/share/rrdtool/fonts/ARIAL8.TTF \
 DEF:a=/var/lib/collectd/rrd/${host}/memory/memory-used.rrd:value:MAX \
 AREA:a#2196F3:used \
 LINE2:a#0D47A1: 

echo "File: $file"
