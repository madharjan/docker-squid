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

### Clone this project

```bash
git clone https://github.com/madharjan/docker-squid
cd docker-squid
```

### Build Container

```bash
# login to DockerHub
docker login

# build
make

# tests
make run
make tests
make clean

# tag
make tag_latest

# release
make release
```

### Tag and Commit to Git

```bash
git tag 3.5.12
git push origin 3.5.12
```

## Run Container

### Prepare folder on host for container volumes

```bash
sudo mkdir -p /opt/docker/squid/cache/
sudo mkdir -p /opt/docker/squid/log/
```

### Run `docker-squid`

```bash
docker stop squid
docker rm squid

docker run -d \
  -p 8080:3128 \
  -e SQUID_CACHE_PEER_HOST=proxyHost \
  -e SQUID_CACHE_PEER_PORT=proxyPort \  
  -v /opt/docker/squid/cache:/var/cache/squid \
  -v /opt/docker/squid/log:/var/log/squid \
  --name squid \
  madharjan/docker-squid:3.5.12
```

## Run as Transparent Proxy

```bash
docker stop squid
docker rm squid

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
  --name squid \
  madharjan/docker-squid:3.5.12
```

## Run via Systemd

### Systemd Unit File - basic example

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

### Generate Systemd Unit File

| Variable                 | Default          | Example                                                          |
|--------------------------|------------------|------------------------------------------------------------------|
| PORT                     |                  | 3128                                                             |
| VOLUME_HOME              | /opt/docker      | /opt/data                                                        |
| VERSION                  | 1.0              | latest                                                           |                                                           |
| SQUID_CACHE_PEER_HOST    |                  | proxy.domain.com                                                             |
| SQUID_CACHE_PEER_PORT    |                  | 8080                                                             |

```bash
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
