# docker-squid

[![Build Status](https://travis-ci.com/madharjan/docker-squid.svg?branch=master)](https://travis-ci.com/madharjan/docker-squid)
[![Layers](https://images.microbadger.com/badges/image/madharjan/docker-squid.svg)](http://microbadger.com/images/madharjan/docker-squid)

Docker container for Squid Proxy based on [madharjan/docker-base](https://github.com/madharjan/docker-base/)

Squid configuration and Transparent Proxy configuration based on [jpetazzo/squid-in-a-can](https://github.com/jpetazzo/squid-in-a-can)

## Changes

* Squid and iptables in single container
* Install `iptables` config if run as Transparent Proxy and cleanup `iptables` config on container stop

## Features

* Environment variables to set upstream proxy & authentication
* Environment variables to set cache settings
* Bats ([sstephenson/bats](https://github.com/sstephenson/bats/)) based test cases

## Usages
* Run `docker-squid` as Transparent Proxy while `docker build` to speedup build time by caching  OS packages downloads
* Run `docker-squid` as Transparent Proxy while `docker build` behind Corporate Proxy WITHOUT changing Dockerfile *(works only if all downloads from Internet is HTTP only, NOT HTTPS)*
* Run `docker-squid` to conserve bandwidth on slow Internet connection by caching frequently downloaded files


## Squid 3.3.8 (docker-squid)

### Environment

| Variable                  | Default | Example        |
|---------------------------|---------|----------------|
| DISABLE_SQUID             | 0       | 1 (to disable) |
| SQUID_INTERFACE_IP        | 0.0.0.0 | 170.17.42.1    |
| SQUID_HTTP_PORT           | 3128    | 8080           |
| SQUID_INTERCEPT_PORT      | 3129    | 8081           |
| SQUID_MAXIMUM_OBJECT_SIZE | 1024    | 512  (MB)      |
| SQUID_DISK_CACHE_SIZE     | 10000   | 1000           |
| SQUID_CACHE_PEER_HOST     |         | proxyHost      |
| SQUID_CACHE_PEER_PORT     |         | proxyPort      |
| SQUID_CACHE_PEER_AUTH     |         | user:pass      |
| ENABLE_TRANSPARENT_PROXY  | 0       | 1 (to enable)  |


## Build

```bash
# clone project
git clone https://github.com/madharjan/docker-squid
cd docker-squid

# build
make

# tests
make run
make test

# clean
make clean
```

## Run

**Note**: update environment variables below as necessary

```bash
# prepare foldor on host for container volumes
sudo mkdir -p /opt/docker/squid/cache/
sudo mkdir -p /opt/docker/squid/log/

# stop & remove previous instances
docker stop squid
docker rm squid

# run container
docker run -d \
  -p 8080:3128 \
  -e SQUID_CACHE_PEER_HOST=[ProxyHost] \
  -e SQUID_CACHE_PEER_PORT=[ProxyPort] \  
  -v /opt/docker/squid/cache:/var/cache/squid \
  -v /opt/docker/squid/log:/var/log/squid \
  --name squid \
  madharjan/docker-squid:3.5.12


# run container as transparent proxy
docker run -d \
  --network=host \
  --cap-add=NET_ADMIN \
  -e SQUID_HTTP_PORT=9090 \
  -e SQUID_INTERCEPT_PORT=9091 \
  -e SQUID_CACHE_PEER_HOST=proxyHost \
  -e SQUID_CACHE_PEER_PORT=proxyPort \  
  -e ENABLE_TRANSPARENT_PROXY=1 \
  -v /opt/docker/squid/cache:/var/cache/squid \
  -v /opt/docker/squid/log:/var/log/squid \
  --name squid_t \
  madharjan/docker-squid:3.5.12
```

## Systemd Unit File

**Note**: update environment variables below as necessary

```txt
[Unit]
Description=Squid

After=docker.service

[Service]
TimeoutStartSec=0

ExecStartPre=-/bin/mkdir -p /opt/docker/squid/cache
ExecStartPre=-/bin/mkdir -p /opt/docker/squid/log
ExecStartPre=-/usr/bin/docker stop squid
ExecStartPre=-/usr/bin/docker rm squid
ExecStartPre=-/usr/bin/docker pull madharjan/docker-squid:3.5.12

ExecStart=/usr/bin/docker run \
  -p 8080:3128 \
  -v /opt/docker/squid/cache:/var/cache/squid \
  -v /opt/docker/squid/log:/var/log/squid \
  --name squid \
  madharjan/docker-squid:3.5.12

ExecStop=/usr/bin/docker stop -t 2 squid

[Install]
WantedBy=multi-user.target
```

## Generate Systemd Unit File

| Variable                 | Default          | Example                                                          |
|--------------------------|------------------|------------------------------------------------------------------|
| PORT                     |                  | 3128                                                             |
| VOLUME_HOME              | /opt/docker      | /opt/data                                                        |
|                          |                  |                                                                  |                                                           |
| SQUID_CACHE_PEER_HOST    |                  | proxy.domain.com                                                 |
| SQUID_CACHE_PEER_PORT    |                  | 8080                                                             |

```bash
# generate template.service
docker run --rm \
  -e PORT=3128 \
  -e VOLUME_HOME=/opt/docker \
  -e VERSION=3.5.12 \
  -e SQUID_CACHE_PEER_HOST=proxy.domain.com \
  -e SQUID_CACHE_PEER_PORT=8080 \  
  madharjan/docker-squid:3.5.12 \
  template-systemd-unit | \
  sudo tee /etc/systemd/system/template.service

sudo systemctl enable template
sudo systemctl start template
```
