docker rm -f client 

docker run \
  --net host \
  --privileged \
  -d \
  --name client \
  -e COLLECTD_SERVER=127.0.0.1 \
  -v /proc:/mnt/proc:ro \
  collectd
