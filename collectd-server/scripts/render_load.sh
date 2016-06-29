#!/bin/bash 

host=$1
file=$2/${host}_load.png

rrdtool graph $file \
 -e now \
 -s 'end-15m' \
 -S 15 \
 --title "Load avarage" \
 --vertical-label "Percents" \
 --imgformat PNG \
 --slope-mode   \
 --lower-limit 0 \
 -X 0 \
 -E \
 -i \
 --color SHADEA#FFFFFF \
 --color SHADEB#FFFFFF \
 --color BACK#CCCCCC \
 -w 600 \
 -h 150 \
 --interlaced \
 --font DEFAULT:8:/usr/local/share/rrdtool/fonts/ARIAL8.TTF \
 DEF:load1=/var/lib/collectd/rrd/$host/load/load.rrd:shortterm:AVERAGE \
 DEF:load5=/var/lib/collectd/rrd/$host/load/load.rrd:midterm:AVERAGE \
 DEF:load15=/var/lib/collectd/rrd/$host/load/load.rrd:longterm:AVERAGE \
 LINE2:load1#03A9F4:load1\
 LINE2:load5#009688:load5\
 LINE2:load15#FF5722:load15\

echo "File: $file"
