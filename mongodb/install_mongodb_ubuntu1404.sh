#!/bin/bash

# Remove the lock
set +e
sudo rm /var/lib/dpkg/lock
sudo rm /var/cache/apt/archives/lock
sudo dpkg --configure -a
set -e

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

echo "deb http://mirrors.tuna.tsinghua.edu.cn/mongodb/apt/ubuntu trusty/mongodb-org/stable multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update -y
sudo apt-get install -y mongodb-org

# Restart mongodb
sudo service mongod start

# display mongo version to see if we are ok
mongo --version
