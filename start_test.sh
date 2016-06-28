#!/bin/bash
source ./perfcorder.sh
source ./config.sh

usage() {
  echo "----------"
  echo "Usage: <max_calls_number> <simultaneous_calls> <calls_per_sec>"
  echo "----------"
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

if [ "$TEST_ENGINE" = 'local' ]; then
    echo "Use local env"
    machine_ip=`ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | cut -f2 -d' '`
    COLLECTD_SERVER_IP_PUBLIC=$machine_ip
    RESTCOMM_IP_PRIVATE=$machine_ip
    IVRAPP_IP_PUBLIC=$machine_ip
else
    source ./machine_util.sh
    COLLECTD_SERVER_IP_PUBLIC=`get_public_ip collectd-server`
    RESTCOMM_IP_PRIVATE=`get_private_ip restcomm`
    IVRAPP_IP_PUBLIC=`get_public_ip ivrapp`
fi

RESTCOMM_IP=$RESTCOMM_IP_PRIVATE
RESTCOMM_PORT=5080
PHONE_NUMBER=5555

########################################################################
### Init test env
########################################################################

#run perf collector
perfcorder_start restcomm
perfcorder_start mediaserver

#reset stat
curl -s http://${IVRAPP_IP_PUBLIC}:7090/start

#copy test
if [ "$TEST_ENGINE" = 'local' ]; then
    #remove prev logs
    rm -rf /tmp/sipp-test
    mkdir -p /tmp/sipp-test
    cp -ar $PWD/sipp-test /tmp
    TEST_LOCAL_PATH=/tmp/sipp-test
else
    #remove prev data
    docker-machine ssh sipp-test sudo rm -rf /home/ubuntu/sipp-test

    docker-machine scp -r $PWD/sipp-test sipp-test:/home/ubuntu/sipp-test
    TEST_LOCAL_PATH='/home/ubuntu/sipp-test'
fi

########################################################################
### Start test container
########################################################################

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
perfcorder_stop restcomm
perfcorder_stop mediaserver

perfcorder_dump restcomm
perfcorder_dump mediaserver

echo "Rendering results..."
echo "Collectd mem: ${INSTANCES_MEM["$INSTANCE_TYPE"]}"
docker \
    $(get_docker_config collectd-server) \
    exec \
    collectd-server \
    bash /opt/collectd-server/render.sh ${INSTANCES_MEM["$INSTANCE_TYPE"]}

COLLECTD_URL="http://${COLLECTD_SERVER_IP_PUBLIC}"

if [ "${TEST_ENGINE}" = "local" ]; then
    services=(
        "$(hostname)"
    )
else
    services=(
        'restcomm'
        'mediaserver'
        'ivrapp'
        'mysql'
    )
fi

for service in ${services[*]}; do
    wget -O $RESULT_DIR/${service}_cpu.png $COLLECTD_URL/${service}_cpu.png
    wget -O $RESULT_DIR/${service}_memory.png $COLLECTD_URL/${service}_memory.png
    wget -O $RESULT_DIR/${service}_network_eth0.png $COLLECTD_URL/${service}_network_eth0.png
done

RESULT_INCOMING=`curl -s http://${IVRAPP_IP_PUBLIC}:7090/stat/incoming`
RESULT_RECEIVED=`curl -s http://${IVRAPP_IP_PUBLIC}:7090/stat/received`

dif=`echo $RESULT_INCOMING - $RESULT_RECEIVED | bc`

perfcorder_install_local

render_perfcorder_result(){
    folder=$1
    echo "folder: $folder"
    cp $RESULT_DIR/results/*_test.csv $folder/data/periodic/sip/sipp.csv
    cur=$PWD
    cd $folder
    zip -rq result.zip data
    cd $cur
    $PERFCORDER_LOCAL/pc_analyse.sh $folder/result.zip 1 > $folder/PerfCorderAnalysis.xml
    cat $folder/PerfCorderAnalysis.xml | $PERFCORDER_LOCAL/pc_test.sh ./xslt/mss-proxy-goals.xsl > $folder/TEST-PerfCorderAnalysisTest.xml
}

render_perfcorder_result $RESULT_DIR/perfcorder-restcomm
render_perfcorder_result $RESULT_DIR/perfcorder-mediaserver

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
Restcomm: $RESULT_DIR/perfcorder-restcomm
Mediaserver: $RESULT_DIR/perfcorder-mediaserver"


echo "
***Collectd Stats***
Url: $COLLECTD_URL"

echo "
*** IVR server stats ***
Incoming calls: $RESULT_INCOMING
Gathered digits: $RESULT_RECEIVED
Failed calls: $dif" >> $RESULT_DIR/ivr_stat.txt

cat $RESULT_DIR/ivr_stat.txt