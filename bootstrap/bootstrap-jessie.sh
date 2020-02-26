#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ARCH=$(dpkg --print-architecture)
REPO=http://http.debian.net/debian
KEY=https://ftp-master.debian.org/keys/archive-key-8.asc
DISTRO=jessie

echo "Open file limit: $(ulimit -n)"

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
    #lsof 2>&1 | grep $ROOTFS | awk '{print $2}' | sort | uniq | xargs kill -9 || true
    echo "chroot services after kill"
    lsof 2>&1 | grep $ROOTFS || true
}

cleanup

rm -rf ${ROOTFS}
rm -rf rootfs.tar.gz
apt install -y debootstrap
debootstrap --no-check-gpg --include=ca-certificates,locales,sudo,openssh-server,wget,less,parted,unzip,bzip2,curl,dbus,avahi-daemon,ntp,net-tools,wireless-tools,fancontrol --arch=${ARCH} ${DISTRO} ${ROOTFS} ${REPO}

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' ${ROOTFS}/etc/locale.gen
chroot ${ROOTFS} /bin/bash -c "locale-gen en_US en_US.UTF-8"
chroot ${ROOTFS} wget ${KEY} -O archive.key
chroot ${ROOTFS} apt-key add archive.key

mount -v --bind /dev ${ROOTFS}/dev
chroot ${ROOTFS} /bin/bash -c "echo \"root:syncloud\" | chpasswd"

echo "copy system files to get image working"
cp -rf ${DIR}/files/common/* ${ROOTFS}
cp -rf ${DIR}/files/arch/${ARCH}/* ${ROOTFS}
if [[ -d ${DIR}/files/distro/${DISTRO} ]]; then
  cp -rf ${DIR}/files/distro/${DISTRO}/* ${ROOTFS}
fi
sed -i -e'/AVAHI_DAEMON_DETECT_LOCAL/s/1/0/' ${ROOTFS}/etc/default/avahi-daemon
sed -i "s/^.*PermitRootLogin.*/PermitRootLogin yes/g" ${ROOTFS}/etc/ssh/sshd_config

for f in ${DIR}/patches/*.patch
do
  patch -d ${ROOTFS} -p1 < $f
done

umount ${ROOTFS}/dev

cleanup

echo "cleaning apt cache"
rm -rf ${ROOTFS}/var/cache/apt/archives/*.deb

echo "zipping bootstrap"
tar czf bootstrap.tar.gz -C ${ROOTFS} .
