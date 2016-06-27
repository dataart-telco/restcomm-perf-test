#!/bin/bash
if [ -f ./.aws_credentials ]; then
    TEST_ENGINE='aws'
fi

if [ -f ./.openstack_credentials ]; then
    TEST_ENGINE='openstack'
fi

usage() {
  echo "----------"
  echo "Usage: <max_calls_number> <simultaneous_calls> <calls_per_sec>"
  echo "----------"
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

get_docker_config(){
    if [ "$TEST_ENGINE" = 'local' ]; then
        return 0
    else
        echo `docker-machine config $1`
    fi
}

if [ -z "${TEST_ENGINE}" ]; then
    TEST_ENGINE='local'
    echo "Use local env"
    machine_ip=`ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | cut -f2 -d' '`
    COLLECTD_SERVER_IP_PUBLIC=$machine_ip
    RESTCOMM_IP_PRIVATE=$machine_ip
    IVRAPP_IP_PUBLIC=$machine_ip
else
    source ./machine_util.sh
    COLLECTD_SERVER_IP_PUBLIC=`get_public_ip collectd-server`
    RESTCOMM_IP_PRIVATE=`get_private_ip restcomm-node`
    IVRAPP_IP_PUBLIC=`get_public_ip ivrapp`
fi

RESTCOMM_IP=$RESTCOMM_IP_PRIVATE
RESTCOMM_PORT=5080
PHONE_NUMBER=5555

########################################################################
### Init test env
########################################################################

#run perf collector
docker  \
    $(get_docker_config restcomm-node) \
    exec restcomm /opt/perfcorder/run_perfcorder.d.sh

#reset stat
curl -s http://${IVRAPP_IP_PUBLIC}:7090/start

#copy test
if [ "$TEST_ENGINE" = 'local' ]; then
    rm -rf /tmp/sipp-test
    mkdir -p /tmp/sipp-test
    cp -ar $PWD/sipp-test /tmp
    TEST_LOCAL_PATH=/tmp/sipp-test
else
    docker-machine scp -r $PWD/sipp-test sipp-test:/home/ubuntu/sipp-test
    TEST_LOCAL_PATH='/home/ubuntu/sipp-test'
fi

########################################################################
### Start test container
########################################################################
exit 1
docker \
    $(get_docker_config sipp-test) \
    run \
    --rm \
    --net host \
    --privileged \
    --name sipp-test \
    -v $TEST_LOCAL_PATH:/opt/sipp-test \
    -e SIP_ADDRESS=$RESTCOMM_IP:$RESTCOMM_PORT \
    -e PHONE_NUMBER=$PHONE_NUMBER \
    -e MAXIMUM_CALLS=$1 \
    -e SIMULTANEOUS_CALLS=$2 \
    -e CALLS_PER_SEC=$3 \
    -it hamsterksu/sipp /opt/sipp-test/bootstrap.sh

########################################################################
### Collect results
########################################################################

echo "Copy results..."
DATE=`date +%Y_%m_%d_%H_%M_%S`
RESULT_DIR=results/${DATE}_$1_$2_$3

mkdir -p $RESULT_DIR
if [ "$TEST_ENGINE" = 'local' ]; then
    mv $TEST_LOCAL_PATH/logs $RESULT_DIR
    mv $TEST_LOCAL_PATH/results $RESULT_DIR
else
    docker-machine scp -r sipp-test:/home/ubuntu/sipp-test/logs $RESULT_DIR
    docker-machine scp -r sipp-test:/home/ubuntu/sipp-test/results $RESULT_DIR
fi

#stop perf collector
docker  \
    $(get_docker_config restcomm-node) \
    exec -it restcomm /opt/perfcorder/stop_perfcorder.sh

mkdir -p $RESULT_DIR/perfcorder

docker  \
    $(get_docker_config restcomm-node) \
    cp restcomm:/opt/perfcorder/target $RESULT_DIR/perfcorder

echo "Rendering results..."
docker \
    $(get_docker_config collectd-server) \
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

RESULT_INCOMING=`curl -s http://${IVRAPP_IP_PUBLIC}:7090/stat/incoming`
RESULT_RECEIVED=`curl -s http://${IVRAPP_IP_PUBLIC}:7090/stat/received`

dif=`echo $RESULT_INCOMING - $RESULT_RECEIVED | bc`

########################################################################
### Print result
########################################################################
echo "
########################################################################
### Results
########################################################################
"

echo "Result forlder: $RESULT_DIR" 

echo "
***Perfcorder data***
Path: $RESULT_DIR/perfcorder/target

echo "
***Collectd Stats***
Url: $COLLECTD_URL"

echo "
*** IVR server stats ***
Incoming calls: $RESULT_INCOMING
Gathered digits: $RESULT_RECEIVED
Failed calls: $dif" >> $RESULT_DIR/ivr_stat.txt

cat $RESULT_DIR/ivr_stat.txt