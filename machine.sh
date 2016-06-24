#!/bin/bash

if [ -f ./.aws_credentials ]; then
    source ./.aws_credentials
fi

if [ -f ./.openstack_credentials ]; then
    source ./.openstack_credentials
fi

source ./machine_util.sh

create_machine(){
    if [ "${TEST_ENGINE}" = "openstack" ]; then
        create_machine_openstack $@
    else
        create_machine_aws $@
    fi
}

create_machine_openstack(){
    echo "Create openstack machine: $1 ($2)"
    name=$1
    instance_type=$2
    docker-machine create \
        --driver openstack \
        --openstack-tenant-name "$OPENSTACK_TENANT_NAME" \
        --openstack-region "$OPENSTACK_REGION" \
        --openstack-auth-url "$OPENSTACK_AUTH_URL" \
        --openstack-username "$OPENSTACK_USER" \
        --openstack-password "$OPENSTACK_PSWD" \
        --openstack-image-id "$OPENSTACK_IMAGE_ID" \
        --openstack-flavor-name "$instance_type" \
        --openstack-net-name "$OPENSTACK_PRIVATE_NETWORK_NAME" \
        --openstack-floatingip-pool "$OPENSTACK_EXTERNAL_NETWORK_NAME" \
        --openstack-ssh-user "$OPENSTACK_OS_USER" \
        --openstack-sec-groups "$OPENSTACK_SEC_GROUP" \
        $name
}

create_machine_aws(){
    echo "Create aws machine: $1"
    name=$1
    instance_type=$2
    docker-machine create \
        --driver amazonec2 \
        --amazonec2-access-key $AWS_KEY \
        --amazonec2-secret-key $AWS_SECRET \
        --amazonec2-region $AWS_REGION \
        --amazonec2-instance-type $instance_type \
        --amazonec2-zone=b \
        $name
}

init_machines(){

    if [ -z "$AWS_KEY" ] && [ -z "$OPENSTACK_USER" ]; then
        echo "No credentials are provided"
        exit 1
    fi

    RESTCOMM_NODE=`exists restcomm-node`
    RESTCOMM_MEDIA=`exists restcomm-media`
    MYSQL=`exists mysql`
    IVRAPP=`exists ivrapp`
    COLLECTD_SERVER=`exists collectd-server`
    SIPP_TEST=`exists sipp-test`

    if [ -z "$SIPP_TEST" ]; then
        echo "Creating sipp-test instance"
        create_machine sipp-test $INSTANCE_TYPE
    fi

    if [ -z "$COLLECTD_SERVER" ]; then
        echo "Creating collect.d server instance"
        create_machine collectd-server $COLLECTD_SERVER_INSTANCE_TYPE
    fi

    if [ -z "$IVRAPP" ]; then
        echo "Creating ivrapp instance"
        create_machine ivrapp $APP_INSTANCE_TYPE
    fi

    if [ -z "$MYSQL" ]; then
        echo "Creating mysql instance"
        create_machine mysql $INSTANCE_TYPE
    fi

    if [ -z "$RESTCOMM_NODE" ]; then
        echo "Creating restcomm-node instance"
        create_machine restcomm-node $INSTANCE_TYPE
    fi

    if [ -z "$RESTCOMM_MEDIA" ]; then
        echo "Creating restocmm mediaserver instance"
        create_machine restcomm-media $INSTANCE_TYPE
    fi

    RESTCOMM_NODE=`exists restcomm-node`
    RESTCOMM_MEDIA=`exists restcomm-media`
    MYSQL=`exists mysql`
    IVRAPP=`exists ivrapp`
    COLLECTD_SERVER=`exists collectd-server`
    SIPP_TEST=`exists sipp-test`

    if [ -z "$SIPP_TEST" ]; then
        echo "sipp-test server instance does not exist"
        exit 1
    fi

    if [ -z "$COLLECTD_SERVER" ]; then
        echo "collect.d server instance does not exist"
        exit 1
    fi

    if [ -z "$IVRAPP" ]; then
        echo "ivrp instance does not exist"
        exit 1
    fi

    if [ -z "$MYSQL" ]; then
        echo "Mysql instance does not exist"
        exit 1
    fi

    if [ -z "$RESTCOMM_NODE" ]; then
        echo "Restcomm node instance does not exist"
        exit 1
    fi

    if [ -z "$RESTCOMM_MEDIA" ]; then
        echo "Restcomm mediaserver instance does not exist"
        exit 1
    fi

    SIPP_TEST_IP_PRIVATE=`get_private_ip sipp-test`
    SIPP_TEST_IP_PUBLIC=`get_public_ip sipp-test`

    COLLECTD_SERVER_IP_PRIVATE=`get_private_ip collectd-server`
    COLLECTD_SERVER_IP_PUBLIC=`get_public_ip collectd-server`

    IVRAPP_IP_PRIVATE=`get_private_ip ivrapp`
    IVRAPP_IP_PUBLIC=`get_public_ip ivrapp`

    MYSQL_IP_PRIVATE=`get_private_ip mysql`
    MYSQL_IP_PUBLIC=`get_public_ip mysql`

    MEDIASERVER_IP_PRIVATE=`get_private_ip restcomm-media`
    MEDIASERVER_IP_PUBLIC=`get_public_ip restcomm-media`

    RESTCOMM_IP_PRIVATE=`get_private_ip restcomm-node`
    RESTCOMM_IP_PUBLIC=`get_public_ip restcomm-node`

}

