#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-7-oracle

if [ ! -d "$JAVA_HOME" ]; then
  JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
fi

getPID(){
  local RESTCOMM_PID=""
  local RMS_PID=""

  RESTCOMM_PID=$(jps | grep jboss-modules.jar | cut -d " " -f 1)
  RMS_PID=$(jps | grep Main | cut -d " " -f 1)

  if [ -n "$RESTCOMM_PID" ]; then
    export PROC_PID=$RESTCOMM_PID
    return
  fi

  if [ -n "$RMS_PID" ]; then
    export PROC_PID=$RMS_PID
    return
  fi
}

getPID

if [ -z "$PROC_PID" ]; then
  echo "Restcomm PID is empty"
  exit 1
fi

rm /opt/perfcorder/perfTest-*

/opt/perfcorder/pc_start_collect.sh -o /opt/perfcorder/result $PROC_PID