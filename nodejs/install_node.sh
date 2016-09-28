#!/bin/bash

# Remove the lock
set +e
sudo rm /var/lib/dpkg/lock
sudo rm /var/cache/apt/archives/lock
sudo dpkg --configure -a
set -e

sudo apt-get -y install build-essential libssl-dev git curl

NODE_VERSION=4.6.0
NODE_ARCH=x64

# check we need to do this or not

NODE_DIST=node-v${NODE_VERSION}-linux-${NODE_ARCH}

cd /tmp
curl -O -L http://nodejs.org/dist/v${NODE_VERSION}/${NODE_DIST}.tar.gz
tar xvzf ${NODE_DIST}.tar.gz
sudo rm -rf /opt/nodejs
sudo mv ${NODE_DIST} /opt/nodejs

sudo ln -sf /opt/nodejs/bin/node /usr/bin/node
sudo ln -sf /opt/nodejs/bin/npm /usr/bin/npm

node -v
npm -v
