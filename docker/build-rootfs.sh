#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ -z "$1" ]; then
    echo "usage: $0 arch"
    exit 1
fi

ARCH=$1

set +x
docker login --username=$DOCKER_USERNAME --password=$DOCKER_PASSWORD
set -x

cat rootfs-$(dpkg --print-architecture).tar.gz | docker import - syncloud/rootfs-${ARCH}
docker push syncloud/rootfs-${ARCH}
