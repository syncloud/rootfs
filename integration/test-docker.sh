#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$1" ]]; then
    echo "usage $0 device_host"
    exit 1
fi

DEVICE_HOST=$1
DEVICE_PORT=$2
DOMAIN=$DEVICE_HOST-${ARCH}-${DRONE_BRANCH}

pip2 install -r ${DIR}/dev_requirements.txt
pip2 install -U pytest

py.test -sx verify.py --domain=$DOMAIN --device-host=$DEVICE_HOST --device-port=$DEVICE_PORT