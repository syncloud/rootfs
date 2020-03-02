#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get update
xargs apt-get install -y < deps.apt.list

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install -r python.dev.requirements.txt

GECKODRIVER=0.24.0
FIREFOX=65.0
ARCH=$(uname -m)

mkdir /tools
cd /tools

if [[ ${ARCH} == "x86_64" ]]; then
    CPU_ARCH=amd64

    wget https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER}/geckodriver-v${GECKODRIVER}-linux64.tar.gz --progress dot:giga
    mkdir /tools/geckodriver
    tar xf geckodriver-v${GECKODRIVER}-linux64.tar.gz -C /tools/geckodriver

    wget https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX}/linux-x86_64/en-US/firefox-${FIREFOX}.tar.bz2 --progress dot:giga
    tar xf firefox-${FIREFOX}.tar.bz2 -C /tools

    wget --progress dot:giga http://artifact.syncloud.org/3rdparty/phantomjs-2.1.1-linux-x86_64.tar.bz2
    tar xjf phantomjs-2.1.1-linux-x86_64.tar.bz2
    cp ./phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin
else
    CPU_ARCH=armv6l
    wget --progress dot:giga http://artifact.syncloud.org/3rdparty/phantomjs-2.1.1-armhf
    cp phantomjs-2.1.1-armhf /usr/bin/phantomjs
fi

chmod +x /usr/bin/phantomjs

${DIR}/install-s3cmd.sh