if [ -z "${TEST_ENGINE}" ]; then
    TEST_ENGINE='local'
    echo "Use local env"
    machine_ip=`ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | cut -f2 -d' '`
    SIPP_TEST_IP_PRIVATE=$machine_ip
    SIPP_TEST_IP_PUBLIC=$machine_ip

    COLLECTD_SERVER_IP_PRIVATE=$machine_ip
    COLLECTD_SERVER_IP_PUBLIC=$machine_ip

    IVRAPP_IP_PRIVATE=$machine_ip
    IVRAPP_IP_PUBLIC=$machine_ip

    MYSQL_IP_PRIVATE=$machine_ip
    MYSQL_IP_PUBLIC=$machine_ip

    MEDIASERVER_IP_PRIVATE=$machine_ip
    MEDIASERVER_IP_PUBLIC=$machine_ip

    RESTCOMM_IP_PRIVATE=$machine_ip
    RESTCOMM_IP_PUBLIC=$machine_ip

    INSTANCE_TYPE='local-pc'
    APP_INSTANCE_TYPE='local-pc'
    COLLECTD_SERVER_INSTANCE_TYPE='local-pc'

    declare -A INSTANCES_MEM=( 
        ['local-pc']='4'
    )
else
    init_machines
fi

echo "*** sipp-test server ***
NOTE: use 'docker-machine ssh sipp-test' to connect to instance 

SIPP_TEST_IP_PUBLIC: $SIPP_TEST_IP_PUBLIC
SIPP_TEST_IP_PRIVATE: $SIPP_TEST_IP_PRIVATE
"

echo "*** collect.d server ***
NOTE: use 'docker-machine ssh collectd-server' to connect to instance 

COLLECTD_SERVER_IP_PUBLIC: $COLLECTD_SERVER_IP_PUBLIC
COLLECTD_SERVER_IP_PRIVATE: $COLLECTD_SERVER_IP_PRIVATE
"

echo "*** ivrapp ***
NOTE: use 'docker-machine ssh ivrapp' to connect to instance 

IVRAPP_IP_PUBLIC: $IVRAPP_IP_PUBLIC
IVRAPP_IP_PRIVATE: $IVRAPP_IP_PRIVATE
"

echo "*** Mysql ***
NOTE: use 'docker-machine ssh mysql' to connect to instance 

MYSQL_IP_PUBLIC: $MYSQL_IP_PUBLIC
MYSQL_IP_PRIVATE: $MYSQL_IP_PRIVATE
"

echo "*** Restcomm node ***
NOTE: use 'docker-machine ssh restcomm-node' to connect to instance 

RESTCOMM_IP_PUBLIC: $RESTCOMM_IP_PUBLIC
RESTCOMM_IP_PRIVATE: $RESTCOMM_IP_PRIVATE
"

echo "*** Mediaserver ***
NOTE: use 'docker-machine ssh restcomm-media' to connect to instance 

MEDIASERVER_IP_PUBLIC: $MEDIASERVER_IP_PUBLIC
MEDIASERVER_IP_PRIVATE: $MEDIASERVER_IP_PRIVATE
******************
"