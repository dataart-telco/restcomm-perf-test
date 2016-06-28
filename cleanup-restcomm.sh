#!/bin/bash

docker \
    $(docker-machine config mediaserver) \
    rm -f mediaserver

docker \
    $(docker-machine config restcomm) \
    rm -f restcomm