#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ARCH=$1
DEB_ARCH=$(dpkg --print-architecture)
REPO=http://http.debian.net/debian
KEY=https://ftp-master.debian.org/keys/archive-key-12.asc
DISTRO=bookworm

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
apt update
apt install -y debootstrap rsync
debootstrap --no-check-gpg --include=\
avahi-daemon,\
bzip2,\
ca-certificates,\
curl,\
dbus,\
fancontrol,\
gnupg,\
less,\
locales,\
net-tools,\
ntp,\
openssh-server,\
parted,\
rsync,\
sudo,\
unzip,\
wget,\
wireless-tools \
--arch=${DEB_ARCH} ${DISTRO} ${ROOTFS} ${REPO}

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' ${ROOTFS}/etc/locale.gen
echo "LC_ALL=en_US.UTF-8" >> ${ROOTFS}/etc/environment
chroot ${ROOTFS} /bin/bash -c "locale-gen en_US en_US.UTF-8"
chroot ${ROOTFS} wget ${KEY} -O archive.key
chroot ${ROOTFS} apt-key add archive.key
mount -v --bind /dev ${ROOTFS}/dev
chroot ${ROOTFS} /bin/bash -c "echo \"root:syncloud\" | chpasswd"

echo "copy system files to get image working"
rsync -avhp --ignore-times --stats ${DIR}/files/common/ ${ROOTFS}
rsync -avhp --ignore-times --stats ${DIR}/files/arch/${ARCH}/ ${ROOTFS}
rsync -avhp --ignore-times --stats ${DIR}/files/distro/${DISTRO}/ ${ROOTFS}
cp $DIR/../install.sh ${ROOTFS}/root
grep localhost ${ROOTFS}/etc/hosts
grep dev ${ROOTFS}/etc/fstab
ls -la ${ROOTFS}/etc/network
grep eth ${ROOTFS}/etc/network/interfaces

sed -i -e'/AVAHI_DAEMON_DETECT_LOCAL/s/1/0/' ${ROOTFS}/etc/default/avahi-daemon
sed -i "s/^.*PermitRootLogin.*/PermitRootLogin yes/g" ${ROOTFS}/etc/ssh/sshd_config

umount ${ROOTFS}/dev
cleanup

echo "cleaning apt cache"
rm -rf ${ROOTFS}/var/cache/apt/archives/*.deb
tar cf $DIR/bootstrap.tar -C $ROOTFS .
