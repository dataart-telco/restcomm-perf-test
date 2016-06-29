#!/bin/bash

source ./machine.sh
source ./perfcorder.sh

echo "Instance type memory: ${INSTANCES_MEM["$INSTANCE_TYPE"]}"

if [ ${INSTANCES_MEM["$INSTANCE_TYPE"]} -ge 4 ]; then
    echo "Setup memory settings: 4G"
    java_opt='-Djava.net.preferIPv4Stack=true -Xms2g -Xmx4g -Xmn512m -XX:MaxPermSize=512m -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycle=100 -XX:CMSIncrementalDutyCycleMin=100 -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000'
fi

if [ ${INSTANCES_MEM["$INSTANCE_TYPE"]} -ge 6 ]; then
    echo "Setup memory settings: 6G"
    java_opt='-Djava.net.preferIPv4Stack=true -Xms4g -Xmx6g -Xmn512m -XX:MaxPermSize=512m -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycle=100 -XX:CMSIncrementalDutyCycleMin=100 -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000'
fi

echo "Creating mysql database"

docker \
    $(get_docker_config mysql) \
    run \
    -d \
    --name mysql \
    --net host \
    --privileged \
    -e MYSQL_ROOT_PASSWORD=restcomm-pw \
    -e MYSQL_DATABASE=restcomm \
    -e MYSQL_USER=restcomm \
    -e MYSQL_PASSWORD=restcomm \
    -v /var/lib/mysql \
    mysql
echo "****************"
echo ""

echo "Wait for mysql: 15 sec"
sleep 15

echo "Creating mediaserver container"

docker \
    $(get_docker_config mediaserver) \
    run \
    -d \
    --name mediaserver \
    --net host \
    -e LOG_LEVEL=WARN \
    -e USE_HOST_NETWORK=true \
    -e PROPERTY_externalAddress=$MEDIASERVER_IP_PUBLIC \
    -e PROPERTY_media_lowestPort=64000 \
    -e PROPERTY_media_highestPort=65500 \
    -e RESOURCE_recorder=0 \
    -e RESOURCE_dtmfDetector=0 \
    -e RESOURCE_dtmfGenerator=0 \
    -e RESOURCE_localConnection=200 \
    -e RESOURCE_remoteConnection=200 \
    -e RESOURCE_player=200 \
    -e JAVA_OPTS="$java_opt" \
    -v /opt/perfcorder \
    -v /opt/restcomm-media-server/log \
    hamsterksu/restcomm-mediaserver:4.2.0.68

#    --privileged \

#hamsterksu/restcomm-mediaserver:cache

#-e AMAZON_EC2=true \
#-e JAVA_OPTS="$java_opt" \
#-e RESOURCE_player=200 \

echo "****************"
echo ""

echo "Creating restcomm container"

docker \
    $(get_docker_config restcomm) \
    run \
    -d \
    --name restcomm \
    --net host \
    -e INIT_PASSWORD=q1w2e3r4t5 \
    -e VOICERSS_KEY=29b2d893df9f454abbfae94df6cff95b \
    -e STATIC_ADDRESS=$RESTCOMM_IP_PUBLIC \
    -e MEDIASERVER_LOWEST_PORT=64000 \
    -e MEDIASERVER_HIGHEST_PORT=65500 \
    -e MS_ADDRESS=$MEDIASERVER_IP_PRIVATE \
    -e MEDIASERVER_EXTERNAL_ADDRESS=$MEDIASERVER_IP_PUBLIC \
    -e LOG_LEVEL=WARN \
    -e RESTCOMM_TRACE_LOG='' \
    -e ENABLE_MYSQL=true, \
    -e MYSQL_HOST=$MYSQL_IP_PRIVATE \
    -e MYSQL_SCHEMA=restcomm \
    -e MYSQL_USER=restcomm \
    -e MYSQL_PASSWORD=restcomm \
    -e RC_JAVA_OPTS="$java_opt" \
    -v /opt/Restcomm-JBoss-AS7/standalone/log \
    -v /opt/perfcorder \
    restcomm/restcomm

#    --privileged \

#    -e INIT_PASSWORD=q1w2e3r4t5 \
#    -e INIT_PASSWORD=42d8aa7cde9c78c4757862d84620c335 \
#hamsterksu/restcomm-external-ms

perfcorder_install mediaserver
perfcorder_install restcomm

echo "*************"
echo ""

echo "Wait for restcomm 15 sec"
sleep 15

echo "Creating ivrapp"
docker \
    $(get_docker_config ivrapp) \
    run \
    -d \
    --name ivrapp \
    --net host \
    --privileged \
    -e PORT=7090 \
    -e PHONE_NUMBER=5555 \
    -e RESTCOMM_HOST=$RESTCOMM_IP_PRIVATE \
    -e RESTCOMM_PORT=8080 \
    -e RESTCOMM_USER=ACae6e420f425248d6a26948c17a9e2acf \
    -e RESTCOMM_PSWD=42d8aa7cde9c78c4757862d84620c335 \
    -e RES_MSG='https://s3.amazonaws.com/da-test-audio/demo-30sec.wav' \
    -e RES_CONFIRM='https://s3.amazonaws.com/da-test-audio/demo-4sec.wav' \
    hamsterksu/ivrapp

echo "****************"
echo ""

echo "Creating collectd-server"
docker \
    $(get_docker_config collectd-server) \
    run \
    -d \
    --net host \
    --privileged \
    --name collectd-server \
    hamsterksu/collectd-server
echo "****************"
echo ""

    ############### add staistic gathering #########################
if [ "${TEST_ENGINE}" = "local" ]; then
services=(
    'localhost'
)
else
services=(
    'restcomm'
    'mediaserver'
    'ivrapp'
    'mysql'
)
fi

for service in ${services[*]} ; do
    echo "Add collectd to $service"

    docker \
        $(get_docker_config $service) \
        run \
        -d \
        -c 100 \
        --net host \
        --privileged \
        --name ${service}-collectd \
        -e COLLECTD_SERVER=$COLLECTD_SERVER_IP_PRIVATE \
        -v /proc:/mnt/proc:ro \
        hamsterksu/collectd

    echo "****************"
    echo ""
done
