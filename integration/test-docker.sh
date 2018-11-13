#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$1" ]]; then
    echo "usage $0 device_host"
    exit 1
fi

REDIRECT_USER=teamcity@syncloud.it
REDIRECT_PASSWORD=password
DEVICE_HOST=$1
DOMAIN=$DEVICE_HOST-${ARCH}-${DRONE_BRANCH}

pip2 install -r ${DIR}/dev_requirements.txt
pip2 install -U pytest

py.test -sx verify.py --email=$REDIRECT_USER --password=$REDIRECT_PASSWORD --domain=$DOMAIN --device-host=$DEVICE_HOST