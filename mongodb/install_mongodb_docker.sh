#!/bin/bash

sudo mkdir -p /data/db

sudo docker run -d \
  -p 27017:27017 \
  -v /data/db:/data/db \
  --name mongo \
  mongo 

