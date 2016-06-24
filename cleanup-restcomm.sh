#!/bin/bash

docker \
    $(docker-machine config restcomm-media) \
    rm -f mediaserver

docker \
    $(docker-machine config restcomm-node) \
    rm -f restcomm

docker \
    $(docker-machine config ivrapp) \
    rm -f ivrapp

services=(
'restcomm-media'
'restcomm-node'
'ivrapp'
'mysql')

for service in ${services[*]} ; do
    echo "Romove collectd from $service"
    docker \
        $(docker-machine config $service) \
        rm -f collectd
done
