#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [ -z "$1" ]; then
    echo "usage: $0 arch"
    exit 1
fi

ARCH=$1
docker build -f Dockerfile.systemd.${ARCH} -t syncloud/systemd-${ARCH} .

set +x
docker login --username=$DOCKER_USERNAME --password=$DOCKER_PASSWORD
set -x

docker push syncloud/systemd-${ARCH}
