#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ARCH=$(dpkg --print-architecture)
if [[ ${ARCH} == "amd64" ]]; then
  REPO=http://archive.ubuntu.com/ubuntu
else
  REPO=http://ports.ubuntu.com
fi
DISTRO=eoan

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive
export TMPDIR=/tmp
export TMP=/tmp

ROOTFS=${DIR}/build

function cleanup {

    mount | grep $ROOTFS || true
    mount | grep $ROOTFS | awk '{print "umounting "$1; system("umount "$3)}' || true
    mount | grep $ROOTFS || true

    echo "killing chroot services"
    lsof 2>&1 | grep $ROOTFS | awk '{print $1 $2}' | sort | uniq
    echo "chroot services after kill"
    lsof 2>&1 | grep $ROOTFS || true
}

cleanup

rm -rf ${ROOTFS}
wget http://archive.ubuntu.com/ubuntu/pool/main/d/debootstrap/debootstrap_1.0.117ubuntu1_all.deb
dpkg --install debootstrap_1.0.117ubuntu1_all.deb
debootstrap --no-check-gpg --include=ca-certificates,locales,sudo,openssh-server,wget,less,parted,unzip,bzip2,curl,dbus,avahi-daemon,net-tools,wireless-tools --arch=${ARCH} ${DISTRO} ${ROOTFS} ${REPO}

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' ${ROOTFS}/etc/locale.gen
chroot ${ROOTFS} /bin/bash -c "locale-gen en_US en_US.UTF-8"
mount -v --bind /dev ${ROOTFS}/dev
chroot ${ROOTFS} /bin/bash -c "echo \"root:syncloud\" | chpasswd"

echo "copy system files to get image working"
cp -rf ${DIR}/files/common/* ${ROOTFS}/
cp -rf ${DIR}/files/arch/${ARCH}/* ${ROOTFS}/
cp -rf ${DIR}/files/distro/${DISTRO}/* ${ROOTFS}/

sed -i -e'/AVAHI_DAEMON_DETECT_LOCAL/s/1/0/' ${ROOTFS}/etc/default/avahi-daemon
sed -i "s/^.*PermitRootLogin.*/PermitRootLogin yes/g" ${ROOTFS}/etc/ssh/sshd_config

cleanup

echo "cleaning apt cache"
rm -rf ${ROOTFS}/var/cache/apt/archives/*.deb

cat ${ROOTFS}/etc/hosts

echo "zipping bootstrap"
tar czf bootstrap.tar.gz -C ${ROOTFS} .
