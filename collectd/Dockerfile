from ubuntu

RUN apt-get update && apt-get install -y collectd

COPY conf /etc/collectd
COPY scripts /opt/collectd-client

WORKDIR /opt/collectd-client
CMD ./run.sh
