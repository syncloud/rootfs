#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage: $0 distro arch"
    exit 1
fi

DISTRO=$1
ARCH=$2
../bootstrap/bootstrap-${DISTRO}.sh
docker rmi bootstrap || true
cat bootstrap.tar.gz | docker import - bootstrap
docker build --no-cache -f Dockerfile.deps -t syncloud/build-deps-${DISTRO}-${ARCH} .
docker push syncloud/build-deps-${DISTRO}-${ARCH}
