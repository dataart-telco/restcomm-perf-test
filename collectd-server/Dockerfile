from ubuntu

RUN apt-get update && apt-get install -y collectd bc nginx

COPY conf /etc/collectd
COPY scripts /opt/collectd-server

EXPOSE 25826 80

WORKDIR /opt/collectd-server
CMD ./run.sh
