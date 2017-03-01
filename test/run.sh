#!/bin/bash

set -x

./clean.sh

sudo mkdir -p /opt/docker/squid/cache
sudo mkdir -p /opt/docker/squid/log
sudo chown -R 13:13 /opt/docker/squid

docker run -d \
  --network=host \
  --cap-add=NET_ADMIN \
  -e DEBUG=true \
  -e ENABLE_TRANSPARENT_PROXY=1 \
  -v /opt/docker/squid/cache:/var/cache/squid3 \
  -v /opt/docker/squid/log:/var/log/squid3 \
  --name tsquid \
  madharjan/docker-squid:3.3.8

sleep 2
docker logs tsquid
