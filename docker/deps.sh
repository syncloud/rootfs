#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ $(. /etc/os-release; echo $VERSION) =~ .*jessie.* ]]; then
    echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list
fi

apt-get -qq update
xargs apt-get -y install < apt.pkg.list

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install -r python.dev.requirements.txt

ARCH=$(uname -m)
if [ $ARCH == "x86_64" ]; then
  wget --progress dot:giga http://artifact.syncloud.org/3rdparty/phantomjs-2.1.1-linux-x86_64.tar.bz2
  tar xjf phantomjs-2.1.1-linux-x86_64.tar.bz2
  cp ./phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin
else
  wget --progress dot:giga http://artifact.syncloud.org/3rdparty/phantomjs-2.1.1-armhf
  cp phantomjs-2.1.1-armhf /usr/bin/phantomjs
fi
chmod +x /usr/bin/phantomjs

${DIR}/install-sam.sh 85 stable
${DIR}/install-s3cmd.sh

