#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$3" ]]; then
    echo "usage $0 redirect_user redirect_password device_host"
    exit 1
fi

DEVICE_HOST=$3
DOMAIN=$DEVICE_HOST-${ARCH}-${DRONE_BRANCH}

pip2 install -r ${DIR}/dev_requirements.txt
pip2 install -U pytest

py.test -sx verify.py --email=$1 --password=$2 --domain=$DOMAIN --device-host=$DEVICE_HOST