PERFCORDER_LOCAL=$PWD/results/perfcorder

perfcorder_install_local(){
    if [ -f $PERFCORDER_LOCAL/sipp-report-$(cat $PERFCORDER_LOCAL/version.txt)-with-dependencies.jar ]; then
        return
    fi
    mkdir -p $PERFCORDER_LOCAL
    wget -q -O $PERFCORDER_LOCAL/version.txt https://mobicents.ci.cloudbees.com/job/PerfCorder/lastSuccessfulBuild/artifact/perfcorder-version.txt &&\
    wget -q -O $PERFCORDER_LOCAL/sipp-report-$(cat $PERFCORDER_LOCAL/version.txt)-with-dependencies.jar https://mobicents.ci.cloudbees.com/job/PerfCorder/lastSuccessfulBuild/artifact/target/sipp-report-$(cat $PERFCORDER_LOCAL/version.txt)-with-dependencies.jar && \
    unzip -o $PERFCORDER_LOCAL/sipp-report-$(cat $PERFCORDER_LOCAL/version.txt)-with-dependencies.jar -d $PERFCORDER_LOCAL &&\
    chmod +x $PERFCORDER_LOCAL/*.sh
}

perfcorder_install(){
    instance=$1
    docker \
        $(get_docker_config $instance) \
        cp \
        ./tools/install_perfcorder.sh \
        $instance:/opt/perfcorder

    docker \
        $(get_docker_config $instance) \
        cp \
        ./tools/run_perfcorder.sh \
        $instance:/opt/perfcorder

    docker \
        $(get_docker_config $instance) \
        cp \
        ./tools/run_perfcorder.d.sh \
        $instance:/opt/perfcorder

    docker \
        $(get_docker_config $instance) \
        cp \
        ./tools/stop_perfcorder.sh \
        $instance:/opt/perfcorder

    docker \
        $(get_docker_config $instance) \
        exec -it $instance /opt/perfcorder/install_perfcorder.sh

}

perfcorder_dump(){
    instance=$1
    mkdir -p $RESULT_DIR/perfcorder-$instance

    docker  \
        $(get_docker_config $instance) \
        cp $instance:/opt/perfcorder/result/data $RESULT_DIR/perfcorder-$instance

#    docker  \
#        $(get_docker_config $instance) \
#        cp $instance:/opt/perfcorder/perfTest-result.zip $RESULT_DIR/perfcorder-$instance/perfTest-result.zip
}

perfcorder_start(){
    instance=$1
    #stop perf collector
    docker  \
        $(get_docker_config $instance) \
        exec $instance /opt/perfcorder/run_perfcorder.d.sh
}

perfcorder_stop(){
    instance=$1
    #stop perf collector
    docker  \
        $(get_docker_config $instance) \
        exec -it $instance /opt/perfcorder/stop_perfcorder.sh
}