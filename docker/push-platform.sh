#!/bin/sh -xe

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

DISTRO=$1
ARCH=$2

TAG=latest
if [ -n "$DRONE_TAG" ]; then
    TAG=$DRONE_TAG
fi
IMAGE="syncloud/platform-${DISTRO}-${ARCH}:$TAG"

set +ex
while ! docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD; do
  echo "retry login"
  sleep 10
done
set -ex

docker rmi rootfs || true
cat ../rootfs-${DISTRO}-${ARCH}.tar.gz | docker import - rootfs
docker build -f Dockerfile.platform -t ${IMAGE} .

set -ex
while ! docker push ${IMAGE}; do
  echo "retry push"
  sleep 10
done
set +ex
