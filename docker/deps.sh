#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get update
xargs apt-get install -y < apt.pkg.list

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install -r python.dev.requirements.txt

GECKODRIVER=0.14.0
FIREFOX=65.0
GO_VERSION=1.7.6
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

    curl https://raw.githubusercontent.com/mguillem/JSErrorCollector/master/dist/JSErrorCollector.xpi -o /tools/firefox/JSErrorCollector.xpi
    wget --progress dot:giga http://artifact.syncloud.org/3rdparty/phantomjs-2.1.1-linux-x86_64.tar.bz2
    tar xjf phantomjs-2.1.1-linux-x86_64.tar.bz2
    cp ./phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin
else
    CPU_ARCH=armv6l
    wget --progress dot:giga http://artifact.syncloud.org/3rdparty/phantomjs-2.1.1-armhf
    cp phantomjs-2.1.1-armhf /usr/bin/phantomjs
fi

sed -i 's/;phar.readonly = On/phar.readonly = Off/g' /etc/php5/cli/php.ini

chmod +x /usr/bin/phantomjs

wget https://dl.google.com/go/go${GO_VERSION}.linux-${CPU_ARCH}.tar.gz --progress dot:giga
tar xf go${GO_VERSION}.linux-${CPU_ARCH}.tar.gz
rm go${GO_VERSION}.linux-${CPU_ARCH}.tar.gz
mv go go-${GO_VERSION}
ln -s go-${GO_VERSION} go

export GOROOT=.
/tools/go/bin/go version

${DIR}/install-s3cmd.sh

