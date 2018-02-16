#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [ -z "$1" ]; then
    echo "usage: $0 arch"
    exit 1
fi

ARCH=$1
docker build -f Dockerfile.deps.systemd.${ARCH} -t syncloud/build-deps-systemd-${ARCH} .
docker push syncloud/build-deps-systemd-${ARCH}
