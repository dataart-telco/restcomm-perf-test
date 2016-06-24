#!/bin/bash

source ./machine_util.sh

usage() {
  echo "----------"
  echo "Usage: <max_calls_number> <simultaneous_calls> <calls_per_sec>"
  echo "----------"
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

COLLECTD_SERVER_IP_PUBLIC=`get_public_ip collectd-server`
RESTCOMM_IP_PRIVATE=`get_private_ip restcomm-node`
IVRAPP_IP_PUBLIC=`get_public_ip ivrapp`

RESTCOMM_IP=$RESTCOMM_IP_PRIVATE
RESTCOMM_PORT=5080
PHONE_NUMBER=5555

curl -s http://${IVRAPP_IP_PUBLIC}:7090/start

docker-machine scp -r $PWD/sipp-test sipp-test:/home/ubuntu/sipp-test

docker \
    $(docker-machine config sipp-test) \
    run \
    --rm \
    --net host \
    --privileged \
    --name sipp-test \
    -v /home/ubuntu/sipp-test:/opt/sipp-test \
    -e SIP_ADDRESS=$RESTCOMM_IP:$RESTCOMM_PORT \
    -e PHONE_NUMBER=$PHONE_NUMBER \
    -e MAXIMUM_CALLS=$1 \
    -e SIMULTANEOUS_CALLS=$2 \
    -e CALLS_PER_SEC=$3 \
    -it hamsterksu/sipp /opt/sipp-test/bootstrap.sh

echo "Copy results..."
DATE=`date +%Y_%m_%d_%H_%M_%S`
RESULT_DIR=results/${DATE}_$1_$2_$3

mkdir -p $RESULT_DIR
docker-machine scp -r sipp-test:/home/ubuntu/sipp-test/logs $RESULT_DIR
docker-machine scp -r sipp-test:/home/ubuntu/sipp-test/results $RESULT_DIR

echo "Rendering results..."
docker \
    $(docker-machine config collectd-server) \
    exec \
    collectd-server \
    bash /opt/collectd-server/render.sh ${INSTANCES_MEM["$INSTANCE_TYPE"]}

COLLECTD_URL="http://${COLLECTD_SERVER_IP_PUBLIC}"

services=(
'restcomm-media'
'restcomm-node'
'ivrapp'
'mysql')

for service in ${services[*]}; do
    wget -O $RESULT_DIR/${service}_cpu.png $COLLECTD_URL/${service}_cpu.png
    wget -O $RESULT_DIR/${service}_memory.png $COLLECTD_URL/${service}_memory.png
    wget -O $RESULT_DIR/${service}_network_eth0.png $COLLECTD_URL/${service}_network_eth0.png
done

echo ""
echo "Stats: $COLLECTD_URL"

RESULT_INCOMING=`curl -s http://${IVRAPP_IP_PUBLIC}:7090/stat/incoming`
RESULT_RECEIVED=`curl -s http://${IVRAPP_IP_PUBLIC}:7090/stat/received`

dif=`echo $RESULT_INCOMING - $RESULT_RECEIVED | bc`

echo "
*** IVR server stats ***
Incoming calls: $RESULT_INCOMING
Gathered digits: $RESULT_RECEIVED
Failed calls: $dif" >> $RESULT_DIR/ivr_stat.txt

cat $RESULT_DIR/ivr_stat.txt