#!/bin/bash

set -x

./clean.sh

sudo mkdir -p /opt/docker/squid/cache
sudo mkdir -p /opt/docker/squid/log
sudo chown -R proxy:proxy /opt/docker/squid

docker run -d \
  --network=host \
  -e DEBUG=true \
  --cap-add=NET_ADMIN \
  -e SQUID_INTERFACE_IP=172.17.0.1 \
  -e SQUID_HTTP_PORT=9128 \
  -e SQUID_INTERCEPT_PORT=9129 \
  -e SQUID_DISK_CACHE_SIZE=15000 \
  -e ENABLE_TRANSPARENT_PROXY=1 \
  -v /opt/docker/squid/cache:/var/cache/squid3 \
  -v /opt/docker/squid/log:/var/log/squid3 \
  --name tsquid \
  madharjan/docker-squid:3.3.8

sleep 2
docker logs tsquid
