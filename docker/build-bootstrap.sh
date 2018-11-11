#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ -z "$1" ]; then
    echo "usage: $0 arch"
    exit 1
fi

ARCH=$1

set +x
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
set -x

cat bootstrap-$(dpkg --print-architecture).tar.gz | docker import - syncloud/bootstrap-${ARCH}
docker push syncloud/bootstrap-${ARCH}
