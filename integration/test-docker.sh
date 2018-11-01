#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$5" ]]; then
    echo "usage $0 redirect_user redirect_password redirect_domain release device_host user password"
    exit 1
fi

RELEASE=$4
DEVICE_HOST=$5
USER=$6
PASSWORD=$7

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

sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no install.sh $USER@${DEVICE_HOST}:./install.sh

sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no $USER@${DEVICE_HOST} sudo ./install.sh

pip2 install -r ${DIR}/dev_requirements.txt
pip2 install -U pytest

py.test -sx verify.py --email=$1 --password=$2 --domain=$3 --release=$4 --device-host=$DEVICE_HOST