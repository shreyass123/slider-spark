#!/bin/bash
if [[ "$1" == "" || "$2" == "" ]];then
    echo "Usage: launch.sh <app-name> <run.sh-folder>"
    exit 1
fi
APP_NAME=$1
RUN_FOLDER=$2
hadoop fs -mkdir -p /user/slider/$APP_NAME
if [[ "$?" != "0" ]]; then
    echo "ERROR: failed to create HDFS directory /user/slider/$APP_NAME. Please make sure /user/slider exists on hdfs and is writable by this user."
    exit 1
fi

if [[ ! -e "${RUN_FOLDER}/run.sh" ]]; then
    echo "ERROR: Missing run.sh script in $RUN_FOLDER. This should have a spark-submit command. Look in example folder for an example"
    exit 1
fi

hadoop fs -put -f $2/* /user/slider/$APP_NAME || true

sed "s/@SLIDER_APP_NAME@/SLIDER_APP_NAME=$APP_NAME/g; \
     s/@SLIDER_APP_USER@/SLIDER_APP_USER=$USER/g; \
     s/@MEM@/MEM=4096/g; \
     s/@CORES@/CORES=4/g" appConfig.json.template > appConfig.json
slider create $1 --template appConfig.json --metainfo metainfo.json --resources resources.json

# Wait for slider to launch the containers
sleep 10

SPARK_MASTER=$(slider status ${APP_NAME} | \
               sed -n '/\"MASTER\" :/,/}/p' |grep \"host\" | awk -F\" '{print $4}')
APP_ID=$(slider status ${APP_NAME} | sed -n '/\"info\" :/,/}/p' | \
         grep \"info.am.app.id\" | awk -F\" '{print $4}')
RM_ADDR=$(hdfs getconf -confKey yarn.resourcemanager.webapp.address)
APP_MASTER=http://$RM_ADDR/proxy/$APP_ID
echo "SPARK_MASTER running on $SPARK_MASTER. Check http://${SPARK_MASTER}:8080 for status of the spark job."
echo "If this is the first time running this or the docker images have changed significantly. It will take a few minutes to launch."
echo "You can also check the status of slider at $APP_MASTER"