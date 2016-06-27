#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/java-7-oracle

/opt/perfcorder/pc_stop_collect.sh -o /opt/perfcorder/result

fileName=`ls /opt/perfcorder/perfTest-* | head -n 1`

mv $fileName /opt/perfcorder/perfTest-result.zip
