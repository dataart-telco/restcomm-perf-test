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
 DEF:system=/var/lib/collectd/rrd/$host/cpu/${prefix}-system.rrd:value:MAX \
 DEF:user=/var/lib/collectd/rrd/$host/cpu/${prefix}-user.rrd:value:MAX \
 DEF:wait=/var/lib/collectd/rrd/$host/cpu/${prefix}-wait.rrd:value:MAX \
 AREA:wait#F44336:"Wait max":STACK \
 AREA:system#4CAF50:"Sys max":STACK \
 AREA:user#03A9F4:"User max":STACK 

echo "File: $file"
