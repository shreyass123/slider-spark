#!/bin/bash

set -o pipefail
set -x

groupadd -g 123 hadoop
useradd -u 202 -g 123 yarn
useradd -u 204 -g 123 spark

mkdir -p /var/run/spark
mkdir -p /var/log/spark

chown -R spark:hadoop /opt/apache/spark* /etc/spark /var/run/spark /var/log/spark

# TODO: use /grid/1 disk for /data?
if [[ -e /usr/hdp/current/slider-client/bin/slider ]]; then
    useradd -u 205 -g 123 $SLIDER_APP_USER
    # TODO: figure out a better logic to retrieve spark master?
    SPARK_MASTER=$(sudo -u $SLIDER_APP_USER /usr/hdp/current/slider-client/bin/slider status ${SLIDER_APP_NAME} | \
                   sed -n '/\"MASTER\" :/,/}/p' |grep \"host\" | awk -F\" '{print $4}')
    METASTORE_URI=$(grep "thrift://" /etc/hive/conf/hive-site.xml | sed -n 's:<value>\(.*\)</value>:\1:p' | tr -d '[:space:]')
    SPARK_METASTORE_OPT="\"-Dhive.metastore.uris=${METASTORE_URI}\""
else
    # local docker container
    SPARK_MASTER=$(hostname)
    SPARK_METASTORE_OPT=""
fi
SPARK_WORKER_LOCAL=$(hostname)

sed -i "s/^SPARK_WORKER_MEMORY.*/SPARK_WORKER_MEMORY=${MEM}m/g; \
        s/^SPARK_WORKER_CORES.*/SPARK_WORKER_CORES=${CORES}/g; \
        s@^SPARK_MASTER_IP.*@SPARK_MASTER_IP=${SPARK_MASTER}@g" /etc/spark/conf/spark-env.sh

sed -i "s/^spark.default.parallelism.*/spark.default.parallelism=${CORES}/g; \
        s@^spark.master.*@spark.master=spark://${SPARK_MASTER}:7077@g; \
        s@spark.driver.extraJavaOptions.*@spark.driver.extraJavaOptions=${SPARK_METASTORE_OPT}@g" /etc/spark/conf/spark-defaults.conf

# TODO: set non default ports for spark?
if [[ "${SPARK_MASTER}" == "${SPARK_WORKER_LOCAL}" ]]; then
    #start spark master as well
    sudo -u spark -E /opt/apache/spark/sbin/start-master.sh
fi
sudo -u spark -E /opt/apache/spark/sbin/start-slave.sh spark://$SPARK_MASTER:7077


# Run the app if running on the cluster and we are the master
if [[ -e /usr/hdp/current/slider-client/bin/slider ]]; then
    if [[ "${SPARK_MASTER}" == "${SPARK_WORKER_LOCAL}" ]]; then
        sudo -u $SLIDER_APP_USER -E $SPARK_HOME/bin/hadoop fs -get /user/slider/$SLIDER_APP_NAME /tmp
        sudo -u $SLIDER_APP_USER -E chmod +x /tmp/$SLIDER_APP_NAME/run.sh
        sudo -u $SLIDER_APP_USER -E /tmp/$SLIDER_APP_NAME/run.sh &
    fi
fi

# Leave the container running
/usr/bin/supervisord -c /etc/supervisord.conf
