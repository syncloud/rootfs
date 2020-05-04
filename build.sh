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
sed '/auto-hotplug eth0/d' -i bootstrap/build/etc/network/interfaces 
tar cf bootstrap.tar -C bootstrap/build .
docker image import bootstrap.tar ${device}
docker run -d --privileged -i --name ${device} --hostname ${device} --network=drone ${device} /sbin/init
device_ip=$(docker container inspect --format '{{ .NetworkSettings.Networks.drone.IPAddress }}' ${device})
cd ${DIR}
set +e
./integration/wait-ssh.sh ${device_ip} root syncloud 22
code=$?
set -e
if [[ $code -eq 0 ]]; then
    sshpass -p syncloud scp -o StrictHostKeyChecking=no install.sh root@${device_ip}:/root/install.sh
    DOCKER_RUN="sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@$device_ip"
    ${DOCKER_RUN} cat /etc/hosts
    ${DOCKER_RUN} /root/install.sh
    ${DOCKER_RUN} rm /root/install.sh
    ${DOCKER_RUN} rm -rf /tmp/*
    ${DOCKER_RUN} grep localhost /etc/hosts
    ${DOCKER_RUN} grep nameserver /etc/resolv.conf
    ${DOCKER_RUN} grep dev /etc/fstab
fi
docker container export --output="docker-rootfs.tar" ${device}

docker kill ${device}
docker rm ${device}
docker rmi ${device}

rm -rf rootfs
mkdir rootfs
tar xf docker-rootfs.tar -C rootfs
rm -rf docker-rootfs.tar

mkdir log
ls -la rootfs/var/log > log/files.log
cp rootfs/var/log/messages log/messages.log | true
cp rootfs/var/log/auth.log log | true
cp rootfs/var/log/syslog log/syslog.log | true
cp rootfs/var/log/dmesg log/dmesg.log | true
chmod -R a+r log

rsync -avhp --ignore-times --stats bootstrap/files/common/ rootfs
rsync -avhp --ignore-times --stats bootstrap/files/arch/${DEBIAN_ARCH}/ rootfs
rsync -avhp --ignore-times --stats bootstrap/files/distro/${DISTRO}/ rootfs

sync

grep localhost rootfs/etc/hosts
ls -la rootfs/etc/hosts
grep nameserver rootfs/etc/resolv.conf
grep dev rootfs/etc/fstab
grep eth rootfs/etc/network/interfaces

tar czf rootfs-${DISTRO}-${ARCH}.tar.gz -C rootfs .

exit $code
