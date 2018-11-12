#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$5" ]]; then
    echo "usage $0 redirect_user redirect_password redirect_domain device_host user password"
    exit 1
fi

DOMAIN=$3-${ARCH}-${DRONE_BRANCH}
DEVICE_HOST=$4
USER=$5
PASSWORD=$6

attempts=100
attempt=0

set +e
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no $USER@${DEVICE_HOST} date
while test $? -gt 0
do
  if [ $attempt -gt $attempts ]; then
    exit 1
  fi
  sleep 3
  echo "Waiting for SSH $attempt"
  attempt=$((attempt+1))
  sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no $USER@${DEVICE_HOST} date
done
set -e

pip2 install -r ${DIR}/dev_requirements.txt
pip2 install -U pytest

py.test -sx verify.py --email=$1 --password=$2 --domain=$DOMAIN --device-host=$DEVICE_HOST