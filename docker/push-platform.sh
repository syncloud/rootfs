#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage: $0 distro arch"
    exit 1
fi

DISTRO=$1
ARCH=$2
apt update
apt install -y libltdl7 libnss3 

if [[ ${DISTRO} == "buster" ]]; then
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

while ! docker push ${IMAGE}; do
  echo "retry push"
  sleep 10
done