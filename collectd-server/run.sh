docker rm -f collectd-server
docker run --net host --name collectd-server -d --privileged collectd-server
