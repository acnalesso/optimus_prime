#!/bin/bash

echo "Starting optimus prime"
echo $ENV
echo $VCAP_APP_PORT
ENV=$ENV thin start -R config.ru -p $VCAP_APP_PORT --threaded --threadpool-size 16 -e $ENV
echo "OP has been started"
