#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage: $0 distro arch"
    exit 1
fi

DISTRO=$1
ARCH=$2

if [[ ${DISTRO} == "jessie" ]]; then
    IMAGE="syncloud/platform-${ARCH}"
else
    IMAGE="syncloud/platform-${DISTRO}-${ARCH}"
fi

set +x
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
set -x

docker rmi rootfs || true
cat ../rootfs-${DISTRO}-${ARCH}.tar.gz | docker import - rootfs
docker build -f Dockerfile.platform -t ${IMAGE} .
docker push ${IMAGE}
