#!/bin/bash

if [ -z "${TEST_ENGINE}" ] && [ -f ../.aws_credentials ]; then
    echo "Import AWS credentials"
    source ../.aws_credentials
fi

if [ -z "${TEST_ENGINE}" ] && [ -f ../.openstack_credentials ]; then
    echo "Import openstack credentials"
    source ../.openstack_credentials
fi

if [ -z "${TEST_ENGINE}" ]; then
    TEST_ENGINE='local'
fi

echo "TEST_ENGINE: $TEST_ENGINE"

get_docker_config(){
    if [ "$TEST_ENGINE" = 'local' ]; then
        return 0
    else
        echo `docker-machine config $1`
    fi
}