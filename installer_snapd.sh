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

VERSION=$(curl http://apps.syncloud.org/releases/${CHANNEL}/snapd.version)

SNAPD=snapd-${VERSION}-${ARCH}.tar.gz
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