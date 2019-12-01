#!/bin/bash -ex
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 arch"
    exit 1
fi

ARCH=$1
DEBIAN_ARCH=$(dpkg --print-architecture)
DOMAIN=${ARCH}-${DRONE_BRANCH}

BOOTSTRAP_ROOTFS_ZIP=bootstrap-${ARCH}.tar.gz

ls -la
device=rootfsvm
docker kill ${device} || true
docker rm ${device} || true
docker rmi ${device} || true
docker import ${BOOTSTRAP_ROOTFS_ZIP} ${device}
docker run -d --privileged -i --name ${device} --hostname ${device} --network=drone ${device} /sbin/init

./integration/wait-ssh.sh ${device} root syncloud 22

sshpass -p syncloud scp -o StrictHostKeyChecking=no install.sh root@${device}:/root/install.sh
DOCKER_RUN="sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@$device"
${DOCKER_RUN} /root/install.sh
${DOCKER_RUN} rm /root/install.sh
${DOCKER_RUN} rm -rf /tmp/*

docker export ${device} | gzip > docker-rootfs-${ARCH}.tar.gz

#test
pip2 install -r ${DIR}/dev_requirements.txt
cd integration
py.test -sx verify.py --domain=${DOMAIN} --device-host=${device}
cd ${DIR}
docker kill ${device}
docker rm ${device}
docker rmi ${device}

rm -rf rootfs
mkdir rootfs
tar xzf docker-rootfs-${ARCH}.tar.gz -C rootfs
rm -rf docker-rootfs-${ARCH}.tar.gz
cp ${DIR}/bootstrap/${DEBIAN_ARCH}/etc/hosts rootfs/etc/hosts
cat rootfs/etc/hosts
tar czf rootfs-${ARCH}.tar.gz -C rootfs .
rm -rf rootfs
