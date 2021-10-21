#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage: $0 distro arch"
    exit 1
fi
apt update
apt install -y libltdl7 libnss3 

DISTRO=$1
ARCH=$2
if [[ ${DISTRO} == "jessie" ]]; then
    IMAGE="syncloud/bootstrap-${ARCH}"
else
    IMAGE="syncloud/bootstrap-${DISTRO}-${ARCH}"
fi

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