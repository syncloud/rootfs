#!/bin/sh -ex
DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}


if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 distro arch"
    exit 1
fi

DISTRO=$1
ARCH=$2
DOMAIN=${ARCH}

apk add sshpass python3 py3-pip

device=rootfs

sed '/allow-hotplug eth0/d' -i rootfs/etc/network/interfaces
tar c -C rootfs . | docker import - ${device}
docker run -d --privileged -i --name ${device} -p 22:22 ${device} /sbin/init

./integration/wait-ssh.sh docker root syncloud 22

sshpass -p syncloud scp -o StrictHostKeyChecking=no test-on-device.sh root@docker:/test-on-device.sh
DOCKER_RUN="sshpass -p syncloud ssh -o StrictHostKeyChecking=no docker"

${DOCKER_RUN} /test-on-device.sh

pip install -r ${DIR}/dev_requirements.txt
cd integration
py.test -sx verify.py --domain=${DOMAIN} --device-host=docker --arch=${ARCH}

docker kill ${device}
docker rm ${device}
docker rmi ${device}
