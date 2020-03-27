#!/bin/bash -ex
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 distro arch"
    exit 1
fi

DISTRO=$1
ARCH=$2
DEBIAN_ARCH=$(dpkg --print-architecture)
DOMAIN=${ARCH}-${DRONE_BRANCH}

ls -la
device=rootfs
docker kill ${device} || true
docker rm ${device} || true
docker rmi ${device} || true
docker import bootstrap.tar.gz ${device}
docker run -d --privileged -i --name ${device} --hostname ${device} --network=drone ${device} /sbin/init
device_ip=$(docker container inspect --format '{{ .NetworkSettings.Networks.drone.IPAddress }}' ${device})
./integration/wait-ssh.sh ${device_ip} root syncloud 22

sshpass -p syncloud scp -o StrictHostKeyChecking=no install.sh root@${device_ip}:/root/install.sh
DOCKER_RUN="sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@$device_ip"
${DOCKER_RUN} cat /etc/hosts
${DOCKER_RUN} /root/install.sh
${DOCKER_RUN} rm /root/install.sh
${DOCKER_RUN} rm -rf /tmp/*

docker export ${device} | gzip > docker-rootfs.tar.gz

cd ${DIR}
docker kill ${device}
docker rm ${device}
docker rmi ${device}

rm -rf rootfs
mkdir rootfs
tar xzf docker-rootfs.tar.gz -C rootfs
cat rootfs/etc/hosts

rm -rf docker-rootfs.tar.gz

tar czf rootfs-${DISTRO}-${ARCH}.tar.gz -C rootfs .
rm -rf rootfs
