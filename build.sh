#!/bin/sh -ex
DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 distro arch"
    exit 1
fi

DISTRO=$1
ARCH=$2
apk add rsync sshpass

ls -la
device=rootfs

sed '/allow-hotplug eth0/d' -i bootstrap/build/etc/network/interfaces 
cat bootstrap/build/etc/network/interfaces
docker image import $DIR/bootstrap/bootstrap.tar ${device}
docker run -d --privileged -i --name ${device} -p 22:22 ${device} /sbin/init
./integration/wait-ssh.sh docker root syncloud 22

cd ${DIR}
DOCKER_RUN="docker exec $device"
${DOCKER_RUN} cat /etc/hosts
${DOCKER_RUN} /root/install.sh
${DOCKER_RUN} rm /root/install.sh
${DOCKER_RUN} rm -rf /tmp/*
${DOCKER_RUN} grep localhost /etc/hosts
${DOCKER_RUN} grep nameserver /etc/resolv.conf
${DOCKER_RUN} grep dev /etc/fstab
docker container export --output="docker-rootfs.tar" ${device}

docker stop ${device}
docker stop ${device} || true
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
rsync -avhp --ignore-times --stats bootstrap/files/arch/${ARCH}/ rootfs
rsync -avhp --ignore-times --stats bootstrap/files/distro/${DISTRO}/ rootfs

sync

grep localhost rootfs/etc/hosts
ls -la rootfs/etc/hosts
grep nameserver rootfs/etc/resolv.conf
grep dev rootfs/etc/fstab
grep eth rootfs/etc/network/interfaces

tar czf rootfs-${DISTRO}-${ARCH}.tar.gz -C rootfs .
