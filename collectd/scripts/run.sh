#!/bin/bash 

sed -i "s|0.0.0.0|$COLLECTD_SERVER|" /etc/collectd/collectd.conf.d/network.conf
sed -i "s/Hostname .*/Hostname \"$HOSTNAME\"/" /etc/collectd/collectd.conf

collectd -f
