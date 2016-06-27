#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-7-oracle

getPID(){
   RESTCOMM_PID=""
   RMS_PID=""

   export RESTCOMM_PID=$(jps | grep jboss-modules.jar | cut -d " " -f 1)
   export JBOSS_PID=$RESTCOMM_PID
   echo "Restcomm PID: $RESTCOMM_PID"

   while read -r line
   do
    if  ps -ef | grep $line | grep -q  mediaserver
    then
          export RMS_PID=$line
          echo "RMS PID: $RMS_PID"
   fi
   done < <(jps | grep Main | cut -d " " -f 1)
}

getPID

if [ -z "$RESTCOMM_PID" ]; then
  echo "Restcomm PID is empty"
  exit 1
fi

/opt/perfcorder/pc_start_collect.sh -o /opt/perfcorder $RESTCOMM_PID