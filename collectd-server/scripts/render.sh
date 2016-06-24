#!/bin/bash
www=/var/www/html
stat=/var/lib/collectd/rrd
mem_limit=$1
if [ -z "$mem_limit" ]; then
  mem_limit=16
fi

echo "
<html>
<head>
<title>Stats: 15min</title>
</head>
<body>" > $www/index.html

for dir in $stat/*/ ; do
  host=`basename $dir`
  echo "dir - ${host}"
  ./render_cpu.sh $host percent $www
  ./render_memory.sh $host $mem_limit $www
  ./render_network.sh $host eth0 $www

  echo "
    <center><h2>${host}</h2></center>
    <center><img src='${host}_cpu.png'></center><br>
    <center><img src='${host}_memory.png'></center><br>
    <center><img src='${host}_network_eth0.png'></center><br>
  " >> $www/index.html
done

echo "</body>" >> $www/index.html
