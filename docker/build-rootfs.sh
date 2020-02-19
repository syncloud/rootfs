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

cat rootfs-$ARCH.tar.gz | docker import - syncloud/rootfs
docker build -f Dockerfile.platform -t syncloud/platform-${ARCH} .
docker push syncloud/platform-${ARCH}
