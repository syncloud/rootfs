# Syncloud root filesystem

# Run Syncloud on any Linux distro

Make sure you have nothing listening on port 80 and 443, like apache.

Remove apache2:

```
apt-get remove apache2
```

Also, as we use a modified version of snapd installation will remove any existing snapd.
Installation:

```
wget https://raw.githubusercontent.com/syncloud/rootfs/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

This should install Syncloud Platform

Open https://localhost and activate your device.

Report issues at https://github.com/syncloud/platform/issues
