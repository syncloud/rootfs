#!/bin/bash -xe

echo "Running from: $PWD"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 release point_to_release"
    exit 1
fi

RELEASE=$1
POINT_TO_RELEASE=$2

SAM_VERSION=85
SAM_ARCH=$(uname -m)

#Fix debconf frontend warnings
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBCONF_FRONTEND=noninteractive
export DEBIAN_FRONTEND=noninteractive

SAM=sam-${SAM_VERSION}-${SAM_ARCH}.tar.gz
wget http://apps.syncloud.org/apps/${SAM} --progress=dot:giga -O ${SAM}
tar xzf ${SAM} -C /opt/app

/opt/app/sam/bin/sam --debug update --release ${RELEASE}
/opt/app/sam/bin/sam --debug upgrade_all
#This is needed to make sure that update is properly done on fresh platform
/opt/app/sam/bin/sam --debug update --release ${RELEASE}
/opt/app/sam/bin/sam list
/opt/app/sam/bin/sam set_release ${POINT_TO_RELEASE}