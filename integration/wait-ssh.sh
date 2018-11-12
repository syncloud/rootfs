#!/bin/bash -e

DEVICE_HOST=$1
USER=$2
PASSWORD=$3
PORT=$4

attempts=100
attempt=0
DOCKER_RUN="sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no -p $PORT $USER@${DEVICE_HOST}"

set +e
$DOCKER_RUN date
while test $? -gt 0
do
  if [ $attempt -gt $attempts ]; then
    exit 1
  fi
  sleep 3
  echo "Waiting for SSH $attempt"
  attempt=$((attempt+1))
  $DOCKER_RUN date
done
set -e
