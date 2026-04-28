#!/bin/sh -ex
DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 arch"
    exit 1
fi

ARCH=$1
DISTRO=buster

# Buster apt repos are EOL — we no longer debootstrap. Instead, refresh a
# pinned, last-known-good platform-buster image by re-running the snap-based
# install (snapd tarball + snap install platform), which doesn't need apt.
BASE_IMAGE="syncloud/platform-buster-${ARCH}:25.02"

apk add rsync sshpass

device=rootfs
docker pull ${BASE_IMAGE}
docker tag ${BASE_IMAGE} ${device}
docker run -d --privileged -i --name ${device} -p 22:22 ${device} /sbin/init
./integration/wait-ssh.sh docker root syncloud 22

DOCKER_RUN="docker exec ${device}"
docker cp $DIR/install.sh ${device}:/root/install.sh
${DOCKER_RUN} chmod +x /root/install.sh
${DOCKER_RUN} /root/install.sh
${DOCKER_RUN} rm /root/install.sh
docker cp $DIR/v2-services ${device}:/root/v2-services
docker cp $DIR/install-v2-services.sh ${device}:/root/install-v2-services.sh
${DOCKER_RUN} chmod +x /root/install-v2-services.sh
${DOCKER_RUN} /root/install-v2-services.sh
${DOCKER_RUN} rm /root/install-v2-services.sh
${DOCKER_RUN} rm -rf /tmp/*
docker container export --output="docker-rootfs.tar" ${device}

docker stop ${device} || true
docker rm ${device}
docker rmi ${device}
docker rmi ${BASE_IMAGE} || true

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

tar czf rootfs-${DISTRO}-${ARCH}.tar.gz -C rootfs .
