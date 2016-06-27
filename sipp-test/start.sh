#!/bin/bash

LOCAL_ADDRESS=$(ifconfig eth0 | grep 'inet ' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n1)

echo "*****************************"
echo "Local address: $LOCAL_ADDRESS"
echo "SIP_ADDRESS: $SIP_ADDRESS"
echo "PHONE_NUMBER: $PHONE_NUMBER"
echo ""
echo "MAXIMUM_CALLS: $MAXIMUM_CALLS"
echo "SIMULTANEOUS_CALLS: $SIMULTANEOUS_CALLS"
echo "CALLS_PER_SEC: $CALLS_PER_SEC"
echo "*****************************"

LOGS_DIR="$PWD"/logs
RESULTS_DIR="$PWD"/results

mkdir -p $LOGS_DIR
mkdir -p $RESULTS_DIR

sipp \
    -sf ./test.xml \
    -s $PHONE_NUMBER \
    $SIP_ADDRESS \
    -i $LOCAL_ADDRESS \
    -p 5060 \
    -mi $LOCAL_ADDRESS \
    -mp 5090 \
    -l $SIMULTANEOUS_CALLS \
    -m $MAXIMUM_CALLS \
    -r $CALLS_PER_SEC \
    -recv_timeout 5000 -t un -nr \
    -trace_err -error_file "$LOGS_DIR"/error_"$PHONE_NUMBER"_test.log \
    -trace_msg -message_file "$LOGS_DIR"/message_"$PHONE_NUMBER"_test.log \
    -fd 1 \
    -trace_stat -stf "$RESULTS_DIR"/stat_"$PHONE_NUMBER"_test.csv \
    -trace_screen -screen_file "$RESULTS_DIR"/screen_"$PHONE_NUMBER"_test.log

#remove temp files
rm test_*.csv

echo "Test is finished"