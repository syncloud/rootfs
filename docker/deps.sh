#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get -qq update
apt-get install kpartx pigz pxz parted \
    wget p7zip unzip dosfstools xz-utils \
    debootstrap lsof ssh sshpass python \
    build-essential \
    libxml2-dev autoconf libjpeg-dev libpng12-dev libfreetype6-dev \
    libzip-dev zlib1g-dev dpkg-dev \
    libpq-dev libreadline-dev libldap2-dev libsasl2-dev libssl-dev libldb-dev \
    libtool wget cmake libncurses5-dev libldap2-dev libsasl2-dev libssl-dev libldb-dev \
    uuid-dev libjansson-dev libxslt1-dev liburiparser1 libxml2 sqlite3 libsqlite3-dev libicu-dev \
    libsrtp0-dev libspeex1 libspeex-dev libspeexdsp1 libspeexdsp-dev libgsm1-dev autoconf debconf-utils libopus-dev \
    libvorbis-dev nettle-dev libncurses5-dev libldap2-dev libsasl2-dev libssl-dev libldb-dev \
    libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev \
    asciidoc xmlto docbook2x autoconf dpkg-dev \
    flex bison libreadline-dev zlib1g-dev \
    libpcre3-dev libdb5.3-dev libsasl2-dev groff \
    libffi-dev libxml2-dev autoconf libjpeg-dev libpng-dev libfreetype6-dev \
    libzip-dev zlib1g-dev libcurl4-openssl-dev dpkg-dev \
    libpq-dev libreadline-dev libldap2-dev libsasl2-dev libssl-dev libldb-dev \
    p7zip libtool libmcrypt-dev libicu-dev \
    libxml2-dev autoconf libjpeg-dev libpng-dev libfreetype6-dev \
    libzip-dev zlib1g-dev dpkg-dev \
    libpq-dev libreadline-dev libldap2-dev libsasl2-dev libssl-dev libldb-dev \
    p7zip libtool libmcrypt-dev libicu-dev libldap2-dev libsasl2-dev libssl-dev \
    libldb-dev libdb-dev libreadline-dev zlib1g-dev \
    libpcre3-dev libbz2-dev libsqlite3-dev unzip libffi-dev \
    libestr-dev libjson-c-dev uuid-dev libgcrypt20-dev liblogging-stdlog-dev pkg-config zlib1g-dev \
    python-dev

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

if [ ! -f /usr/bin/s3cmd ]; then
    ${DIR}/install-s3cmd.sh
fi
