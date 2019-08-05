#!/bin/bash -ex
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -lt 3 ]]; then
    echo "Usage: $0 release point_to_release arch"
    exit 1
fi

RELEASE=$1
POINT_TO_RELEASE=$2
ARCH=$3
DEBIAN_ARCH=$(dpkg --print-architecture)
DOMAIN=${ARCH}-${DRONE_BRANCH}

BOOTSTRAP_ROOTFS_ZIP=bootstrap-${ARCH}.tar.gz

ls -la

docker kill rootfs || true
docker rm rootfs || true
docker rmi rootfs || true
docker import ${BOOTSTRAP_ROOTFS_ZIP} rootfs
docker run -d --privileged -i --name rootfs --network=drone rootfs /sbin/init
device_host=$(docker container inspect --format '{{ .NetworkSettings.IPAddress }}' rootfs)
#device_host=rootfs
./integration/wait-ssh.sh ${device_host} root syncloud 22

sshpass -p syncloud scp -o StrictHostKeyChecking=no install.sh root@${device_host}:/root/install.sh
DOCKER_RUN="sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@$device_host"
${DOCKER_RUN} /root/install.sh ${RELEASE} ${POINT_TO_RELEASE}
${DOCKER_RUN} rm /root/install.sh
${DOCKER_RUN} rm -rf /tmp/*

docker export rootfs | gzip > docker-rootfs-${ARCH}.tar.gz

#test
pip2 install -r ${DIR}/dev_requirements.txt
cd integration
py.test -sx verify.py --domain=${DOMAIN} --device-host=${device_host}
cd ${DIR}
docker kill rootfs
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
