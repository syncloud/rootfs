#!/bin/bash -ex
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 release point_to_release installer"
    exit 1
fi

ARCH=$(dpkg --print-architecture)
RELEASE=$1
POINT_TO_RELEASE=$2
INSTALLER=$3

BASE_ROOTFS_ZIP=rootfs-${ARCH}.tar.gz

ls -la

if [ ! -f ${BASE_ROOTFS_ZIP} ]; then
  echo "${BASE_ROOTFS_ZIP} is not found"
  wget http://artifact.syncloud.org/image/${BASE_ROOTFS_ZIP} --progress dot:giga
else
  echo "rootfs is found"
fi

docker kill rootfs || true
docker rm rootfs || true
docker rmi rootfs || true
docker import ${BASE_ROOTFS_ZIP} rootfs
docker run -d --privileged -i -p 2222:22 --name rootfs rootfs /sbin/init

attempts=100
attempt=0

set +e
sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost date
while test $? -gt 0
do
  if [ $attempt -gt $attempts ]; then
    exit 1
  fi
  sleep 3
  echo "Waiting for SSH $attempt"
  attempt=$((attempt+1))
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost date
done
set -e

sshpass -p syncloud scp -o StrictHostKeyChecking=no -P 2222 installer_${INSTALLER}.sh root@localhost:/root/installer.sh
sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost /root/installer.sh ${RELEASE} ${POINT_TO_RELEASE}
sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost rm /root/installer.sh
sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost rm -rf /tmp/*
docker kill rootfs
docker export rootfs | gzip > syncloud-rootfs-${ARCH}-${INSTALLER}.tar.gz
docer rm rootfs
docer rmi rootfs
