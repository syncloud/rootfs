#!/bin/bash -xe
# Buster apt repos are EOL — skip apt. curl is already in the base image.
VERSION=$(curl http://apps.syncloud.org/releases/stable/snapd2.version)
ARCH=$(dpkg --print-architecture)
SNAPD=snapd-${VERSION}-${ARCH}.tar.gz

cd /tmp
rm -rf "${SNAPD}"
rm -rf snapd
wget http://apps.syncloud.org/apps/"${SNAPD}" --progress=dot:giga
tar xzvf "${SNAPD}"
./snapd/install.sh
while ! snap install platform; do
  echo "retry"
  sleep 10
done
