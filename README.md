# rootfs
Syncloud rootfs

# Run Syncloud on any Linux distro

Make sure you have nothing listening on port 80 and 81, like apache.

Remove apache2:

````
apt-get remove apache2

````

Installation:

````
wget https://raw.githubusercontent.com/syncloud/rootfs/master/install.sh
chmod +x install.sh
sudo ./install.sh stable
````

This should install Syncloud Platform

Open https://localhost and activate your device.

Report issues at https://github.com/syncloud/platform/issues
