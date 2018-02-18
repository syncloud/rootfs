#!/bin/bash -ex
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

#Fix debconf frontend warnings
#export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 release point_to_release installer"
    exit 1
fi

ARCH=$(dpkg --print-architecture)
RELEASE=$1
POINT_TO_RELEASE=$2
INSTALLER=$3

BASE_ROOTFS_ZIP=rootfs-${ARCH}.tar.gz
ROOTFS=${DIR}/rootfs

function cleanup {
    mount | grep $ROOTFS
    mount | grep $ROOTFS | awk '{print "umounting "$1; system("umount "$3)}'
    mount | grep $ROOTFS

    echo "killing chroot services"
    lsof 2>&1 | grep $ROOTFS | grep -v docker | grep -v rootfs.sh | awk '{print $1" "$2}' | sort | uniq

    #lsof 2>&1 | grep $ROOTFS | grep -v docker | grep -v rootfs.sh | awk '{print $2}' | sort | uniq | xargs kill -9

    lsof 2>&1 | grep $ROOTFS
}

ls -la

if [ ! -f ${BASE_ROOTFS_ZIP} ]; then
  echo "${BASE_ROOTFS_ZIP} is not found"
  wget http://artifact.syncloud.org/image/${BASE_ROOTFS_ZIP} --progress dot:giga
else
  echo "rootfs is found"
fi

cleanup || true

rm -rf ${ROOTFS}
mkdir -p ${ROOTFS}

echo "extracting rootfs"

tar xzf ${BASE_ROOTFS_ZIP} -C ${ROOTFS}
rm -rf ${BASE_ROOTFS_ZIP}

#echo "disable service restart"
#cp disable-service-restart.sh ${ROOTFS}/root
#chroot ${ROOTFS} /root/disable-service-restart.sh

echo "configuring rootfs"
#mount -v --bind /dev ${ROOTFS}/dev
#chroot ${ROOTFS} /bin/bash -c "mount -t devpts devpts /dev/pts"
#chroot ${ROOTFS} /bin/bash -c "mount -t proc proc /proc"

cp installer_$INSTALLER.sh ${ROOTFS}/root/installer.sh

docker images

#nohup systemd-nspawn --network-veth -bD ${ROOTFS} -p 2222:22 &
#sleep 60
#systemd-run --wait --pty --machine=rootfs /bin/bash -c "/root/installer.sh ${RELEASE} ${POINT_TO_RELEASE}"

attempts=100
attempt=0

set +e
sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost date
while test $? -gt 0
do
  if [ $attempt -gt $attempts ]; then
    exit 1
  fi
  sleep 3
  echo "Waiting for SSH $attempt"
  attempt=$((attempt+1))
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost date
done
set -e

sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost /bin/bash -c /root/installer.sh ${RELEASE} ${POINT_TO_RELEASE}"

#machinectl -h
#machinectl --version
#machinectl shell rootfs "/bin/bash -c /root/installer.sh ${RELEASE} ${POINT_TO_RELEASE}"

rm ${ROOTFS}/root/installer.sh

#umount ${ROOTFS}/dev/pts
#umount ${ROOTFS}/dev
#umount ${ROOTFS}/proc
rm -rf ${ROOTFS}/tmp/*

cleanup || true

#echo "enable restart"
#cp enable-service-restart.sh ${ROOTFS}/root
#chroot ${ROOTFS} /root/enable-service-restart.sh

rm -rf syncloud-rootfs-${ARCH}-${INSTALLER}.tar.gz
tar czf syncloud-rootfs-${ARCH}-${INSTALLER}.tar.gz -C ${ROOTFS} .
rm -rf ${ROOTFS}