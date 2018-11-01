#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ARCH=$(dpkg --print-architecture)

if [ "$#" -lt 2 ]; then
    CHANNEL=stable
    POINT_TO_CHANNEL=stable
else
    CHANNEL=$1
    POINT_TO_CHANNEL=$2
fi
echo "root:syncloud" | chpasswd

apt-get update
apt-get -y install sudo openssh-server wget less parted lsb-release unzip bzip2 curl ntp net-tools wireless-tools

VERSION=$(curl http://apps.syncloud.org/releases/${CHANNEL}/snapd.version)

SNAPD=snapd-${VERSION}-${ARCH}.tar.gz
systemctl disable apt-daily.timer
systemctl disable apt-daily.service
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service

ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys
sed -i "s/^.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart ssh

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
cp snapd/lib/* /lib/$HOSTTYPE-$OSTYPE

cp snapd/conf/snapd.service /lib/systemd/system/
cp snapd/conf/snapd.socket /lib/systemd/system/

systemctl enable snapd.service
systemctl enable snapd.socket
systemctl start snapd.service snapd.socket

snap --version
snap install platform --channel=${CHANNEL}
snap switch platform --channel=${POINT_TO_CHANNEL}