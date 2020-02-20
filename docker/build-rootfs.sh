#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage: $0 distro arch"
    exit 1
fi

DISTRO=$1
ARCH=$2

set +x
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
set -x

cat ../rootfs-$ARCH.tar.gz | docker import - syncloud/rootfs
docker build -f Dockerfile.platform -t syncloud/platform-${DISTRO}-${ARCH} .
docker push syncloud/platform-${DISTRO}-${ARCH}
