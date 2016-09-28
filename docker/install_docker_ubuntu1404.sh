#!/usr/bin/env bash

# trus Docker 的 GPG 公钥
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# add source
echo "deb https://mirrors.tuna.tsinghua.edu.cn/docker/apt/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list

# install Docker
sudo apt-get update -y
sudo apt-get install docker-engine -y
