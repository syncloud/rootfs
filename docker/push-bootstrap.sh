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
    IMAGE="syncloud/bootstrap-${ARCH}"
else
    IMAGE="syncloud/bootstrap-${DISTRO}-${ARCH}"
fi
BOOTSTRAP_DIR=$DIR/../bootstrap
$BOOTSTRAP_DIR/bootstrap-${DISTRO}.sh
docker kill bootstrap || true
docker rm bootstrap || true
docker rmi bootstrap || true
cat $BOOTSTRAP_DIR/bootstrap.tar | docker import - bootstrap
docker build --no-cache -f Dockerfile.bootstrap -t ${IMAGE} .
docker push ${IMAGE}

