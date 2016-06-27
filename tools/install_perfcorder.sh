#!/bin/bash

apt-get update && \
apt-get install -y sysstat wget zip unzip lsof net-tools

wget -q -O /opt/perfcorder/version.txt https://mobicents.ci.cloudbees.com/job/PerfCorder/lastSuccessfulBuild/artifact/perfcorder-version.txt &&\
wget -q -O /opt/perfcorder/sipp-report-$(cat /opt/perfcorder/version.txt)-with-dependencies.jar https://mobicents.ci.cloudbees.com/job/PerfCorder/lastSuccessfulBuild/artifact/target/sipp-report-$(cat /opt/perfcorder/version.txt)-with-dependencies.jar && \
unzip -o /opt/perfcorder/sipp-report-$(cat /opt/perfcorder/version.txt)-with-dependencies.jar -d /opt/perfcorder && \
chmod +x /opt/perfcorder/*.sh 