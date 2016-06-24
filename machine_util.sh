#!/bin/bash

exists(){
    machine=`docker-machine ls | grep $1`
    if [ -n "$machine" ]; then
        echo $machine | awk '{print $5}'
    fi
}

get_private_ip(){
    ip=`docker-machine inspect $1 | grep PrivateIPAddress | cut -d ':' -f2`
    ip=${ip:2:-2}
    if [ -z "$ip" ]; then
        ip=`docker-machine ssh $1 ip addr show eth0 | grep inet | head -n 1 | awk '{print $2}' | cut -f1 -d'/'`
    fi
    echo $ip
}

get_public_ip(){
    ip=`docker-machine inspect $1 | grep \"IPAddress\" | cut -d ':' -f2`
    echo ${ip:2:-2}
}