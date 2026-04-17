#!/bin/bash -ex

# Install v2 (RAUC A/B update) services into rootfs
# All services are installed MASKED so v1 images are unaffected.
# image-v2 unmasks them and writes board-specific RAUC config during assembly.

# Install rauc
DEBIAN_FRONTEND=noninteractive apt-get install -y rauc

# Install service scripts
mkdir -p /usr/lib/syncloud
cp /root/v2-services/data-init.sh /usr/lib/syncloud/
cp /root/v2-services/syncloud-update.sh /usr/lib/syncloud/
chmod +x /usr/lib/syncloud/data-init.sh /usr/lib/syncloud/syncloud-update.sh

# Install systemd units to /usr/lib/systemd/system (package location)
# Masking in /etc/systemd/system takes precedence over /usr/lib/systemd/system
cp /root/v2-services/syncloud-data-init.service /usr/lib/systemd/system/
cp /root/v2-services/syncloud-update.service /usr/lib/systemd/system/
cp /root/v2-services/syncloud-update.timer /usr/lib/systemd/system/
cp /root/v2-services/syncloud-boot-ok.service /usr/lib/systemd/system/

# Mask all v2 services so v1 images are unaffected
# image-v2 removes these masks during assembly to enable them
ln -sf /dev/null /etc/systemd/system/syncloud-data-init.service
ln -sf /dev/null /etc/systemd/system/syncloud-update.service
ln -sf /dev/null /etc/systemd/system/syncloud-update.timer
ln -sf /dev/null /etc/systemd/system/syncloud-boot-ok.service

# Create dirs for data partition bind mounts (used by data-init)
mkdir -p /mnt/data /var/lib/snapd /var/snap /snap

# Cleanup
rm -rf /root/v2-services

echo "=== v2 services installed (masked) ==="
