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
    IMAGE="syncloud/build-deps-${ARCH}"
else
    IMAGE="syncloud/build-deps-${DISTRO}-${ARCH}"
fi

../bootstrap/bootstrap-${DISTRO}.sh
docker rmi bootstrap || true
cat bootstrap.tar.gz | docker import - bootstrap
cp deps.apt.list.${DISTRO} deps.apt.list
docker build --no-cache -f Dockerfile.deps -t ${IMAGE} .
docker push ${IMAGE}

