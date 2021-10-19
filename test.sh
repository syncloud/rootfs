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
DOMAIN=${ARCH}

apt update
apt install -y libltdl7 libnss3 sshpass netcat

device=rootfs
docker kill ${device} || true
docker rm ${device} || true
docker rmi ${device} || true
sed '/allow-hotplug eth0/d' -i rootfs/etc/network/interfaces
tar c -C rootfs . | docker import - ${device}
docker run -d --privileged -i --name ${device} --hostname ${device} --network=drone ${device} /sbin/init
device_ip=$(docker container inspect --format '{{ .NetworkSettings.Networks.drone.IPAddress }}' ${device})
./integration/wait-ssh.sh ${device_ip} root syncloud 22

sshpass -p syncloud scp -o StrictHostKeyChecking=no test-on-device.sh root@${device_ip}:/test-on-device.sh
DOCKER_RUN="sshpass -p syncloud ssh -o StrictHostKeyChecking=no root@$device_ip"

${DOCKER_RUN} /test-on-device.sh

pip install -r ${DIR}/dev_requirements.txt
cd integration
py.test -sx verify.py --domain=${DOMAIN} --device-host=${device_ip} --arch=${ARCH}

docker kill ${device}
docker rm ${device}
docker rmi ${device}
