#!/bin/bash 

host=$1
prefix=$2
file=$3/${host}_cpu.png

rrdtool graph $file \
 -e now \
 -s 'end-15m' \
 -S 15 \
 --title "Cpu usage" \
 --vertical-label "Percents" \
 --imgformat PNG \
 --slope-mode   \
 --lower-limit 0 \
 --upper-limit 100 \
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
 DEF:a=/var/lib/collectd/rrd/$host/cpu/${prefix}-idle.rrd:value:MAX \
 DEF:b=/var/lib/collectd/rrd/$host/cpu/${prefix}-system.rrd:value:MAX \
 DEF:c=/var/lib/collectd/rrd/$host/cpu/${prefix}-user.rrd:value:MAX \
 DEF:user_avg=/var/lib/collectd/rrd/$host/cpu/${prefix}-user.rrd:value:AVERAGE \
 DEF:sys_avg=/var/lib/collectd/rrd/$host/cpu/${prefix}-system.rrd:value:AVERAGE \
 AREA:b#54eb48:System \
 AREA:c#ebd648:User \
 LINE2:b#2cc320: \
 LINE2:c#e7ad4a: \
 LINE2:user_avg#03A9F4:User_avg \
 LINE2:sys_avg#009688:Sys_avg

echo "File: $file"
