#!/bin/bash -e

# Initialize data partition and set up bind mounts for snapd persistence
# This runs early in boot, before snapd, to ensure /var/lib/snapd and /var/snap
# point to the data partition which survives A/B rootfs switches.

DATA_MNT=/mnt/data

# Mount data partition if not already mounted
if ! mountpoint -q "$DATA_MNT"; then
    mkdir -p "$DATA_MNT"
    mount /dev/disk/by-partlabel/data "$DATA_MNT"
fi

# Create persistent directories on data partition (first boot)
mkdir -p "$DATA_MNT/snapd"
mkdir -p "$DATA_MNT/snap-data"
mkdir -p "$DATA_MNT/syncloud"

# Seed from rootfs on first boot: if data partition is empty but rootfs has snapd state,
# move it to the data partition
if [ ! -f "$DATA_MNT/snapd/state.json" ] && [ -d /var/lib/snapd ] && [ "$(ls -A /var/lib/snapd 2>/dev/null)" ]; then
    echo "First boot: moving snapd state to data partition"
    cp -a /var/lib/snapd/* "$DATA_MNT/snapd/" || true
fi
if [ ! -d "$DATA_MNT/snap-data/platform" ] && [ -d /var/snap ] && [ "$(ls -A /var/snap 2>/dev/null)" ]; then
    echo "First boot: moving snap data to data partition"
    cp -a /var/snap/* "$DATA_MNT/snap-data/" || true
fi

# Bind mount data partition dirs over rootfs dirs
mkdir -p /var/lib/snapd /var/snap
mount --bind "$DATA_MNT/snapd" /var/lib/snapd
mount --bind "$DATA_MNT/snap-data" /var/snap

echo "Data partition initialized and bind mounts active"
