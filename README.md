# rootfs
Syncloud rootfs

# Run Syncloud on any Linux distro

Make sure you have nothing listening on port 80 and 81, like apache.

Remove apache2:

````
apt-get remove apache2

````

Also, as we use a modified version of snapd installation will remove any existing snapd.
Installation:

````
wget https://raw.githubusercontent.com/syncloud/rootfs/master/install.sh
chmod +x install.sh
sudo ./install.sh stable
````

This should install Syncloud Platform

Open https://localhost and activate your device.

# Running a build server

1. Install docker
2. Install drone
3. Create drone network:
```
docker network create drone
```

Report issues at https://github.com/syncloud/platform/issues
