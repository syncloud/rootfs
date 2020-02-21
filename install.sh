#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get update
apt-get -y install sudo openssh-server wget less parted lsb-release unzip bzip2 curl ntp net-tools wireless-tools
echo "root:syncloud" | chpasswd
sed -i "s/^.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart ssh

ARCH=$(dpkg --print-architecture)
VERSION=$(curl http://apps.syncloud.org/releases/stable/snapd.version)
SNAPD=snapd-${VERSION}-${ARCH}.tar.gz
systemctl disable apt-daily.timer
systemctl disable apt-daily.service
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service

wget http://apps.syncloud.org/apps/${SNAPD} --progress=dot:giga

tar xzvf ${SNAPD}
systemctl stop snapd.service snapd.socket || true
systemctl disable snapd.service snapd.socket || true

rm -rf /var/lib/snapd
mkdir /var/lib/snapd

rm -rf /usr/lib/snapd
mkdir -p /usr/lib/snapd
cp snapd/bin/snapd /usr/lib/snapd
cp snapd/bin/snap-exec /usr/lib/snapd
cp snapd/bin/snap-confine /usr/lib/snapd
cp snapd/bin/snap-discard-ns /usr/lib/snapd
cp snapd/bin/snap /usr/bin
cp snapd/bin/snapctl /usr/bin
cp snapd/bin/mksquashfs /usr/bin
cp snapd/bin/unsquashfs /usr/bin

mkdir -p /usr/lib/snapd/lib
cp snapd/lib/* /usr/lib/snapd/lib

cp snapd/conf/snapd.service /lib/systemd/system/
cp snapd/conf/snapd.socket /lib/systemd/system/

systemctl enable snapd.service
systemctl enable snapd.socket
systemctl start snapd.service snapd.socket

snap --version
strings /lib/systemd/libsystemd-shared-*.so | grep LZ4F_createDecompressionContext || true
snap install platform
