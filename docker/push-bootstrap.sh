#!/bin/sh -e

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

DISTRO=$1
ARCH=$2
TAG=latest
if [ -n "$DRONE_TAG" ]; then
    TAG=$DRONE_TAG
fi

IMAGE="syncloud/bootstrap-${DISTRO}-${ARCH}:$TAG"

set +ex
while ! docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD; do
  echo "retry login"
  sleep 10
done
set -ex

docker kill bootstrap || true
docker rm bootstrap || true
docker rmi bootstrap || true
cat $DIR/../bootstrap/bootstrap.tar | docker import - bootstrap
docker build --no-cache -f Dockerfile.bootstrap -t ${IMAGE} .

set -ex
while ! docker push ${IMAGE}; do
  echo "retry push"
  sleep 10
done
set +ex
