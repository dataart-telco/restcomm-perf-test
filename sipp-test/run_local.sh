#!/bin/bash

docker run \
    --rm \
    --net host \
    --privileged \
    --name sipp-test \
    -v $PWD:/opt/sipp-test \
    -e SIP_ADDRESS=52.23.248.120:5080 \
    -e PHONE_NUMBER=5555 \
    -e MAXIMUM_CALLS=20 \
    -e SIMULTANEOUS_CALLS=10 \
    -e CALLS_PER_SEC=5 \
    -it hamsterksu/sipp bash /opt/sipp-test/bootstrap.sh