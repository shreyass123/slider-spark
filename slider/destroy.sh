#!/bin/bash

if [[ "$1" == "" ]];then
    echo "Usage: destroy.sh <app-name>"
    exit 1
fi
slider stop $1
slider destroy $1 --force

hadoop fs -rm -r /user/slider/$1
