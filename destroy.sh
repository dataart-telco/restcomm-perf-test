
if [ "$TEST_ENGINE" = 'local' ]; then
    services=(
        'restcomm'
        'mediaserver'
        'ivrapp'
        'mysql'
        'localhost-collectd'
        'collectd-server'
    )

    for service in ${services[*]} ; do
        echo "Remove container: $service"
        docker rm -f $service
    done
else
    machines=(
        'sipp-test'
        'restcomm'
        'ivrapp'
        'mediaserver'
        'mysql'
        'collectd-server'
    )

    for machine in ${machines[*]} ; do
        echo "Remove docker machine"
        docker-machine rm -y -f $machine
    done
fi