#!/bin/bash -ex
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 release point_to_release arch"
    exit 1
fi

RELEASE=$1
POINT_TO_RELEASE=$2
ARCH=$3
DEBIAN_ARCH=$(dpkg --print-architecture)

BOOTSTRAP_ROOTFS_ZIP=bootstrap-${ARCH}.tar.gz

ls -la

if [ ! -f ${BOOTSTRAP_ROOTFS_ZIP} ]; then
  echo "${BOOTSTRAP_ROOTFS_ZIP} is not found"
  wget http://artifact.syncloud.org/image/${BASE_ROOTFS_ZIP} --progress dot:giga
else
  echo "bootstrap rootfs is found"
fi

docker kill rootfs || true
docker rm rootfs || true
docker rmi rootfs || true
docker import ${BOOTSTRAP_ROOTFS_ZIP} rootfs
docker run -d --privileged -i -p 2222:22 --name rootfs rootfs /sbin/init

./integration/wait-ssh.sh localhost root syncloud 2222

sshpass -p syncloud scp -o StrictHostKeyChecking=no -P 2222 install.sh root@localhost:/root/install.sh
DOCKER_RUN="sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost"
$DOCKER_RUN /root/install.sh ${RELEASE} ${POINT_TO_RELEASE}
$DOCKER_RUN rm /root/install.sh
$DOCKER_RUN rm -rf /tmp/*

docker kill rootfs
docker export rootfs | gzip > docker-rootfs-${ARCH}.tar.gz
docker rm rootfs
docker rmi rootfs

rm -rf rootfs
mkdir rootfs
tar xzf docker-rootfs-${ARCH}.tar.gz -C rootfs
rm -rf docker-rootfs-${ARCH}.tar.gz
cp ${DIR}/bootstrap/${DEBIAN_ARCH}/etc/hosts rootfs/etc/hosts
cat rootfs/etc/hosts
tar czf rootfs-${ARCH}.tar.gz -C rootfs .
rm -rf rootfs
