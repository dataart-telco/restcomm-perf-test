#!/bin/bash 
host=$1
eth=$2
file=$3/${host}_network_${eth}.png

rrdtool graph $file \
 -e now \
 -s 'end-15m' \
 -S 15 \
 --title "Traffic on $eth" \
 --vertical-label 'Mbyte\s' \
 --imgformat PNG \
 --slope-mode   \
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
 DEF:tx=/var/lib/collectd/rrd/$host/interface-${eth}/if_octets.rrd:tx:MAX \
 DEF:rx=/var/lib/collectd/rrd/$host/interface-${eth}/if_octets.rrd:rx:MAX \
 DEF:err=/var/lib/collectd/rrd/$host/interface-${eth}/if_errors.rrd:tx:MAX \
 AREA:tx#2196F3:Tx \
 AREA:rx#FFEB3B:Rx \
 LINE2:err#F44336:Errors \
 LINE2:tx#0D47A1: \
 LINE2:rx#F57F17:
