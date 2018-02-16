#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [ "$#" -lt 2 ]; then
    echo "usage $0 device_host release point_to_release installer"
    exit 1
fi

DEVICE_HOST=$1
RELEASE=$2
POINT_TO_RELEASE=$3
INSTALLER=$4
ARCH=$(dpkg --print-architecture)
BASE_ROOTFS_ZIP=rootfs-${ARCH}.tar.gz

ls -la

if [ ! -f ${BASE_ROOTFS_ZIP} ]; then
  echo "${BASE_ROOTFS_ZIP} not found"
  exit 1
fi

attempts=100
attempt=0

set +e
sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@${DEVICE_HOST} date
while test $? -gt 0
do
  if [ $attempt -gt $attempts ]; then
    exit 1
  fi
  sleep 3
  echo "Waiting for SSH $attempt"
  attempt=$((attempt+1))
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@${DEVICE_HOST} date
done
set -e

sshpass -p syncloud scp -o StrictHostKeyChecking=no rootfs.sh root@${DEVICE_HOST}:/
sshpass -p syncloud scp -o StrictHostKeyChecking=no installer_* root@${DEVICE_HOST}:/
sshpass -p syncloud scp -o StrictHostKeyChecking=no $BASE_ROOTFS_ZIP root@${DEVICE_HOST}:/

sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@${DEVICE_HOST} /rootfs.sh $RELEASE $POINT_TO_RELEASE $INSTALLER
sshpass -p syncloud scp -o StrictHostKeyChecking=no root@${DEVICE_HOST}:/syncloud-rootfs-${ARCH}-${INSTALLER}.tar.gz .